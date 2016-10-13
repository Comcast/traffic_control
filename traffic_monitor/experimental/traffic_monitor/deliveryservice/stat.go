package deliveryservice

import (
	"fmt"
	"github.com/Comcast/traffic_control/traffic_monitor/experimental/common/log"
	"github.com/Comcast/traffic_control/traffic_monitor/experimental/traffic_monitor/cache"
	dsdata "github.com/Comcast/traffic_control/traffic_monitor/experimental/traffic_monitor/deliveryservicedata"
	"github.com/Comcast/traffic_control/traffic_monitor/experimental/traffic_monitor/enum"
	"github.com/Comcast/traffic_control/traffic_monitor/experimental/traffic_monitor/http_server"
	"github.com/Comcast/traffic_control/traffic_monitor/experimental/traffic_monitor/peer"
	todata "github.com/Comcast/traffic_control/traffic_monitor/experimental/traffic_monitor/trafficopsdata"
	"net/url"
	"strconv"
	"time"
)

// TODO remove 'ds' and 'stat' from names

// TODO remove DeliveryService and set type to the map directly, or add other members
type Stats struct {
	DeliveryService map[enum.DeliveryServiceName]dsdata.Stat `json:"deliveryService"`
}

func (a Stats) Copy() Stats {
	b := NewStats()
	for k, v := range a.DeliveryService {
		b.DeliveryService[k] = v.Copy()
	}
	return b
}

func (a Stats) Get(name enum.DeliveryServiceName) (dsdata.StatReadonly, bool) {
	ds, ok := a.DeliveryService[name]
	return ds, ok
}

// TODO rename to just 'New'?
func NewStats() Stats {
	return Stats{DeliveryService: map[enum.DeliveryServiceName]dsdata.Stat{}}
}

func setStaticData(dsStats Stats, dsServers map[enum.DeliveryServiceName][]enum.CacheName) Stats {
	for ds, stat := range dsStats.DeliveryService {
		stat.CommonStats.CachesConfiguredNum.Value = int64(len(dsServers[ds]))
		dsStats.DeliveryService[ds] = stat // TODO consider changing dsStats.DeliveryService[ds] to a pointer so this kind of thing isn't necessary; possibly more performant, as well
	}
	return dsStats
}

func addAvailableData(dsStats Stats, crStates peer.Crstates, serverCachegroups map[enum.CacheName]enum.CacheGroupName, serverDs map[enum.CacheName][]enum.DeliveryServiceName, serverTypes map[enum.CacheName]enum.CacheType, statHistory map[enum.CacheName][]cache.Result) (Stats, error) {
	for cache, available := range crStates.Caches {
		cacheGroup, ok := serverCachegroups[cache]
		if !ok {
			log.Warnf("CreateStats not adding availability data for '%s': not found in Cachegroups\n", cache)
			continue
		}
		deliveryServices, ok := serverDs[cache]
		if !ok {
			log.Warnf("CreateStats not adding availability data for '%s': not found in DeliveryServices\n", cache)
			continue
		}
		cacheType, ok := serverTypes[enum.CacheName(cache)]
		if !ok {
			log.Warnf("CreateStats not adding availability data for '%s': not found in Server Types\n", cache)
			continue
		}

		for _, deliveryService := range deliveryServices {
			if deliveryService == "" {
				log.Errorf("EMPTY addAvailableData DS") // various bugs in other functions can cause this - this will help identify and debug them.
				continue
			}

			stat, ok := dsStats.DeliveryService[enum.DeliveryServiceName(deliveryService)]
			if !ok {
				log.Warnf("CreateStats not adding availability data for '%s': not found in Stats\n", cache)
				continue // TODO log warning? Error?
			}

			if available.IsAvailable {
				// c.IsAvailable.Value
				stat.CommonStats.IsAvailable.Value = true
				stat.CommonStats.CachesAvailableNum.Value++
				cacheGroupStats := stat.CacheGroups[enum.CacheGroupName(cacheGroup)]
				cacheGroupStats.IsAvailable.Value = true
				stat.CacheGroups[enum.CacheGroupName(cacheGroup)] = cacheGroupStats
				stat.TotalStats.IsAvailable.Value = true
				typeStats := stat.Types[cacheType]
				typeStats.IsAvailable.Value = true
				stat.Types[cacheType] = typeStats
			}

			// TODO fix nested ifs
			if results, ok := statHistory[enum.CacheName(cache)]; ok {
				if len(results) < 1 {
					log.Warnf("no results %v %v\n", cache, deliveryService)
				} else {
					result := results[0]
					if result.PrecomputedData.Reporting {
						stat.CommonStats.CachesReporting[enum.CacheName(cache)] = true
					} else {
						log.Debugf("no reporting %v %v\n", cache, deliveryService)
					}
				}
			} else {
				log.Debugf("no result for %v %v\n", cache, deliveryService)
			}

			dsStats.DeliveryService[enum.DeliveryServiceName(deliveryService)] = stat // TODO Necessary? Remove?
		}
	}
	return dsStats, nil
}

// LastStats includes the previously recieved stats for DeliveryServices and Caches, the stat itself, when it was received, and the stat value per second.
type LastStats struct {
	DeliveryServices map[enum.DeliveryServiceName]LastDSStat
	Caches           map[enum.CacheName]LastStatsData
}

func NewLastStats() LastStats {
	return LastStats{DeliveryServices: map[enum.DeliveryServiceName]LastDSStat{}, Caches: map[enum.CacheName]LastStatsData{}}
}

func (a LastStats) Copy() LastStats {
	b := NewLastStats()
	for k, v := range a.DeliveryServices {
		b.DeliveryServices[k] = v.Copy()
	}
	for k, v := range a.Caches {
		b.Caches[k] = v
	}
	return b
}

// TODO figure a way to associate this type with StatHTTP, with which its members correspond.
type LastDSStat struct {
	Caches      map[enum.CacheName]LastStatsData
	CacheGroups map[enum.CacheGroupName]LastStatsData
	Type        map[enum.CacheType]LastStatsData
	Total       LastStatsData
}

func (a LastDSStat) Copy() LastDSStat {
	b := LastDSStat{
		CacheGroups: map[enum.CacheGroupName]LastStatsData{},
		Type:        map[enum.CacheType]LastStatsData{},
		Caches:      map[enum.CacheName]LastStatsData{},
		Total:       a.Total,
	}
	for k, v := range a.CacheGroups {
		b.CacheGroups[k] = v
	}
	for k, v := range a.Type {
		b.Type[k] = v
	}
	for k, v := range a.Caches {
		b.Caches[k] = v
	}
	return b
}

func newLastDSStat() LastDSStat {
	return LastDSStat{
		CacheGroups: map[enum.CacheGroupName]LastStatsData{},
		Type:        map[enum.CacheType]LastStatsData{},
		Caches:      map[enum.CacheName]LastStatsData{},
	}
}

type LastStatsData struct {
	Bytes     LastStatData
	Status2xx LastStatData
	Status3xx LastStatData
	Status4xx LastStatData
	Status5xx LastStatData
}

// Sum returns the Sum() of each member data with the given LastStatsData corresponding members
func (a LastStatsData) Sum(b LastStatsData) LastStatsData {
	return LastStatsData{
		Bytes:     a.Bytes.Sum(b.Bytes),
		Status2xx: a.Status2xx.Sum(b.Status2xx),
		Status3xx: a.Status3xx.Sum(b.Status3xx),
		Status4xx: a.Status4xx.Sum(b.Status4xx),
		Status5xx: a.Status5xx.Sum(b.Status5xx),
	}
}

type LastStatData struct {
	PerSec float64
	Stat   int64
	Time   time.Time
}

// Sum adds the PerSec and Stat of the given data to this object. Time is meaningless for the summed object, and is thus set to 0.
func (a LastStatData) Sum(b LastStatData) LastStatData {
	return LastStatData{
		PerSec: a.PerSec + b.PerSec,
		Stat:   a.Stat + b.Stat,
	}
}

const BytesPerKilobit = 125

func addLastStat(lastData LastStatData, newStat int64, newStatTime time.Time) (LastStatData, error) {
	if newStat == lastData.Stat {
		return lastData, nil
	}

	if newStat < lastData.Stat {
		return lastData, fmt.Errorf("new stat '%d'@'%v' value less than last stat '%d'@'%v'", lastData.Stat, lastData.Time, newStat, newStatTime)
	}

	if newStatTime.Before(lastData.Time) {
		return lastData, fmt.Errorf("new stat '%d'@'%v' time less than last stat '%d'@'%v'", lastData.Stat, lastData.Time, newStat, newStatTime)
	}

	if lastData.Stat != 0 {
		lastData.PerSec = float64(newStat-lastData.Stat) / newStatTime.Sub(lastData.Time).Seconds()
	}

	lastData.Stat = newStat
	lastData.Time = newStatTime
	return lastData, nil
}

func combineErrs(errs []error) error {
	combinedErr := ""
	for _, err := range errs {
		if err != nil {
			combinedErr += err.Error() + ", "
		}
	}
	if len(combinedErr) == 0 {
		return nil
	}
	combinedErr = combinedErr[:len(combinedErr)-2] // strip trailing ', '
	return fmt.Errorf("%s", combinedErr)
}

func addLastStats(lastData LastStatsData, newStats dsdata.StatCacheStats, newStatsTime time.Time) (LastStatsData, error) {
	errs := []error{nil, nil, nil, nil, nil}
	lastData.Bytes, errs[0] = addLastStat(lastData.Bytes, newStats.OutBytes.Value, newStatsTime)
	lastData.Status2xx, errs[1] = addLastStat(lastData.Status2xx, newStats.Status2xx.Value, newStatsTime)
	lastData.Status3xx, errs[2] = addLastStat(lastData.Status3xx, newStats.Status3xx.Value, newStatsTime)
	lastData.Status4xx, errs[3] = addLastStat(lastData.Status4xx, newStats.Status4xx.Value, newStatsTime)
	lastData.Status5xx, errs[4] = addLastStat(lastData.Status5xx, newStats.Status5xx.Value, newStatsTime)
	return lastData, combineErrs(errs)
}

func addLastStatsToStatCacheStats(s dsdata.StatCacheStats, l LastStatsData) dsdata.StatCacheStats {
	s.Kbps.Value = l.Bytes.PerSec / BytesPerKilobit
	s.Tps2xx.Value = l.Status2xx.PerSec
	s.Tps3xx.Value = l.Status3xx.PerSec
	s.Tps4xx.Value = l.Status4xx.PerSec
	s.Tps5xx.Value = l.Status5xx.PerSec
	return s
}

// addLastDSStatTotals takes a LastDSStat with only raw `Caches` data, and calculates and sets the `CacheGroups`, `Type`, and `Total` data, and returns the augmented structure.
func addLastDSStatTotals(lastStat LastDSStat, cachesReporting map[enum.CacheName]bool, serverCachegroups map[enum.CacheName]enum.CacheGroupName, serverTypes map[enum.CacheName]enum.CacheType) LastDSStat {
	cacheGroups := map[enum.CacheGroupName]LastStatsData{}
	cacheTypes := map[enum.CacheType]LastStatsData{}
	total := LastStatsData{}
	for cacheName, cacheStats := range lastStat.Caches {
		if !cachesReporting[cacheName] {
			continue
		}

		if cacheGroup, ok := serverCachegroups[cacheName]; ok {
			cacheGroups[cacheGroup] = cacheGroups[cacheGroup].Sum(cacheStats)
		} else {
			log.Errorf("while computing delivery service data, cache %v not in cachegroups\n", cacheName)
		}

		if cacheType, ok := serverTypes[cacheName]; ok {
			cacheTypes[cacheType] = cacheTypes[cacheType].Sum(cacheStats)
		} else {
			log.Errorf("while computing delivery service data, cache %v not in types\n", cacheName)
		}
		total = total.Sum(cacheStats)
	}
	lastStat.CacheGroups = cacheGroups
	lastStat.Type = cacheTypes
	lastStat.Total = total
	return lastStat
}

// addDSPerSecStats calculates and adds the per-second delivery service stats to both the Stats and LastStats structures, and returns the augmented structures.
func addDSPerSecStats(dsName enum.DeliveryServiceName, stat dsdata.Stat, lastStats LastStats, dsStats Stats, dsStatsTime time.Time, serverCachegroups map[enum.CacheName]enum.CacheGroupName, serverTypes map[enum.CacheName]enum.CacheType) (Stats, LastStats) {
	err := error(nil)
	lastStat, lastStatExists := lastStats.DeliveryServices[dsName]
	if !lastStatExists {
		lastStat = newLastDSStat()
	}

	for cacheName, cacheStats := range stat.Caches {
		lastStat.Caches[cacheName], err = addLastStats(lastStat.Caches[cacheName], cacheStats, dsStatsTime)
		if err != nil {
			log.Errorf("debugq %v Error adding kbps for cache %v: %v", cacheName, err)
			continue
		}
		cacheStats.Kbps.Value = lastStat.Caches[cacheName].Bytes.PerSec / BytesPerKilobit
		stat.Caches[cacheName] = cacheStats
	}

	lastStat = addLastDSStatTotals(lastStat, stat.CommonStats.CachesReporting, serverCachegroups, serverTypes)

	for cacheGroup, cacheGroupStat := range lastStat.CacheGroups {
		stat.CacheGroups[cacheGroup] = addLastStatsToStatCacheStats(stat.CacheGroups[cacheGroup], cacheGroupStat)
	}
	for cacheType, cacheTypeStat := range lastStat.Type {
		stat.Types[cacheType] = addLastStatsToStatCacheStats(stat.Types[cacheType], cacheTypeStat)
	}
	stat.TotalStats = addLastStatsToStatCacheStats(stat.TotalStats, lastStat.Total)
	lastStats.DeliveryServices[dsName] = lastStat
	dsStats.DeliveryService[dsName] = stat
	return dsStats, lastStats
}

// latestBytes returns the most recent OutBytes from the given cache results, and the time of that result. It assumes zero results are not valid, but nonzero results with errors are valid.
func latestBytes(results []cache.Result) (int64, time.Time, error) {
	var result *cache.Result
	for _, r := range results {
		// result.Errors can include stat errors where OutBytes was set correctly, so we look for the first non-zero OutBytes rather than the first errorless result
		// TODO add error classes to PrecomputedData, to distinguish stat errors from HTTP errors?
		if r.PrecomputedData.OutBytes == 0 {
			continue
		}
		result = &r
		break
	}
	if result == nil {
		return 0, time.Time{}, fmt.Errorf("no valid results")
	}
	return result.PrecomputedData.OutBytes, result.Time, nil
}

// addCachePerSecStats calculates the cache per-second stats, adds them to LastStats, and returns the augmented object.
func addCachePerSecStats(cacheName enum.CacheName, results []cache.Result, lastStats LastStats) LastStats {
	outBytes, outBytesTime, err := latestBytes(results) // it's ok if `latestBytes` returns 0s with an error, `addLastStat` will refrain from setting it (unless the previous calculation was nonzero, in which case it will error appropriately).
	if err != nil {
		log.Warnf("while computing delivery service data for cache %v: %v\n", cacheName, err)
	}
	lastStat := lastStats.Caches[cacheName] // if lastStats.Caches[cacheName] doesn't exist, it will be zero-constructed, and `addLastStat` will refrain from setting the PerSec for zero LastStats
	lastStat.Bytes, err = addLastStat(lastStat.Bytes, outBytes, outBytesTime)
	if err != nil {
		log.Errorf("while computing delivery service data for cache %v: %v\n", cacheName, err)
		return lastStats
	}
	lastStats.Caches[cacheName] = lastStat

	return lastStats
}

// addPerSecStats adds Kbps fields to the NewStats, based on the previous out_bytes in the oldStats, and the time difference.
//
// Traffic Server only updates its data every N seconds. So, often we get a new Stats with the same OutBytes as the previous one,
// So, we must record the last changed value, and the time it changed. Then, if the new OutBytes is different from the previous,
// we set the (new - old) / lastChangedTime as the KBPS, and update the recorded LastChangedTime and LastChangedValue
//
// TODO handle ATS byte rolling (when the `out_bytes` overflows back to 0)
func addPerSecStats(statHistory map[enum.CacheName][]cache.Result, dsStats Stats, lastStats LastStats, dsStatsTime time.Time, serverCachegroups map[enum.CacheName]enum.CacheGroupName, serverTypes map[enum.CacheName]enum.CacheType) (Stats, LastStats) {
	for dsName, stat := range dsStats.DeliveryService {
		dsStats, lastStats = addDSPerSecStats(dsName, stat, lastStats, dsStats, dsStatsTime, serverCachegroups, serverTypes)
	}
	for cacheName, results := range statHistory {
		lastStats = addCachePerSecStats(cacheName, results, lastStats)
	}
	return dsStats, lastStats
}

func CreateStats(statHistory map[enum.CacheName][]cache.Result, toData todata.TOData, crStates peer.Crstates, lastStats LastStats, now time.Time) (Stats, LastStats, error) {
	start := time.Now()
	dsStats := NewStats()
	for deliveryService, _ := range toData.DeliveryServiceServers {
		if deliveryService == "" {
			log.Errorf("EMPTY CreateStats deliveryService")
			continue
		}
		dsStats.DeliveryService[enum.DeliveryServiceName(deliveryService)] = *dsdata.NewStat()
	}
	dsStats = setStaticData(dsStats, toData.DeliveryServiceServers)
	var err error
	dsStats, err = addAvailableData(dsStats, crStates, toData.ServerCachegroups, toData.ServerDeliveryServices, toData.ServerTypes, statHistory) // TODO move after stat summarisation
	if err != nil {
		return dsStats, lastStats, fmt.Errorf("Error getting Cache availability data: %v", err)
	}

	for server, history := range statHistory {
		if len(history) < 1 {
			continue // TODO warn?
		}
		cachegroup, ok := toData.ServerCachegroups[server]
		if !ok {
			log.Warnf("server %s has no cachegroup, skipping\n", server)
			continue
		}
		serverType, ok := toData.ServerTypes[enum.CacheName(server)]
		if !ok {
			log.Warnf("server %s not in CRConfig, skipping\n", server)
			continue
		}
		result := history[len(history)-1]

		// TODO check result.PrecomputedData.Errors
		for ds, resultStat := range result.PrecomputedData.DeliveryServiceStats {
			if ds == "" {
				log.Errorf("EMPTY precomputed delivery service")
				continue
			}

			if _, ok := dsStats.DeliveryService[ds]; !ok {
				dsStats.DeliveryService[ds] = resultStat
				continue
			}
			httpDsStat := dsStats.DeliveryService[ds]
			httpDsStat.TotalStats = httpDsStat.TotalStats.Sum(resultStat.TotalStats)
			httpDsStat.CacheGroups[cachegroup] = httpDsStat.CacheGroups[cachegroup].Sum(resultStat.CacheGroups[cachegroup])
			httpDsStat.Types[serverType] = httpDsStat.Types[serverType].Sum(resultStat.Types[serverType])
			httpDsStat.Caches[server] = httpDsStat.Caches[server].Sum(resultStat.Caches[server])
			httpDsStat.CachesTimeReceived[server] = resultStat.CachesTimeReceived[server]
			httpDsStat.CommonStats = dsStats.DeliveryService[ds].CommonStats
			dsStats.DeliveryService[ds] = httpDsStat // TODO determine if necessary
		}
	}

	perSecStats, lastStats := addPerSecStats(statHistory, dsStats, lastStats, now, toData.ServerCachegroups, toData.ServerTypes)
	log.Infof("CreateStats took %v\n", time.Since(start))
	return perSecStats, lastStats, nil
}

func addStatCacheStats(s *dsdata.StatsOld, c dsdata.StatCacheStats, deliveryService enum.DeliveryServiceName, prefix string, t int64, filter dsdata.Filter) *dsdata.StatsOld {
	add := func(name, val string) {
		if filter.UseStat(name) {
			s.DeliveryService[deliveryService][dsdata.StatName(prefix+name)] = []dsdata.StatOld{dsdata.StatOld{Time: t, Value: val}}
		}
	}
	add("out_bytes", strconv.Itoa(int(c.OutBytes.Value)))
	add("isAvailable", fmt.Sprintf("%t", c.IsAvailable.Value))
	add("status_5xx", strconv.Itoa(int(c.Status5xx.Value)))
	add("status_4xx", strconv.Itoa(int(c.Status4xx.Value)))
	add("status_3xx", strconv.Itoa(int(c.Status3xx.Value)))
	add("status_2xx", strconv.Itoa(int(c.Status2xx.Value)))
	add("in_bytes", strconv.Itoa(int(c.InBytes.Value)))
	add("kbps", strconv.Itoa(int(c.Kbps.Value)))
	add("tps_5xx", fmt.Sprintf("%f", c.Tps5xx.Value))
	add("tps_4xx", fmt.Sprintf("%f", c.Tps4xx.Value))
	add("tps_3xx", fmt.Sprintf("%f", c.Tps3xx.Value))
	add("tps_2xx", fmt.Sprintf("%f", c.Tps2xx.Value))
	add("error", c.ErrorString.Value)
	add("tps_total", strconv.Itoa(int(c.TpsTotal.Value)))
	return s
}

func addCommonData(s *dsdata.StatsOld, c *dsdata.StatCommon, deliveryService enum.DeliveryServiceName, t int64, filter dsdata.Filter) *dsdata.StatsOld {
	add := func(name, val string) {
		if filter.UseStat(name) {
			s.DeliveryService[deliveryService][dsdata.StatName(name)] = []dsdata.StatOld{dsdata.StatOld{Time: t, Value: val}}
		}
	}
	add("caches-configured", strconv.Itoa(int(c.CachesConfiguredNum.Value)))
	add("caches-reporting", strconv.Itoa(len(c.CachesReporting)))
	add("error-string", strconv.Itoa(len(c.CachesReporting)))
	add("status", c.StatusStr.Value)
	add("isHealthy", fmt.Sprintf("%t", c.IsHealthy.Value))
	add("isAvailable", fmt.Sprintf("%t", c.IsAvailable.Value))
	add("caches-available", strconv.Itoa(int(c.CachesAvailableNum.Value)))
	return s
}

// StatsJSON returns an object formatted as expected to be serialized to JSON and served.
func (dsStats Stats) JSON(filter dsdata.Filter, params url.Values) dsdata.StatsOld {
	now := time.Now().Unix()
	jsonObj := &dsdata.StatsOld{
		DeliveryService: map[enum.DeliveryServiceName]map[dsdata.StatName][]dsdata.StatOld{},
		QueryParams:     http_server.ParametersStr(params),
		DateStr:         http_server.DateStr(time.Now()),
	}

	for deliveryService, stat := range dsStats.DeliveryService {
		if !filter.UseDeliveryService(deliveryService) {
			continue
		}
		jsonObj.DeliveryService[deliveryService] = map[dsdata.StatName][]dsdata.StatOld{}
		jsonObj = addCommonData(jsonObj, &stat.CommonStats, deliveryService, now, filter)
		for cacheGroup, cacheGroupStats := range stat.CacheGroups {
			jsonObj = addStatCacheStats(jsonObj, cacheGroupStats, deliveryService, "location."+string(cacheGroup)+".", now, filter)
		}
		for cacheType, typeStats := range stat.Types {
			jsonObj = addStatCacheStats(jsonObj, typeStats, deliveryService, "type."+cacheType.String()+".", now, filter)
		}
		jsonObj = addStatCacheStats(jsonObj, stat.TotalStats, deliveryService, "total.", now, filter)
	}
	return *jsonObj
}
