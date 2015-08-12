package main

import (
	"encoding/json"
	"errors"
	"flag"
	"fmt"
	"io/ioutil"
	"math/rand"
	"net/http"
	"net/url"
	"os"
	"runtime"
	"strconv"
	"strings"
	"time"

	log "github.com/cihub/seelog"
	traffic_ops "github.com/comcast/traffic_control/traffic_ops/client"
	influx "github.com/influxdb/influxdb/client"
)

const (
	// FATAL will exit after printing error
	FATAL = iota
	// ERROR will just keep going, print error
	ERROR = iota
)

const defaultPollingInterval = 10

// StartupConfig contains all fields necessary to create an InfluxDB session.
type StartupConfig struct {
	ToUser               string `json:"toUser"`
	ToPasswd             string `json:"toPasswd"`
	ToURL                string `json:"toUrl"`
	InfluxUser           string `json:"influxUser"`
	InfluxPassword       string `json:"influxPassword"`
	PollingInterval      int    `json:"pollingInterval"`
	StatusToMon          string `json:"statusToMon"`
	SeelogConfig         string `json:"seelogConfig"`
	CacheRetentionPolicy string `json:"cacheRetentionPolicy"`
	DsRetentionPolicy    string `json:"dsRetentionPolicy"`
}

// RunningConfig contains information about current InfluxDB connections.
type RunningConfig struct {
	HealthUrls    map[string]map[string]string // they 1st map key is CDN_name, the second is DsStats or CacheStats
	CacheGroupMap map[string]string            // map hostName to cacheGroup
	InfluxDBProps []InfluxDBProps
	ActiveServer  string // The fqdn of the last InfluxDB server used.
}

// InfluxDBProps contains the fqdn and port needed to login to an InfluxDB instance.
type InfluxDBProps struct {
	Fqdn string
	Port int64
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
		panic("error reading Seelog config " + config.SeelogConfig)
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
				go storeMetrics(cdnName, url, runningConfig.CacheGroupMap, config, &runningConfig)
			}
		}
	}
}

func getToData(config *StartupConfig, init bool) (RunningConfig, error) {
	var runningConfig RunningConfig
	tm, err := traffic_ops.Login(config.ToURL, config.ToUser, config.ToPasswd, true)
	if err != nil {
		msg := fmt.Sprintf("Error logging in to %v: %v", config.ToURL, err)
		if init {
			panic(msg)
		}
		log.Error(msg)
		return runningConfig, err
	}

	servers, err := tm.Servers()
	if err != nil {
		msg := fmt.Sprintf("Error getting server list from %v: %v ", config.ToURL, err)
		if init {
			panic(msg)
		}
		log.Error(msg)
		return runningConfig, err
	}

	runningConfig.CacheGroupMap = make(map[string]string)
	var influxDBProps []InfluxDBProps
	for _, server := range servers {
		runningConfig.CacheGroupMap[server.HostName] = server.Location
		if server.Type == "INFLUXDB" && server.Status == "ONLINE" {
			fqdn := server.HostName + "." + server.DomainName
			port, err := strconv.ParseInt(server.TcpPort, 10, 32)
			if err != nil {
				port = 8086 //default port
			}
			influxDBProps = append(influxDBProps, InfluxDBProps{Fqdn: fqdn, Port: port})
		}
	}
	runningConfig.InfluxDBProps = influxDBProps

	cacheStatPath := "/publish/CacheStats?hc=1&stats="
	dsStatPath := "/publish/DsStats?hc=1&wildcard=1&stats="
	parameters, err := tm.Parameters("TRAFFIC_STATS")
	if err != nil {
		msg := fmt.Sprintf("Error getting parameter list from %v: %v", config.ToURL, err)
		if init {
			panic(msg)
		}
		log.Error(msg)
		return runningConfig, err
	}

	for _, param := range parameters {
		if param.Name == "DsStats" {
			statName := param.Value
			dsStatPath += "," + statName
		} else if param.Name == "CacheStats" {
			cacheStatPath += "," + param.Value
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
			url = "http://" + server.IpAddress + dsStatPath
			runningConfig.HealthUrls[cdnName]["DsStats"] = url
		}
	}
	return runningConfig, nil
}

func storeMetrics(cdnName string, url string, cacheGroupMap map[string]string, config *StartupConfig, runningConfig *RunningConfig) {
	sampleTime := int64(time.Now().Unix())
	// get the data from rascal
	rascalData, err := getURL(url)
	if err != nil {
		log.Error("Unable to connect to rascal @ ", url, " - skipping timeslot")
		return
	}

	//influx connection
	influxClient, err := influxConnect(config, runningConfig)
	if err != nil {
		errHndlr(err, ERROR)
		return
	}

	if strings.Contains(url, "CacheStats") {
		err = storeCacheValues(rascalData, cdnName, sampleTime, cacheGroupMap, influxClient, config)
	} else if strings.Contains(url, "DsStats") {
		err = storeDsValues(rascalData, cdnName, sampleTime, influxClient, config)
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
func storeDsValues(rascalData []byte, cdnName string, sampleTime int64, influxClient *influx.Client, config *StartupConfig) error {
	type DsStatsJSON struct {
		Pp              string `json:"pp"`
		Date            string `json:"date"`
		DeliveryService map[string]map[string][]struct {
			Index uint64 `json:"index"`
			Time  int    `json:"time"`
			Value string `json:"value"`
			Span  uint64 `json:"span"`
		} `json:"deliveryService"`
	}

	var jData DsStatsJSON
	err := json.Unmarshal(rascalData, &jData)
	errHndlr(err, ERROR)

	statCount := 0
	var pts []influx.Point
	for dsName, dsData := range jData.DeliveryService {
		for dsMetric, dsMetricData := range dsData {
			//create dataKey (influxDb series)
			var cachegroup, statName string
			if strings.Contains(dsMetric, "total.") {
				s := strings.Split(dsMetric, ".")
				cachegroup, statName = s[0], s[1]
			} else {
				s := strings.Split(dsMetric, ".")
				cachegroup, statName = s[1], s[2]
			}

			//convert stat time to epoch
			statTime := strconv.Itoa(dsMetricData[0].Time)
			msInt, err := strconv.ParseInt(statTime, 10, 64)
			if err != nil {
				errHndlr(err, ERROR)
			}

			newTime := time.Unix(0, msInt*int64(time.Millisecond))
			//convert stat value to float
			statValue := dsMetricData[0].Value
			statFloatValue, err := strconv.ParseFloat(statValue, 64)
			if err != nil {
				statFloatValue = 0.0
			}
			pts = append(pts,
				influx.Point{
					Measurement: statName,
					Tags: map[string]string{
						"deliveryservice": dsName,
						"cdn":             cdnName,
						"cachegroup":      cachegroup,
					},
					Fields: map[string]interface{}{
						"value": statFloatValue,
					},
					Time:      newTime,
					Precision: "ms",
				},
			)
			statCount++
		}
	}
	bps := influx.BatchPoints{
		Points:          pts,
		Database:        "deliveryservice_stats",
		RetentionPolicy: config.DsRetentionPolicy,
	}
	_, err = influxClient.Write(bps)
	if err != nil {
		errHndlr(err, ERROR)
	}
	log.Info("Saved ", statCount, " deliveryservice stats values for ", cdnName, " @ ", sampleTime)
	return nil
}

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

func storeCacheValues(trafmonData []byte, cdnName string, sampleTime int64, cacheGroupMap map[string]string, influxClient *influx.Client, config *StartupConfig) error {
	/* note about the data:
	keys are cdnName:deliveryService:cacheGroup:cacheName:statName
	*/

	type CacheStatsJSON struct {
		Pp     string `json:"pp"`
		Date   string `json:"date"`
		Caches map[string]map[string][]struct {
			Index uint64 `json:"index"`
			Time  int    `json:"time"`
			Value string `json:"value"`
			Span  uint64 `json:"span"`
		} `json:"caches"`
	}
	var jData CacheStatsJSON
	err := json.Unmarshal(trafmonData, &jData)
	errHndlr(err, ERROR)

	statCount := 0
	var pts []influx.Point
	for cacheName, cacheData := range jData.Caches {
		for statName, statData := range cacheData {
			dataKey := statName
			dataKey = strings.Replace(dataKey, ".bandwidth", ".kbps", 1)
			dataKey = strings.Replace(dataKey, "-", "_", -1)

			//Get the stat time and convert to epoch
			statTime := strconv.Itoa(statData[0].Time)
			msInt, err := strconv.ParseInt(statTime, 10, 64)
			if err != nil {
				errHndlr(err, ERROR)
			}

			newTime := time.Unix(0, msInt*int64(time.Millisecond))
			//Get the stat value and convert to float
			statValue := statData[0].Value
			statFloatValue, err := strconv.ParseFloat(statValue, 64)
			if err != nil {
				statFloatValue = 0.00
			}
			//add stat data to pts array
			pts = append(pts,
				influx.Point{
					Measurement: dataKey,
					Tags: map[string]string{
						"cachegroup": cacheGroupMap[cacheName],
						"hostname":   cacheName,
						"cdn":        cdnName,
					},
					Fields: map[string]interface{}{
						"value": statFloatValue,
					},
					Time:      newTime,
					Precision: "ms",
				},
			)
			statCount++
		}
	}
	//create influxdb batch of points
	bps := influx.BatchPoints{
		Points:          pts,
		Database:        "cache_stats",
		RetentionPolicy: config.CacheRetentionPolicy,
	}
	//write to influxdb
	_, err = influxClient.Write(bps)
	if err != nil {
		errHndlr(err, ERROR)
	}
	log.Info("Saved ", statCount, " cache stats values for ", cdnName, " @ ", sampleTime)
	return nil
}

func getURL(url string) ([]byte, error) {
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

func influxConnect(config *StartupConfig, runningConfig *RunningConfig) (*influx.Client, error) {
	// Connect to InfluxDb
	activeServers := len(runningConfig.InfluxDBProps)
	rand.Seed(time.Now().UnixNano())

	// if there is only 1 active, use it
	if activeServers == 1 {
		runningConfig.ActiveServer = runningConfig.InfluxDBProps[0].Fqdn

		u, err := url.Parse(fmt.Sprintf("http://%s:%d", runningConfig.InfluxDBProps[0].Fqdn, runningConfig.InfluxDBProps[0].Port))
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
		return con, nil
	} else if activeServers > 1 {
		// TODO: update influx.config to set the last server used and do not use it the next time.
		//
		// try to connect to a random server until we find one that works.  if we dont find one in 20 tries, bail.
		for i := 0; i < 20; i++ {
			index := rand.Intn(activeServers)

			if runningConfig.ActiveServer == runningConfig.InfluxDBProps[index].Fqdn {
				continue
			}
			runningConfig.ActiveServer = runningConfig.InfluxDBProps[index].Fqdn

			u, err := url.Parse(fmt.Sprintf("http://%s:%d", runningConfig.InfluxDBProps[index].Fqdn, runningConfig.InfluxDBProps[index].Port))
			if err != nil {
				errHndlr(err, ERROR)
				continue
			}

			conf := influx.Config{
				URL:      *u,
				Username: config.InfluxUser,
				Password: config.InfluxPassword,
			}
			con, err := influx.NewClient(conf)
			if err != nil {
				errHndlr(err, ERROR)
				continue
			}

			_, _, err = con.Ping()
			if err != nil {
				errHndlr(err, ERROR)
				continue
			}

			return con, nil
		}

		err := errors.New("Could not connect to any of the InfluxDb servers that are ONLINE in traffic ops.")
		return nil, err
	} else {
		err := errors.New("No online InfluxDb servers could be found!")
		return nil, err
	}
}
