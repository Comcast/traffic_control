package manager

import (
	"github.com/Comcast/traffic_control/traffic_monitor/experimental/traffic_monitor/enum"
	"sync"
)

// TODO put somewhere more generic
const CacheAvailableStatusReported = "REPORTED"

type CacheAvailableStatus struct {
	Available bool
	Status    string
}

type CacheAvailableStatuses map[enum.CacheName]CacheAvailableStatus

type CacheAvailableStatusThreadsafe struct {
	caches *CacheAvailableStatuses
	m      *sync.RWMutex
}

func (a CacheAvailableStatuses) Copy() CacheAvailableStatuses {
	b := CacheAvailableStatuses(map[enum.CacheName]CacheAvailableStatus{})
	for k, v := range a {
		b[k] = v
	}
	return b
}

func NewCacheAvailableStatusThreadsafe() CacheAvailableStatusThreadsafe {
	c := CacheAvailableStatuses(map[enum.CacheName]CacheAvailableStatus{})
	return CacheAvailableStatusThreadsafe{m: &sync.RWMutex{}, caches: &c}
}

func (o *CacheAvailableStatusThreadsafe) Get() CacheAvailableStatuses {
	o.m.RLock()
	defer o.m.RUnlock()
	return *o.caches
}

func (o *CacheAvailableStatusThreadsafe) Set(v CacheAvailableStatuses) {
	o.m.Lock()
	*o.caches = v
	o.m.Unlock()
}
