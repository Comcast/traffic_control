// Copyright 2015 Comcast Cable Communications Management, LLC

// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at

// http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

package main

import (
	"./outputFormatter"
	"./sqlParser"
	"./urlParser"
	"encoding/json"
	"flag"
	"fmt"
	"io/ioutil"
	"net"
	"net/http"
	"os"
	"strings"
)

var (
	addr     = flag.Bool("addr", false, "find open address and print to final-port.txt")
	username = os.Args[1]
	password = os.Args[2]
	database = os.Args[3]

	//initializing the database connects and writes a column type map
	//(see sqlParser for more details)
	db = sqlParser.InitializeDatabase(username, password, database)
)

func requestHandler(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Access-Control-Allow-Origin", "*")
	path := strings.Split(r.URL.Path[1:], "/")

	var resp interface{}
	if len(path) > 1 && path[1] != "" {
		fmt.Println("GET FROM " + path[1])
		resp = sqlParser.GetColumnNames(path[1])
		fmt.Println("RESPONSE:")
		fmt.Println(resp)
	} else {
		resp = sqlParser.GetTableNames()
	}
	enc := json.NewEncoder(w)
	enc.Encode(resp)
}

//handles all calls to the API
func apiHandler(w http.ResponseWriter, r *http.Request) {

	w.Header().Set("Access-Control-Allow-Origin", "*")
	w.Header().Set("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE")
	w.Header().Set("Access-Control-Allow-Headers", "Origin, X-Requested-With, Content-Type")
	//url of type "/table?parameterA=valueA&parameterB=valueB/id
	path := r.URL.Path[1:]
	if r.URL.RawQuery != "" {
		path += "?" + r.URL.RawQuery
	}

	request := urlParser.ParseURL(path)

	//note: tableName could also refer to a view
	tableName := request.TableName
	tableParameters := request.Parameters

	if r.Method == "POST" {
		bodyStr, _ := ioutil.ReadAll(r.Body)
		tableName = sqlParser.Post(tableName, bodyStr)
	} else if r.Method == "DELETE" {
		sqlParser.Delete(tableName, tableParameters)
		tableParameters = tableParameters[:0]
	} else if r.Method == "PUT" {
		bodyStr, _ := ioutil.ReadAll(r.Body)
		sqlParser.Put(tableName, tableParameters, bodyStr)
		tableParameters = tableParameters[:0]
	}

	//GETS the request
	if tableName != "" {
		rows := sqlParser.Get(tableName, tableParameters)
		resp := outputFormatter.MakeWrapper(rows)

		//encoder writes the resultant "Response" struct (see outputFormatter) to writer
		enc := json.NewEncoder(w)
		enc.Encode(resp)
	}
}

func main() {
	fmt.Println("Starting server.")
	flag.Parse()

	http.HandleFunc("/api/", apiHandler)
	http.HandleFunc("/request/", requestHandler)

	if *addr {
		//runs on home
		l, err := net.Listen("tcp", "127.0.0.1:0")
		if err != nil {
			panic(err)
		}
		err = ioutil.WriteFile("final-port.txt", []byte(l.Addr().String()), 0644)
		if err != nil {
			panic(err)
		}
		s := &http.Server{}
		s.Serve(l)
		return
	}

	http.ListenAndServe(":8080", nil)
}
