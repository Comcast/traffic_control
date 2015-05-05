Traffic Stats
-------------

Traffic Stats is a utility written in Go that mines metrics from Traffic Monitor’s JSON APIs and stores the data in InfluxDb. This system’s purpose is to land data in InfluxDb for other tools to consume.

Once in InfluxDb, the data can be extracted and prepared to be sent elsewhere for long term storage. Any number of Traffic Stats instances may run on a given CDN to collect metrics from Traffic Monitor, however, redundancy and integration with a long term metrics storage system is implementation dependent. Traffic Stats does not influence overall CDN operation, but is required in order to display charts in Traffic Operations.
