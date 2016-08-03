package http_server

import (
	"fmt"
	"github.com/hydrogen18/stoppableListener"
	"log"
	"net"
	"net/http"
	"sync"
	"time"
)

var mgrReqChan chan DataRequest

func writeResponse(w http.ResponseWriter, f Format, response <-chan []byte) {
	data := <-response
	if len(data) > 0 {
		w.Write(data)
	} else {
		w.WriteHeader(http.StatusServiceUnavailable)
	}
}

// Endpoints returns a map of HTTP paths to functions.
// This is a function because Go doesn't have constant map literals.
func Endpoints() (map[string]http.HandlerFunc, error) {
	handleRoot, err := handleRootFunc()
	if err != nil {
		return nil, fmt.Errorf("Error getting root endpoint: %v")
	}

	// note: with the trailing slash, any non-trailing slash requests will get a 301 redirect
	return map[string]http.HandlerFunc{
		"/publish/CacheStats/":       DataRequestFunc(CacheStats),
		"/publish/CrConfig":          DataRequestFunc(TRConfig),
		"/publish/CrStates":          handleCrStates,
		"/publish/DsStats":           DataRequestFunc(DSStats),
		"/publish/EventLog":          DataRequestFunc(EventLog),
		"/publish/PeerStates":        DataRequestFunc(PeerStates),
		"/publish/StatSummary":       DataRequestFunc(StatSummary),
		"/publish/Stats":             DataRequestFunc(Stats),
		"/publish/ConfigDoc":         DataRequestFunc(ConfigDoc),
		"/api/cache-count":           DataRequestFunc(APICacheCount),
		"/api/cache-available-count": DataRequestFunc(APICacheAvailableCount),
		"/api/cache-down-count":      DataRequestFunc(APICacheDownCount),
		"/api/version":               DataRequestFunc(APIVersion),
		"/api/traffic-ops-uri":       DataRequestFunc(APITrafficOpsURI),
		"/api/cache-statuses":        DataRequestFunc(APICacheStates),
		"/": handleRoot,
	}, nil
}

func RegisterEndpoints(sm *http.ServeMux) error {
	endpoints, err := Endpoints()
	if err != nil {
		return err
	}
	for path, f := range endpoints {
		sm.HandleFunc(path, f)
	}
	return nil
}

var globalStoppableListener *stoppableListener.StoppableListener
var globalStoppableListenerWaitGroup sync.WaitGroup

// Run runs a new HTTP service at the given addr, making data requests to the given c.
// Run may be called repeatedly, and each time, will shut down any existing service first.
// Run is NOT threadsafe, and MUST NOT be called concurrently by multiple goroutines.
func Run(c chan DataRequest, addr string) error {
	// TODO make an object, which itself is not threadsafe, but which encapsulates all data so multiple
	//      objects can be created and Run.

	if globalStoppableListener != nil {
		log.Printf("Stopping Web Server\n")
		globalStoppableListener.Stop()
		globalStoppableListenerWaitGroup.Wait()
	}
	log.Printf("Starting Web Server\n")

	var err error
	var originalListener net.Listener
	if originalListener, err = net.Listen("tcp", addr); err != nil {
		return err
	}
	if globalStoppableListener, err = stoppableListener.New(originalListener); err != nil {
		return err
	}

	mgrReqChan = c

	sm := http.NewServeMux()
	err = RegisterEndpoints(sm)
	if err != nil {
		return err
	}
	server := &http.Server{
		Addr:           addr,
		Handler:        sm,
		ReadTimeout:    10 * time.Second,
		WriteTimeout:   10 * time.Second,
		MaxHeaderBytes: 1 << 20,
	}

	globalStoppableListenerWaitGroup = sync.WaitGroup{}
	globalStoppableListenerWaitGroup.Add(1)
	go func() {
		defer globalStoppableListenerWaitGroup.Done()
		server.Serve(globalStoppableListener)
	}()

	log.Printf("Web server listening on %s", addr)
	return nil
}
