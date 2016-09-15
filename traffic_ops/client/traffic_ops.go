/*
   Copyright 2015 Comcast Cable Communications Management, LLC

   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

   http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.
*/

package client

import (
	"bytes"
	"crypto/tls"
	"encoding/json"
	"fmt"
	"io/ioutil"
	"net/http"
	"net/http/cookiejar"
	"time"

	"github.com/cihub/seelog"
	"golang.org/x/net/publicsuffix"
)

// Session ...
type Session struct {
	UserName  string
	Password  string
	URL       string
	UserAgent *http.Client
	Cache     map[string]CacheEntry
}

// HTTPError is returned on Update Session failure.
type HTTPError struct {
	HTTPStatusCode int
	HTTPStatus     string
	URL            string
}

// Error implements the error interface for our customer error type.
func (e *HTTPError) Error() string {
	return fmt.Sprintf("%s[%d] - Error requesting Traffic Ops %s", e.HTTPStatus, e.HTTPStatusCode, e.URL)
}

// Result {"response":[{"level":"success","text":"Successfully logged in."}],"version":"1.1"}
type Result struct {
	Alerts  []Alert
	Version string `json:"version"`
}

// Alert ...
type Alert struct {
	Level string `json:"level"`
	Text  string `json:"text"`
}

// CacheEntry ...
type CacheEntry struct {
	Entered int64
	Bytes   []byte
}

// Credentials contains Traffic Ops login credentials
type Credentials struct {
	Username string `json:"u"`
	Password string `json:"p"`
}

// TODO JvD
const tmPollingInterval = 60

// loginCreds gathers login credentials for Traffic Ops.
func loginCreds(toUser string, toPasswd string) ([]byte, error) {
	credentials := Credentials{
		Username: toUser,
		Password: toPasswd,
	}

	js, err := json.Marshal(credentials)
	if err != nil {
		err := fmt.Errorf("Error creating login json: %v", err)
		return nil, err
	}
	return js, nil
}

// Login to traffic_ops, the response should set the cookie for this session
// automatically. Start with
//     to := traffic_ops.Login("user", "passwd", true)
// subsequent calls like to.GetData("datadeliveryservice") will be authenticated.
func Login(toURL string, toUser string, toPasswd string, insecure bool) (*Session, error) {
	credentials, err := loginCreds(toUser, toPasswd)
	if err != nil {
		return nil, err
	}

	options := cookiejar.Options{
		PublicSuffixList: publicsuffix.List,
	}

	jar, err := cookiejar.New(&options)
	if err != nil {
		return nil, err
	}

	to := Session{
		UserAgent: &http.Client{
			Transport: &http.Transport{
				TLSClientConfig: &tls.Config{InsecureSkipVerify: insecure},
			},
			Jar: jar,
		},
		URL:      toURL,
		UserName: toUser,
		Password: toPasswd,
		Cache:    make(map[string]CacheEntry),
	}

	path := "/api/1.2/user/login"
	resp, err := to.request(path, credentials)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	var result Result
	if err := json.NewDecoder(resp.Body).Decode(&result); err != nil {
		return nil, err
	}

	success := false
	for _, alert := range result.Alerts {
		if alert.Level == "success" && alert.Text == "Successfully logged in." {
			success = true
			break
		}
	}

	if !success {
		err := fmt.Errorf("Login failed, result string: %+v", result)
		return nil, err
	}

	seelog.Debugf("logged into Traffic Ops: %s", toURL)
	return &to, nil
}

// request performs the actual HTTP request to Traffic Ops
func (to *Session) request(path string, body []byte) (*http.Response, error) {
	url := fmt.Sprintf("%s%s", to.URL, path)

	var req *http.Request
	var err error

	if body != nil {
		req, err = http.NewRequest("POST", url, bytes.NewBuffer(body))
		if err != nil {
			return nil, err
		}
		req.Header.Set("Content-Type", "application/json")
	} else {
		req, err = http.NewRequest("GET", url, nil)
		if err != nil {
			return nil, err
		}
	}

	resp, err := to.UserAgent.Do(req)
	if err != nil {
		return nil, err
	}

	if resp.StatusCode != http.StatusOK {
		e := HTTPError{
			HTTPStatus:     resp.Status,
			HTTPStatusCode: resp.StatusCode,
			URL:            url,
		}
		return nil, &e
	}

	seelog.Infof("request %s, StatusCode[%d]", url, resp.StatusCode)
	return resp, nil
}

// getBytesWithTTL - get the path, and cache in the session
// return from cache is found and the ttl isn't expired, otherwise get it and
// store it in cache
func (to *Session) getBytesWithTTL(path string, ttl int64) ([]byte, error) {
	var body []byte
	var err error
	getFresh := false
	if cacheEntry, ok := to.Cache[path]; ok {
		if cacheEntry.Entered > time.Now().Unix()-ttl {
			seelog.Debugf("Cache HIT for %s%s", to.URL, path)
			body = cacheEntry.Bytes
		} else {
			seelog.Debugf("Cache HIT but EXPIRED for %s%s", to.URL, path)
			getFresh = true
		}
	} else {
		to.Cache = make(map[string]CacheEntry)
		seelog.Debugf("Cache MISS for %s%s", to.URL, path)
		getFresh = true
	}

	if getFresh {
		body, err = to.getBytes(path)
		if err != nil {
			return nil, err
		}

		newEntry := CacheEntry{
			Entered: time.Now().Unix(),
			Bytes:   body,
		}
		to.Cache[path] = newEntry
	}

	return body, nil
}

// GetBytes - get []bytes array for a certain path on the to session.
// returns the raw body
func (to *Session) getBytes(path string) ([]byte, error) {
	resp, err := to.request(path, nil)
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
