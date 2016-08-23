package manager

import (
	"fmt"
	"github.com/Comcast/traffic_control/traffic_monitor/experimental/common/handler"
	"github.com/Comcast/traffic_control/traffic_monitor/experimental/common/poller"
	"github.com/Comcast/traffic_control/traffic_monitor/experimental/traffic_monitor/http_server"
	todata "github.com/Comcast/traffic_control/traffic_monitor/experimental/traffic_monitor/trafficopsdata"
	towrap "github.com/Comcast/traffic_control/traffic_monitor/experimental/traffic_monitor/trafficopswrapper"
	to "github.com/Comcast/traffic_control/traffic_ops/client"
	"log"
	"sync"
)

// This could be made lock-free, if the performance was necessary
type OpsConfigThreadsafe struct {
	opsConfig *handler.OpsConfig
	m         *sync.Mutex
}

func NewOpsConfigThreadsafe() OpsConfigThreadsafe {
	return OpsConfigThreadsafe{m: &sync.Mutex{}, opsConfig: &handler.OpsConfig{}}
}

func (o *OpsConfigThreadsafe) Get() handler.OpsConfig {
	o.m.Lock()
	defer func() {
		o.m.Unlock()
	}()
	return *o.opsConfig
}

func (o *OpsConfigThreadsafe) Set(newOpsConfig handler.OpsConfig) {
	o.m.Lock()
	*o.opsConfig = newOpsConfig
	o.m.Unlock()
}

// Note the OpsConfigManager is in charge of the httpServer, because ops config changes trigger server changes. If other things needed to trigger server restarts, the server could be put in its own goroutine with signal channels
func StartOpsConfigManager(opsConfigFile string, dr chan<- http_server.DataRequest, toSession towrap.ITrafficOpsSession, toData todata.TODataThreadsafe, opsConfigChangeSubscribers []chan<- handler.OpsConfig, toChangeSubscribers []chan<- towrap.ITrafficOpsSession) OpsConfigThreadsafe {

	opsConfigFileChannel := make(chan interface{})
	opsConfigFilePoller := poller.FilePoller{
		File:          opsConfigFile,
		ResultChannel: opsConfigFileChannel,
	}

	opsConfigChannel := make(chan handler.OpsConfig)
	opsConfigFileHandler := handler.OpsConfigFileHandler{
		ResultChannel:    opsConfigFilePoller.ResultChannel,
		OpsConfigChannel: opsConfigChannel,
	}

	go opsConfigFileHandler.Listen()
	go opsConfigFilePoller.Poll()

	opsConfig := NewOpsConfigThreadsafe()
	go opsConfigManagerListen(opsConfig, opsConfigChannel, dr, toSession, toData, opsConfigChangeSubscribers, toChangeSubscribers)
	return opsConfig
}

// TODO remove change subscribers, give Threadsafes directly to the things that need them. If they only set vars, and don't actually do work on change.
func opsConfigManagerListen(opsConfig OpsConfigThreadsafe, opsConfigChannel <-chan handler.OpsConfig, dr chan<- http_server.DataRequest, toSession towrap.ITrafficOpsSession, toData todata.TODataThreadsafe, opsConfigChangeSubscribers []chan<- handler.OpsConfig, toChangeSubscribers []chan<- towrap.ITrafficOpsSession) {
	httpServer := http_server.Server{}

	errorCount := 0 // TODO make threadsafe and a pointer to errorcount in the main manager?
	for {
		select {
		case newOpsConfig := <-opsConfigChannel:
			var err error
			opsConfig.Set(newOpsConfig)

			listenAddress := ":80" // default

			if newOpsConfig.HttpListener != "" {
				listenAddress = newOpsConfig.HttpListener
			}

			handleErr := func(err error) {
				errorCount++
				log.Printf("%v\n", err)
			}

			err = httpServer.Run(dr, listenAddress)
			if err != nil {
				handleErr(fmt.Errorf("MonitorConfigPoller: error creating HTTP server: %s\n", err))
				continue
			}

			realToSession, err := to.Login(newOpsConfig.Url, newOpsConfig.Username, newOpsConfig.Password, newOpsConfig.Insecure)
			if err != nil {
				handleErr(fmt.Errorf("MonitorConfigPoller: error instantiating Session with traffic_ops: %s\n", err))
				continue
			}
			toSession = towrap.NewTrafficOpsSessionThreadsafe(realToSession)

			if err := toData.Fetch(toSession, newOpsConfig.CdnName); err != nil {
				handleErr(fmt.Errorf("Error getting Traffic Ops data: %v\n", err))
				continue
			}

			// These must be in a goroutine, because the monitorConfigPoller tick sends to a channel this select listens for. Thus, if we block on sends to the monitorConfigPoller, we have a livelock race condition.
			// More generically, we're using goroutines as an infinite chan buffer, to avoid potential livelocks
			for _, subscriber := range opsConfigChangeSubscribers {
				go func() {
					subscriber <- newOpsConfig // this is needed for cdnName
				}()
			}
			for _, subscriber := range toChangeSubscribers {
				go func() {
					subscriber <- toSession
				}()
			}
		}
	}
}
