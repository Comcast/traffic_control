package main

import (
	"bufio"
	"fmt"
	"github.com/fzzy/radix/redis"
	"io"
	"os"
	// "io/ioutil"
	"log"
	"strconv"
	"strings"
	"time"
)

func main() {

	file, err := os.Open("bps_2_yrs.csv")
	if err != nil {
		log.Fatal(err)
	}

	r := bufio.NewReader(file)

	redisClient, err := redis.DialTimeout("tcp", "127.0.0.1:6379", time.Duration(10)*time.Second)
	if err != nil {
		log.Fatal(err)
	}
	defer redisClient.Close()

	prevDay := 0
	prevSampleTime := time.Now()
	maxBps := float64(0)
	bytesServed := float64(0)
	tzLoc, _ := time.LoadLocation("America/New_York")
	_ = redisClient.Cmd("del", "over-the-top:all:all:all:daily_maxkbpsbandwidth")
	_ = redisClient.Cmd("del", "over-the-top:all:all:all:daily_bytesserved")
	_ = redisClient.Cmd("del", "title-vi:all:all:all:daily_bytesserved")
	_ = redisClient.Cmd("del", "title-vi:all:all:all:daily_maxkbps")
	for {
		line, err := r.ReadString('\n')
		if err == io.EOF {
			break
		} else if err != nil {
			log.Fatal(err)
		}
		arr := strings.Split(line, ",")
		dateString := strings.TrimSpace(arr[0])
		mon, _ := strconv.Atoi(dateString[0:2])
		day, _ := strconv.Atoi(dateString[3:5])
		year, _ := strconv.Atoi("20" + dateString[6:8])
		hour, _ := strconv.Atoi(dateString[9:11])
		min, _ := strconv.Atoi(dateString[12:14])
		sampleTime := time.Date(year, time.Month(mon), day, hour, min, 0, 0, tzLoc)
		bpsString := strings.TrimSpace(arr[1])
		sampleBps, _ := strconv.ParseFloat(bpsString, 64)
		if prevDay != day {
			summaryTime := time.Date(year, time.Month(mon), day, 0, 0, 0, 0, tzLoc)
			fmt.Printf("%v -> maxBps %v, ByteServed: %v\n", summaryTime.Unix(), maxBps, bytesServed)
			if maxBps > 0 && bytesServed > 0 && summaryTime.Unix() > 1348977600 {
				// fmt.Println("rpush", "over-the-top:daily:bandwidth", strconv.FormatInt(summaryTime.Unix(), 10)+":"+strconv.FormatInt(int64(maxBps), 10))
				maxBps = maxBps / 1000           // Rascal uses Kbps
				bytesServed = bytesServed / 1024 // Rascal uses Kbips
				r := redisClient.Cmd("rpush", "over-the-top:all:all:all:daily_maxkbps", strconv.FormatInt(summaryTime.Unix(), 10)+":"+strconv.FormatInt(int64(maxBps), 10))
				if r.Err != nil {
					log.Fatal(err)
				}
				r = redisClient.Cmd("rpush", "over-the-top:all:all:all:daily_bytesserved", strconv.FormatInt(summaryTime.Unix(), 10)+":"+strconv.FormatInt(int64(bytesServed), 10))
				if r.Err != nil {
					log.Fatal(err)
				}
				r = redisClient.Cmd("rpush", "title-vi:all:all:all:daily_maxkbps", strconv.FormatInt(summaryTime.Unix(), 10)+":"+strconv.FormatInt(int64(maxBps*.1), 10))
				if r.Err != nil {
					log.Fatal(err)
				}
				r = redisClient.Cmd("rpush", "title-vi:all:all:all:daily_bytesserved", strconv.FormatInt(summaryTime.Unix(), 10)+":"+strconv.FormatInt(int64(bytesServed*.1), 10))
				if r.Err != nil {
					log.Fatal(err)
				}
			}
			maxBps = 0
			bytesServed = 0
		}
		if sampleBps > 400000000000 { // get rid of the false big peaks in the nsg data
			fmt.Println("discarding @", dateString)
			continue
		}
		duration := sampleTime.Sub(prevSampleTime)
		bytesServed += duration.Seconds() * sampleBps / 8
		if maxBps < sampleBps {
			maxBps = sampleBps
		}

		prevSampleTime = sampleTime
		prevDay = day
	}
	file.Close()
}
