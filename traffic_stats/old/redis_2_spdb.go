package main

import (
	"encoding/json"
	"flag"
	"fmt"
	"github.com/fzzy/radix/redis"
	"log"
	"os"
	"strconv"
	"strings"
	"time"
)

const (
	FATAL = iota // Exit after printing error
	ERROR = iota // Just keep going, print error
)

type StartupConfig struct {
	RedisString  string                `json:"redisString"`
	SpdbNodeType string                `json:"spdbNodeType"`
	StatConfigs  map[string]StatConfig `json:"statConfigs"`
}

type StatConfig struct {
	RedisInterval int     `json:"redisInterval"`
	SpdbMetric    string  `json:"spdbMetric"`
	SpdbInterval  int     `json:"spdbInterval"`
	Multiplier    float64 `json:"multiplier"`
}

func main() {
	configFile := flag.String("cfg", "", "The config file")
	flag.Parse()
	file, err := os.Open(*configFile)
	errHndlr(err, FATAL)
	decoder := json.NewDecoder(file)
	config := &StartupConfig{}
	err = decoder.Decode(&config)
	errHndlr(err, FATAL)

	redisClient, err := redis.DialTimeout("tcp", config.RedisString, time.Duration(10)*time.Second)
	errHndlr(err, ERROR)
	defer redisClient.Close()
	keyList, err := redisClient.Cmd("keys", "*:*:*:*:*").List()
	errHndlr(err, ERROR)

	for _, key := range keyList {
		nf := false
		statParts := strings.Split(key, ":")
		statName := statParts[len(statParts)-1]

		for _, val := range statParts {
			if val == "" {
				//log.Print("Detected null key portion, in " + strings.Join(statParts[:len(statParts)-1], ",") + "; skipping")
				nf = true
			}
		}

		statConfig, exists := config.StatConfigs[statName]

		if !exists || nf {
			continue
		}

		windowStart := (statConfig.SpdbInterval / statConfig.RedisInterval) * -1 // SpdbInterval should be 300, RedisInterval should be 10; this yields -30
		values, err := redisClient.Cmd("lrange", key, windowStart, -1).List()
		errHndlr(err, ERROR)
		total := float64(0.0)
		count := float64(0.0) // this is a float to avoid type conversion issues when doing the avg
		nowTime := time.Now().Unix()

		for _, val := range values {
			if val == "" {
				val = "0"
			}

			fVal, err := strconv.ParseFloat(val, 64)

			if err != nil {
				fmt.Println(err, " for ", key)
			}

			total += fVal
			count++
		}

		avg := total / count

		if statConfig.Multiplier > 0 {
			avg = avg * statConfig.Multiplier
		}

		fmt.Printf("%s#%d#raw,%d,%.2f,%s,%s\n", statConfig.SpdbMetric, statConfig.SpdbInterval, nowTime, avg, config.SpdbNodeType, strings.Join(statParts[:len(statParts)-1], ","))
	}
}

func errHndlr(err error, severity int) {
	if err != nil {
		switch {
		case severity == ERROR:
			log.Print(err)
		case severity == FATAL:
			log.Fatal(err)
		}
	}
}
