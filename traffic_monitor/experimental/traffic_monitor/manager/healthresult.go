package manager

import (
	"sync"
	"time"

	"github.com/Comcast/traffic_control/traffic_monitor/experimental/traffic_monitor/cache"
	"github.com/Comcast/traffic_control/traffic_monitor/experimental/traffic_monitor/config"
	"github.com/Comcast/traffic_control/traffic_monitor/experimental/traffic_monitor/enum"
	"github.com/Comcast/traffic_control/traffic_monitor/experimental/traffic_monitor/health"
	"github.com/Comcast/traffic_control/traffic_monitor/experimental/traffic_monitor/log"
	"github.com/Comcast/traffic_control/traffic_monitor/experimental/traffic_monitor/peer"
	todata "github.com/Comcast/traffic_control/traffic_monitor/experimental/traffic_monitor/trafficopsdata"
)

type DurationMapThreadsafe struct {
	durationMap map[enum.CacheName]time.Duration
	m           *sync.RWMutex
}

func copyDurationMap(a map[enum.CacheName]time.Duration) map[enum.CacheName]time.Duration {
	b := map[enum.CacheName]time.Duration{}
	for k, v := range a {
		b[k] = v
	}
	return b
}

func NewDurationMapThreadsafe() DurationMapThreadsafe {
	return DurationMapThreadsafe{m: &sync.RWMutex{}, durationMap: map[enum.CacheName]time.Duration{}}
}

func (o *DurationMapThreadsafe) Get() map[enum.CacheName]time.Duration {
	o.m.RLock()
	defer o.m.RUnlock()
	return copyDurationMap(o.durationMap)
}

func (o *DurationMapThreadsafe) GetDuration(cacheName enum.CacheName) (time.Duration, bool) {
	o.m.RLock()
	defer o.m.RUnlock()
	duration, ok := o.durationMap[cacheName]
	return duration, ok
}

func (o *DurationMapThreadsafe) Set(cacheName enum.CacheName, d time.Duration) {
	o.m.Lock()
	o.durationMap[cacheName] = d
	o.m.Unlock()
}

type TimeMapThreadsafe struct {
	timeMap map[enum.CacheName]time.Time
	m       *sync.RWMutex
}

func copyTimeMap(a map[enum.CacheName]time.Time) map[enum.CacheName]time.Time {
	b := map[enum.CacheName]time.Time{}
	for k, v := range a {
		b[k] = v
	}
	return b
}

func NewTimeMapThreadsafe() TimeMapThreadsafe {
	return TimeMapThreadsafe{m: &sync.RWMutex{}, timeMap: map[enum.CacheName]time.Time{}}
}

func (o TimeMapThreadsafe) Get() map[enum.CacheName]time.Time {
	o.m.RLock()
	defer o.m.RUnlock()
	return copyTimeMap(o.timeMap)
}

func (o *TimeMapThreadsafe) GetTime(cacheName enum.CacheName) (time.Time, bool) {
	o.m.RLock()
	defer o.m.RUnlock()
	time, ok := o.timeMap[cacheName]
	return time, ok
}

func (o *TimeMapThreadsafe) Set(cacheName enum.CacheName, d time.Time) {
	o.m.Lock()
	o.timeMap[cacheName] = d
	o.m.Unlock()
}

type ResultsThreadsafe struct {
	r map[enum.CacheName][]cache.Result
	m *sync.RWMutex
}

func NewResultsThreadsafe() ResultsThreadsafe {
	return ResultsThreadsafe{m: &sync.RWMutex{}, r: map[enum.CacheName][]cache.Result{}}
}

func (o *ResultsThreadsafe) Get(cacheName enum.CacheName) []cache.Result {
	o.m.RLock()
	defer o.m.RUnlock()
	return o.r[cacheName]
}

func (o *ResultsThreadsafe) Set(cacheName enum.CacheName, newR []cache.Result) {
	o.m.Lock()
	o.r[cacheName] = newR
	o.m.Unlock()
}

// StartHealthResultManager starts the goroutine which listens for health results.
// Note this polls the brief stat endpoint from ATS Astats, not the full stats.
// This poll should be quicker and less computationally expensive for ATS, but
// doesn't include all stat data needed for e.g. delivery service calculations.4
// Returns the last health durations, events, and the local cache statuses.
func StartHealthResultManager(cacheHealthChan <-chan cache.Result, toData todata.TODataThreadsafe, localStates peer.CRStatesThreadsafe, statHistory StatHistoryThreadsafe, monitorConfig TrafficMonitorConfigMapThreadsafe, peerStates peer.CRStatesPeersThreadsafe, combinedStates peer.CRStatesThreadsafe, fetchCount UintThreadsafe, errorCount UintThreadsafe, cfg config.Config) (DurationMapThreadsafe, EventsThreadsafe, CacheAvailableStatusThreadsafe) {
	lastHealthDurations := NewDurationMapThreadsafe()
	events := NewEventsThreadsafe(cfg.MaxEvents)
	localCacheStatus := NewCacheAvailableStatusThreadsafe()
	go healthResultManagerListen(cacheHealthChan, toData, localStates, lastHealthDurations, statHistory, monitorConfig, peerStates, combinedStates, fetchCount, errorCount, events, localCacheStatus, cfg)
	return lastHealthDurations, events, localCacheStatus
}

// cacheAggregateSeconds is how often to aggregate stats, if the health chan is never empty. (Otherwise, we read from the chan until it's empty, then aggregate, continuously)
const cacheAggregateSeconds = 1

func healthResultManagerListen(cacheHealthChan <-chan cache.Result, toData todata.TODataThreadsafe, localStates peer.CRStatesThreadsafe, lastHealthDurations DurationMapThreadsafe, statHistory StatHistoryThreadsafe, monitorConfig TrafficMonitorConfigMapThreadsafe, peerStates peer.CRStatesPeersThreadsafe, combinedStates peer.CRStatesThreadsafe, fetchCount UintThreadsafe, errorCount UintThreadsafe, events EventsThreadsafe, localCacheStatus CacheAvailableStatusThreadsafe, cfg config.Config) {
	lastHealthEndTimes := map[enum.CacheName]time.Time{}
	healthHistory := map[enum.CacheName][]cache.Result{}
	// This reads at least 1 value from the cacheHealthChan. Then, we loop, and try to read from the channel some more. If there's nothing to read, we hit `default` and process. If there is stuff to read, we read it, then inner-loop trying to read more. If we're continuously reading and the channel is never empty, and we hit the tick time, process anyway even though the channel isn't empty, to prevent never processing (starvation).
	for {
		var results []cache.Result
		results = append(results, <-cacheHealthChan)
		tick := time.Tick(cfg.HealthFlushInterval)
	innerLoop:
		for {
			select {
			case <-tick:
				log.Warnf("Health Result Manager flushing queued results\n")
				processHealthResult(cacheHealthChan, toData, localStates, lastHealthDurations, statHistory, monitorConfig, peerStates, combinedStates, fetchCount, errorCount, events, localCacheStatus, lastHealthEndTimes, healthHistory, results, cfg)
				break innerLoop
			default:
				select {
				case r := <-cacheHealthChan:
					results = append(results, r)
				default:
					processHealthResult(cacheHealthChan, toData, localStates, lastHealthDurations, statHistory, monitorConfig, peerStates, combinedStates, fetchCount, errorCount, events, localCacheStatus, lastHealthEndTimes, healthHistory, results, cfg)
					break innerLoop
				}
			}
		}
	}
}

func processHealthResult(cacheHealthChan <-chan cache.Result, toData todata.TODataThreadsafe, localStates peer.CRStatesThreadsafe, lastHealthDurations DurationMapThreadsafe, statHistory StatHistoryThreadsafe, monitorConfig TrafficMonitorConfigMapThreadsafe, peerStates peer.CRStatesPeersThreadsafe, combinedStates peer.CRStatesThreadsafe, fetchCount UintThreadsafe, errorCount UintThreadsafe, events EventsThreadsafe, localCacheStatus CacheAvailableStatusThreadsafe, lastHealthEndTimes map[enum.CacheName]time.Time, healthHistory map[enum.CacheName][]cache.Result, results []cache.Result, cfg config.Config) {
	if len(results) == 0 {
		return
	}
	toDataCopy := toData.Get()               // create a copy, so the same data used for all processing of this cache health result
	monitorConfigCopy := monitorConfig.Get() // copy now, so all calculations are on the same data
	for _, healthResult := range results {
		log.Debugf("poll %v %v healthresultman start\n", healthResult.PollID, time.Now())
		fetchCount.Inc()
		var prevResult cache.Result
		healthResultHistory := healthHistory[enum.CacheName(healthResult.Id)]
		// healthResultHistory := healthHistory.Get(enum.CacheName(healthResult.Id))
		if len(healthResultHistory) != 0 {
			prevResult = healthResultHistory[len(healthResultHistory)-1]
		}

		health.GetVitals(&healthResult, &prevResult, &monitorConfigCopy)
		// healthHistory.Set(enum.CacheName(healthResult.Id), pruneHistory(append(healthHistory.Get(enum.CacheName(healthResult.Id)), healthResult), defaultMaxHistory))
		healthHistory[enum.CacheName(healthResult.Id)] = pruneHistory(append(healthHistory[enum.CacheName(healthResult.Id)], healthResult), cfg.MaxHealthHistory)
		isAvailable, whyAvailable := health.EvalCache(healthResult, &monitorConfigCopy)
		if localStates.Get().Caches[healthResult.Id].IsAvailable != isAvailable {
			log.Infof("Changing state for %s was: %t now: %t because %s errors: %v", healthResult.Id, prevResult.Available, isAvailable, whyAvailable, healthResult.Errors)
			events.Add(Event{Time: time.Now().Unix(), Description: whyAvailable, Name: healthResult.Id, Hostname: healthResult.Id, Type: toDataCopy.ServerTypes[healthResult.Id].String(), Available: isAvailable})
		}

		localCacheStatus.Set(healthResult.Id, CacheAvailableStatus{Available: isAvailable, Status: monitorConfigCopy.TrafficServer[string(healthResult.Id)].Status}) // TODO move within localStates
		localStates.SetCache(healthResult.Id, peer.IsAvailable{IsAvailable: isAvailable})
		log.Debugf("poll %v %v calculateDeliveryServiceState start\n", healthResult.PollID, time.Now())
		calculateDeliveryServiceState(toDataCopy.DeliveryServiceServers, localStates)
		log.Debugf("poll %v %v calculateDeliveryServiceState end\n", healthResult.PollID, time.Now())
	}
	// TODO determine if we should combineCrStates() here

	for _, healthResult := range results {
		if lastHealthStart, ok := lastHealthEndTimes[enum.CacheName(healthResult.Id)]; ok {
			d := time.Since(lastHealthStart)
			lastHealthDurations.Set(enum.CacheName(healthResult.Id), d)
		}
		lastHealthEndTimes[enum.CacheName(healthResult.Id)] = time.Now()

		log.Debugf("poll %v %v finish\n", healthResult.PollID, time.Now())
		healthResult.PollFinished <- healthResult.PollID
	}
}

// calculateDeliveryServiceState calculates the state of delivery services from the new cache state data `cacheState` and the CRConfig data `deliveryServiceServers` and puts the calculated state in the outparam `deliveryServiceStates`
func calculateDeliveryServiceState(deliveryServiceServers map[enum.DeliveryServiceName][]enum.CacheName, states peer.CRStatesThreadsafe) {
	deliveryServices := states.GetDeliveryServices()
	for deliveryServiceName, deliveryServiceState := range deliveryServices {
		if _, ok := deliveryServiceServers[deliveryServiceName]; !ok {
			// log.Errorf("CRConfig does not have delivery service %s, but traffic monitor poller does; skipping\n", deliveryServiceName)
			continue
		}
		deliveryServiceState.IsAvailable = false
		deliveryServiceState.DisabledLocations = nil
		for _, server := range deliveryServiceServers[deliveryServiceName] {
			if states.GetCache(server).IsAvailable {
				deliveryServiceState.IsAvailable = true
			} else {
				deliveryServiceState.DisabledLocations = append(deliveryServiceState.DisabledLocations, server)
			}
		}
		deliveryServices[deliveryServiceName] = deliveryServiceState
	}
	states.SetDeliveryServices(deliveryServices)
}
