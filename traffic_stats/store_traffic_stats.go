package main

import (
	"encoding/json"
	"flag"
	"fmt"
	log "github.com/cihub/seelog"
	influx "github.com/influxdb/influxdb/client"
	traffic_ops "github.comcast.com/cdneng/traffic_control/traffic_ops/client"
	"io/ioutil"
	"net/http"
	"net/url"
	"os"
	"runtime"
	"strconv"
	"strings"
	"time"
)

const (
	FATAL = iota // Exit after printing error
	ERROR = iota // Just keep going, print error
)

const defaultPollingInterval = 10

type StartupConfig struct {
	ToUser          string `json:"toUser"`
	ToPasswd        string `json:"toPasswd"`
	ToUrl           string `json:"toUrl"`
	InfluxHost      string `json:"influxHost"`
	InfluxPort      int    `json:"influxPort"`
	InfluxUser      string `json:"influxUser"`
	InfluxPassword  string `json:"influxPassword"`
	PollingInterval int    `json:"pollingInterval"`
	StatusToMon     string `json:statusToMon"`
	SeelogConfig    string `json:seelogConfig"`
}

type RunningConfig struct {
	HealthUrls      map[string]map[string]string // they 1st map key is CDN_name, the second is DsStats or CacheStats
	CacheGroupMap   map[string]string            // map hostName to cacheGroup
	RetentionPeriod int64                        // how long in seconds to keep the data in the Redis database
}

func main() {
	configFile := flag.String("cfg", "", "The config file")
	testSummary := flag.Bool("testSummary", false, "Test summary mode")
	flag.Parse()
	file, err := os.Open(*configFile)
	errHndlr(err, FATAL)
	decoder := json.NewDecoder(file)
	config := &StartupConfig{}
	err = decoder.Decode(&config)
	errHndlr(err, FATAL)
	defaultPollingInterval := 10

	if config.PollingInterval == 0 {
		config.PollingInterval = defaultPollingInterval
	}

	logger, err := log.LoggerFromConfigAsFile(config.SeelogConfig)
	defer log.Flush()

	if err != nil {
		panic("error reading config " + config.SeelogConfig)
	}

	fmt.Println("Replacing logger, see log file according to " + config.SeelogConfig)
	if *testSummary {
		fmt.Println("WARNING: testSummary is on!")
	}
	log.ReplaceLogger(logger)

	runtime.GOMAXPROCS(runtime.NumCPU())

	runningConfig, nil := getToData(config, true)

	<-time.NewTimer(time.Now().Truncate(time.Duration(config.PollingInterval) * time.Second).Add(time.Duration(config.PollingInterval) * time.Second).Sub(time.Now())).C
	tickerChan := time.Tick(time.Duration(config.PollingInterval) * time.Second)
	for now := range tickerChan {
		if now.Second() == 30 {
			trc, err := getToData(config, false)
			if err == nil {
				runningConfig = trc
			}
		}
		for cdnName, urls := range runningConfig.HealthUrls {
			for _, url := range urls {
				log.Info(cdnName, " -> ", url)
				if *testSummary {
					fmt.Println("Skipping stat write - testSummary mode is ON!")
					continue
				}
				go storeMetrics(cdnName, url, runningConfig.CacheGroupMap, config)
			}
		}
	}
}

func getToData(config *StartupConfig, init bool) (RunningConfig, error) {
	var runningConfig RunningConfig
	tm, err := traffic_ops.Login(config.ToUrl, config.ToUser, config.ToPasswd, true)
	if err != nil {
		msg := fmt.Sprintf("Error logging in to %v: %v", config.ToUrl, err)
		if init {
			panic(msg)
		} else {
			log.Error(msg)
			return runningConfig, err
		}
	}

	servers, err := tm.Servers()
	if err != nil {
		msg := fmt.Sprintf("Error getting server list from %v: %v ", config.ToUrl, err)

		if init {
			panic(msg)
		} else {
			log.Error(msg)
			return runningConfig, err
		}
	}
	runningConfig.CacheGroupMap = make(map[string]string)
	for _, server := range servers {
		runningConfig.CacheGroupMap[server.HostName] = server.Location
	}

	cacheStatPath := "/publish/CacheStats?hc=1&stats="
	dsStatPath := "/publish/DsStats?hc=1&wildcard=1&stats="
	parameters, err := tm.Parameters("TRAFFIC_STATS")
	if err != nil {
		msg := fmt.Sprintf("Error getting parameter list from %v: %v", config.ToUrl, err)
		if init {
			panic(msg)
		} else {
			log.Error(msg)
			return runningConfig, err
		}
	}
	runningConfig.RetentionPeriod = 259200 //30 days hardcoded default, if the param doesn't exist, it'll use this.  **was 8640 for redis**
	for _, param := range parameters {
		if param.Name == "DsStats" {
			statName := param.Value
			dsStatPath += "," + statName
		} else if param.Name == "CacheStats" {
			cacheStatPath += "," + param.Value
		} else if param.Name == "RetentionPeriod" {
			runningConfig.RetentionPeriod, err = strconv.ParseInt(param.Value, 10, 64)
			if err != nil {
				log.Error(param.Name, " - error converting ", param.Value, " to Int: ", err)
			}
		}
	}
	cacheStatPath = strings.Replace(cacheStatPath, "=,", "=", 1)
	dsStatPath = strings.Replace(dsStatPath, "=,", "=", 1)

	runningConfig.HealthUrls = make(map[string]map[string]string)
	for _, server := range servers {
		if server.Type == "RASCAL" && server.Status == config.StatusToMon {
			cdnName := ""
			parameters, _ := tm.Parameters(server.Profile)
			for _, param := range parameters {
				if param.Name == "CDN_name" && param.ConfigFile == "rascal-config.txt" {
					cdnName = param.Value
					break
				}
			}

			if cdnName == "" {
				log.Error("Unable to find CDN name for " + server.HostName + ".. skipping")
				continue
			}

			if runningConfig.HealthUrls[cdnName] == nil {
				runningConfig.HealthUrls[cdnName] = make(map[string]string)
			}
			url := "http://" + server.IpAddress + cacheStatPath
			runningConfig.HealthUrls[cdnName]["CacheStats"] = url
		}
	}
	return runningConfig, nil
}

func storeMetrics(cdnName string, url string, cacheGroupMap map[string]string, config *StartupConfig) {
	sampleTime := int64(time.Now().Unix())
	// get the data from rascal
	rascalData, err := getUrl(url)
	if err != nil {
		log.Info("ERROR: Unable to connect to rascal @ ", url, " - skipping timeslot")
		return
	}
	//influx connection
	con, err := influxConnect(config)
	if err != nil {
		errHndlr(err, FATAL)
	}
	if strings.Contains(url, "CacheStats") {
		err = storeCacheValues(rascalData, cdnName, sampleTime, cacheGroupMap, con)
		// } else if strings.Contains(url, "DsStats") {
		// 	err = storeDsValues(rascalData, cdnName, sampleTime, redisClient, config.DsAggregate)
	} else {
		log.Info("Don't know what to do with ", url)
	}
}

func errHndlr(err error, severity int) {
	if err != nil {
		switch {
		case severity == ERROR:
			log.Error(err)
		case severity == FATAL:
			log.Error(err)
			panic(err)
		}
	}
}

/* the ds json looks like:
{
  "deliveryService": {
    "linear-gbr-hls-sbr": {
      "	.us-ma-woburn.kbps": [{
        "index": 520281,
        "time": 1398893383605,
        "value": "0",
        "span": 520024
      }],
      "location.us-de-newcastle.kbps": [{
        "index": 520281,
        "time": 1398893383605,
        "value": "0",
        "span": 517707
      }],
    }
 }
*/
// func storeDsValues(rascalData []byte, cdnName string, sampleTime int64, influxClient *influx.Client, dsAggregate map[string]AggregationConfig) error {
// 	type DsStatsJson struct {
// 		Pp              string `json:"pp"`
// 		Date            string `json:"date"`
// 		DeliveryService map[string]map[string][]struct {
// 			Index uint64 `json:"index"`
// 			Time  uint64 `json:"time"`
// 			Value string `json:"value"`
// 			Span  uint64 `json:"span"`
// 		} `json:"deliveryService"`
// 	}

// 	var jData DsStatsJson
// 	err := json.Unmarshal(rascalData, &jData)
// 	errHndlr(err, ERROR)
// 	statCount := 0
// 	// statTotals := make(map[string]float64)
// 	pts := make([]influx.Point, 0)
// 	for dsName, dsData := range jData.DeliveryService {
// 		for dsMetric, dsMetricData := range dsData {
// 			keyPart := strings.Replace(dsMetric, "location.", "", -1)
// 			keyPart = strings.Replace(keyPart, ".kbps", ":kbps", -1)
// 			keyPart = strings.Replace(keyPart, ".tps", ":tps", -1)
// 			keyPart = strings.Replace(keyPart, ".status", ":status", -1)
// 			// keyPart = strings.Replace(keyPart, "total:all:", "all:all:", -1) // for consistency all everywhere
// 			dataKey := cdnName + ":" + dsName + ":" + keyPart
// 			statValue := dsMetricData[0].Value
// 			//fmt.Printf("%s  ->%s\n", redisKey, statValue)

// 			aggConfig, exists := dsAggregate[dsMetric]

// 			if exists {
// 				statFloatValue, err := strconv.ParseFloat(statValue, 64)

// 				if err != nil {
// 					statFloatValue = 0.0
// 				}

// 				statTotals[cdnName+":all:all:all:"+aggConfig.RedisKey] += statFloatValue
// 			}

// 			r := redisClient.Cmd("rpush", redisKey, statValue)
// 			errHndlr(r.Err, ERROR)
// 			statCount++
// 		}
// 	}
// 	// for totalKey, totalVal := range statTotals {
// 	// 	r := redisClient.Cmd("rpush", totalKey, strconv.FormatFloat(totalVal, 'f', 2, 64))
// 	// 	errHndlr(r.Err, ERROR)
// 	// 	statCount++
// 	// }
// 	log.Info("Saved ", statCount, " ds values for ", cdnName, " @ ", sampleTime)
// 	return nil
// }

/* The caches json looks like:
{
	caches: {
		odol-atsmid-est-01: { },
		odol-atsec-sfb-05: {
			ats.proxy.process.net.read_bytes: [
				{
					index: 332545,
					time: 1396711793883,
					value: "5547585527895",
					span: 1
				}
			],
			ats.proxy.process.http.transaction_counts.hit_fresh.process: [
				{
					index: 332545,
					time: 1396711793883,
					value: "2109053611",
					span: 1
				}
			],
		}
	}
}
*/

func storeCacheValues(trafmonData []byte, cdnName string, sampleTime int64, cacheGroupMap map[string]string, influxClient *influx.Client) error {
	/* note about the data:
	keys are cdnName:deliveryService:cacheGroup:cacheName:statName
	*/

	type CacheStatsJson struct {
		Pp     string `json:"pp"`
		Date   string `json:"date"`
		Caches map[string]map[string][]struct {
			Index uint64 `json:"index"`
			Time  int    `json:"time"`
			Value string `json:"value"`
			Span  uint64 `json:"span"`
		} `json:"caches"`
	}
	var jData CacheStatsJson
	err := json.Unmarshal(trafmonData, &jData)
	errHndlr(err, ERROR)
	statCount := 0
	pts := make([]influx.Point, 0)
	for cacheName, cacheData := range jData.Caches {
		for statName, statData := range cacheData {
			dataKey := cdnName + ":" + cacheGroupMap[cacheName] + ":" + cacheName + ":" + statName
			dataKey = strings.Replace(dataKey, ".bandwidth", ".kbps", 1)
			statTime := strconv.Itoa(statData[0].Time)
			msInt, err := strconv.ParseInt(statTime, 10, 64)
			if err != nil {
				errHndlr(err, FATAL)
			}
			newTime := time.Unix(0, msInt*int64(time.Millisecond))
			statValue := statData[0].Value
			statFloatValue, err := strconv.ParseFloat(statValue, 64)
			if err != nil {
				statFloatValue = 0.00
			}
			pts = append(pts,
				influx.Point{
					Name: dataKey,
					Fields: map[string]interface{}{
						"value": statFloatValue,
					},
					Timestamp: newTime,
					Precision: "ms",
				},
			)
			statCount++
		}
	}
	bps := influx.BatchPoints{
		Points:          pts,
		Database:        "cachestats",
		RetentionPolicy: "thirtyDays",
	}
	_, err = influxClient.Write(bps)
	if err != nil {
		errHndlr(err, ERROR)
	}
	log.Info("Saved ", statCount, " values for ", cdnName, " @ ", sampleTime)
	return nil
}

func getUrl(url string) ([]byte, error) {

	resp, err := http.Get(url)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()
	body, err := ioutil.ReadAll(resp.Body)
	if err != nil {
		return nil, err
	}
	return body, nil
}

func influxConnect(config *StartupConfig) (*influx.Client, error) {
	//Connect to InfluxDb
	//TODO: support multiple hosts
	u, err := url.Parse(fmt.Sprintf("http://%s:%d", config.InfluxHost, config.InfluxPort))
	if err != nil {
		return nil, err
	}
	conf := influx.Config{
		URL:      *u,
		Username: config.InfluxUser,
		Password: config.InfluxPassword,
	}

	con, err := influx.NewClient(conf)
	if err != nil {
		return nil, err
	}
	_, _, err = con.Ping()
	if err != nil {
		return nil, err
	}
	// fmt.Printf("Happy as a Hippo! %v, %s \n", dur, ver)

	return con, nil
}
