package environment

import (
	"encoding/json"
	"io/ioutil"
)

// Service contains the location and authentication data of a Traffic Control service.
type Service struct {
	URI      string `json:"uri"`
	User     string `json:"user"`
	Password string `json:"pass"`
}

// Environment contains the location and authentiation data of all Traffic Control services to be tested.
type Environment struct {
	TrafficOps Service `json:"traffic_ops"`
}

// DefaultFile is the default name for the Environment config file.
const DefaultFile = "environment.json"

// DefaultPath is the default file name and path, for tests which are in `./ui/*/` or `./api/*/`.
// Tests more or less deeply nested will need to use their own path when calling `Get`.
const DefaultPath = "../../" + DefaultFile

// Get returns the Environment object, loaded from the given file.
// You can use environment.DefaultPath if your test is in the usual test/api/app or test/ui/app directory.
// You should always use DefaultPath or DefaultFile, and should always be passing the path to `infrastructure/test/environment.json`.
func Get(file string) (Environment, error) {
	f, err := ioutil.ReadFile(file)
	if err != nil {
		return Environment{}, err
	}
	var env Environment
	if err := json.Unmarshal(f, &env); err != nil {
		return Environment{}, err
	}
	return env, nil
}
