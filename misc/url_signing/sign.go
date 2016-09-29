/*
 * Licensed to the Apache Software Foundation (ASF) under one
 * or more contributor license agreements.  See the NOTICE file
 * distributed with this work for additional information
 * regarding copyright ownership.  The ASF licenses this file
 * to you under the Apache License, Version 2.0 (the
 * "License"); you may not use this file except in compliance
 * with the License.  You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.package main
 */

package main

import (
	"bytes"
	"crypto/hmac"
	"crypto/md5"
	"crypto/sha1"
	"encoding/base64"
	"encoding/hex"
	"errors"
	"flag"
	"fmt"
	"hash"
	"log"
	"os"
	"regexp"
	"strconv"
	"strings"
	"time"
)

var durationParam, keyindexParam, expirationParam int
var usepartsParam, clientParam, urlParam, algoParam, keyParam string
var pathparamsParam, verboseParam bool

var algoLookup = make(map[string]int)

const SHA1 string = "SHA1"
const MD5 string = "MD5"

// signature formats
const queryParamSignatureFormat string = "E=%d&A=%d&K=%d&P=%v&S="
const pathSignatureFormat string = "E=%d;A=%d;K=%d&P=%v;S="
const clientQueryFormat string = "C=%v&" + queryParamSignatureFormat
const clientPathFormat string = "C=%v;" + pathSignatureFormat

var httpSchemeRegex = regexp.MustCompile("https?:\\/\\/.*")

func init() {

	algoLookup[SHA1] = 1
	algoLookup[MD5] = 2
	flag.StringVar(&usepartsParam, "useparts", "01", "Parts of URL to use for signing")
	flag.IntVar(&durationParam, "duration", 86400, "Signature duration")
	flag.IntVar(&expirationParam, "expiration", 0, "Explicit expiration (overrides duration if non-zero)")
	flag.IntVar(&keyindexParam, "keyindex", 0, "Key Index")
	flag.StringVar(&urlParam, "url", "", "Base CDN URL")
	flag.StringVar(&algoParam, "algorithm", SHA1, "SHA1 | MD5")
	flag.StringVar(&keyParam, "key", "", "Signing Key")
	flag.StringVar(&clientParam, "client", "", "Client IP")
	flag.BoolVar(&pathparamsParam, "pathparams", false, "Inline path parameter and signature")
	flag.BoolVar(&verboseParam, "verbose", false, "Verbose debug information")
}

func logArgs() {
	fmt.Println("=== Arguments ===")
	fmt.Println("parts:      " + usepartsParam)
	fmt.Println("duration:   " + strconv.Itoa(durationParam))
	fmt.Println("keyindex:   " + strconv.Itoa(keyindexParam))
	fmt.Println("url:        " + urlParam)
	fmt.Println("algo:       " + algoParam)
	fmt.Println("algoNum:    " + strconv.Itoa(algoLookup[algoParam]))
	fmt.Println("key:        " + keyParam)
	fmt.Println("client:     " + clientParam)
	fmt.Println("pathparams: " + strconv.FormatBool(pathparamsParam))
	fmt.Println("================\n")
}

func processURL(url string, useparts string, pathparams bool) (sigBuf *bytes.Buffer, pathPrefix string, file string, query string, err error) {
	if !httpSchemeRegex.MatchString(url) {
		err = errors.New("URL did not start with http:// or https://")
	} else {

		queryAndPath := strings.SplitN(url, "?", 2)
		if len(queryAndPath) > 1 {
			query = queryAndPath[1]
		} else {
			query = ""
		}

		pathParts := strings.Split(queryAndPath[0], "/")
		pathParts = pathParts[2:]
		pathChunks := len(pathParts)
		// substring up to the last '/'
		pathPrefix = queryAndPath[0][:strings.LastIndex(queryAndPath[0], "/")+1]
		file = pathParts[pathChunks-1]
		usepartsBytes := []byte(useparts)
		var signatureBuffer bytes.Buffer
		for idx, part := range pathParts {
			partsLen := len(usepartsBytes)
			lastPart := usepartsBytes[partsLen-1]
			// skipping the file if using pathparams (undocumented behavior raised wih RyanD)
			if !(pathparams && idx >= pathChunks-1) && ((lastPart == '1' && idx >= partsLen) || (idx < partsLen && usepartsBytes[idx] == '1')) {
				signatureBuffer.WriteString(part)
				signatureBuffer.WriteString("/")
			}
		}
		// chop off the trailing slash
		signatureBuffer.Truncate(signatureBuffer.Len() - 1)
		sigBuf = &signatureBuffer
	}
	return
}

func buildPathSignatureSource(signatureBuffer *bytes.Buffer, client string, expiration int, algo int, keyindex int, useparts string, query string) (signingStr string) {

	if clientParam != "" {
		signingStr = ";" + fmt.Sprintf(clientPathFormat, client, expiration, algo, keyindex, useparts)
	} else {
		signingStr = ";" + fmt.Sprintf(pathSignatureFormat, expiration, algo, keyindex, useparts)
	}

	signatureBuffer.WriteString(signingStr)
	return
}

func buildQuerySignatureSource(signatureBuffer *bytes.Buffer, client string, expiration int, algo int, keyindex int, useparts string, query string) (signingStr string) {
	if query != "" {
		query = query + "&"
	}
	if clientParam != "" {
		signingStr = ("?" + query + fmt.Sprintf(clientQueryFormat, client, expiration, algo, keyindex, useparts))
	} else {
		signingStr = ("?" + query + fmt.Sprintf(queryParamSignatureFormat, expiration, algo, keyindex, useparts))

	}

	signatureBuffer.WriteString(signingStr)
	return
}

func sign(sigSrc []byte, key string, algo string) (string, error) {

	var sigHmac hash.Hash
	if algo == SHA1 {
		sigHmac = hmac.New(sha1.New, []byte(key))
	} else {
		sigHmac = hmac.New(md5.New, []byte(key))
	}
	_, err := sigHmac.Write(sigSrc)
	if nil == err {

		signature := sigHmac.Sum(make([]byte, 0, sigHmac.Size()))

		return hex.EncodeToString(signature), nil

	}
	return "", err

}

func main() {
	flag.Parse()
	if "" == urlParam || "" == keyParam {
		fmt.Fprintln(os.Stderr, "URL and Key are required parameters")
		flag.Usage()
	} else if 0 == algoLookup[algoParam] {
		fmt.Fprintln(os.Stderr, "Unknown algorithm: "+algoParam)
		flag.Usage()
	} else {
		if verboseParam {
			logArgs()
		}

		// expiration in seconds since 1970
		expiration := expirationParam
		//if zero, then use duration
		if expiration == 0 {
			expiration = int((time.Now().Add(time.Duration(durationParam) * time.Second).Unix()))
		}
		signatureBuffer, pathPrefix, file, query, err := processURL(urlParam, usepartsParam, pathparamsParam)
		if nil == err {
			// just appending the various signing parameters to the base URL signature buffer
			var signatureStr string
			if pathparamsParam {
				signatureStr = buildPathSignatureSource(signatureBuffer, clientParam, expiration, algoLookup[algoParam], keyindexParam, usepartsParam, query)
			} else {
				signatureStr = buildQuerySignatureSource(signatureBuffer, clientParam, expiration, algoLookup[algoParam], keyindexParam, usepartsParam, query)
			}

			sigBytes := signatureBuffer.Bytes()
			if verboseParam {
				fmt.Println("Signature String: " + string(sigBytes))
			}
			// apply the hmac to the signature buffer using the specified key and algorithm
			signedSig, err := sign(sigBytes, keyParam, algoParam)

			if nil == err {
				if verboseParam {
					fmt.Println("Signature: " + signedSig)
				}
				if pathparamsParam == false {
					fmt.Print(pathPrefix, file, signatureStr, signedSig)
				} else {
					if query == "" {
						fmt.Print(pathPrefix, base64.URLEncoding.EncodeToString([]byte(signatureStr+signedSig)), "/", file)

					} else {
						fmt.Print(pathPrefix, base64.URLEncoding.EncodeToString([]byte(signatureStr+signedSig)), "/", file, "?", query)
					}
				}
			} else {
				log.Fatal(err)
			}
		}
	}
}
