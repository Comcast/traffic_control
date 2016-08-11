// enum contains enumerations and strongly typed names.
// The names are an experiment with strong typing of string types. The primary goal is to make code more self-documenting, especially map keys. If peole don't like it, we can get rid of it.
package enum

import (
	"strings"
)

type TrafficMonitorName string

type CacheName string

type CacheGroupName string

// Current JSON endpoint:
type DeliveryServiceName string

// TODO move and rename more generically
type CacheType string

const CacheTypeEdge = CacheType("EDGE")
const CacheTypeMid = CacheType("MID")
const CacheTypeInvalid = CacheType("INVALID")

func (t CacheType) String() string {
	switch t {
	case CacheTypeEdge:
		return "EDGE"
	case CacheTypeMid:
		return "MID"
	default:
		return "INVALID"
	}
}

func CacheTypeFromString(s string) CacheType {
	s = strings.ToLower(s)
	switch s {
	case "edge":
		return CacheTypeEdge
	case "mid":
		return CacheTypeMid
	default:
		return CacheTypeInvalid
	}
}

// DSType is the Delivery Service type. HTTP, DNS, etc.
type DSType int64

const (
	DSTypeHTTP = iota
	DSTypeDNS
	DSTypeInvalid
)

func (t DSType) String() string {
	switch t {
	case DSTypeHTTP:
		return "HTTP"
	case DSTypeDNS:
		return "DNS"
	default:
		return "INVALID"
	}
}

func DSTypeFromString(s string) DSType {
	s = strings.ToLower(s)
	switch s {
	case "http":
		return DSTypeHTTP
	case "dns":
		return DSTypeDNS
	default:
		return DSTypeInvalid
	}
}
