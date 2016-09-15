package main

import (
	"errors"
	"github.com/Comcast/traffic_control/infrastructure/test/apitest"
	"github.com/Comcast/traffic_control/infrastructure/test/environment"
	"io/ioutil"
	"net/http"
	"strings"
	"testing"
)

type trafficOpsApiTesterData struct {
	fqdn    string
	cookies []*http.Cookie
}

// TrafficOpsAPIPath is the path prefix for Traffic Ops API endpoints
const TrafficOpsAPIPath = "/api/1.2/"

// NewApiTester creates and returns a new ApiTester,
// logging in to the Traffic Ops instance specified in `test/environment` to get an auth token.
// Does not return an error - calls t.Fatal on error
func NewApiTester(t *testing.T) apitest.ApiTester {
	env, err := environment.Get(environment.DefaultPath)
	if err != nil {
		t.Fatalf("Failed to get environment: %v\n", err)
	}

	// getTrafficOpsCookie logs in to Traffic Ops and returns an auth cookie
	getTrafficOpsCookie := func(cdnUri, user, pass string) (string, error) {
		uri := cdnUri + TrafficOpsAPIPath + "user/login"
		postdata := `{"u":"` + user + `", "p":"` + pass + `"}`
		req, err := http.NewRequest("POST", uri, strings.NewReader(postdata))
		if err != nil {
			return "", err
		}
		req.Header.Add("Accept", "application/json")

		client := apitest.GetClient()
		resp, err := client.Do(req)
		if err != nil {
			return "", err
		}
		defer resp.Body.Close()

		for _, cookie := range resp.Cookies() {
			if cookie.Name == `mojolicious` {
				return cookie.Value, nil
			}
		}

		data, err := ioutil.ReadAll(resp.Body)
		if err != nil {
			return "", err
		}
		return "", errors.New("No login cookie received: " + string(data))
	}

	token, err := getTrafficOpsCookie(env.TrafficOps.URI, env.TrafficOps.User, env.TrafficOps.Password)
	if err != nil {
		t.Fatal(err)
	}
	return &trafficOpsApiTesterData{fqdn: env.TrafficOps.URI, cookies: []*http.Cookie{&http.Cookie{Name: "mojolicious", Value: token}}}
}

// ApiPath returns the Traffic Ops API path
func (a *trafficOpsApiTesterData) ApiPath() string {
	return TrafficOpsAPIPath
}

// FQDN returns the Traffic Ops FQDN
func (a *trafficOpsApiTesterData) FQDN() string {
	return a.fqdn
}

// FQDN returns the mojolicous auth cookie
func (a *trafficOpsApiTesterData) Cookies() []*http.Cookie {
	return a.cookies
}
