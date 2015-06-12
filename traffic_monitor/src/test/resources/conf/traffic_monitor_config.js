{"traffic_monitor_config": {
  "tm.healthParams.polling.url": "http://${tmHostname}/health/${cdnName}",
  "hack.ttl": "30",
  "allow.config.edit": false,
  "tm.auth.url": "http://${tmHostname}/login",
  "tm.auth.username": "",
  "tm.auth.password": '',
  "health.polling.interval": "5000",
  "peers.polling.url": "http://${hostname}/publish/CrStates?raw",
  "cdnName": "cdnname",
  "health.event-count": "200",
  "health.timepad": "20",
  "tm.dataServer.polling.url": "http://${tmHostname}/dataserver/orderby/id",
  "tm.crConfig.json.polling.url": "http://${tmHostname}/CRConfig-Snapshots/${cdnName}/CRConfig.json",
  "tm.polling.interval": "10000",
  "tm.hostname": "traffic-ops.company.net"
}}
