var express = require('express'),
    http = require('http'),
    fs = require('fs'),
    morgan = require('morgan'),
    errorhandler = require('errorhandler'),
    modRewrite = require('connect-modrewrite'),
    timeout = require('connect-timeout');

var config;

try {
    config = require('/etc/trafficops/conf/config');
}
catch(e) {
    config = require('../conf/config');
}

var logStream = fs.createWriteStream(config.log.stream, { flags: 'a' });

var app = express();

// proxy api calls to the api.base_url
app.use(modRewrite([
        '^/api/(.*?)\\?(.*)$ ' + config.api.base_url + '/api/$1?$2&api_key=' + config.api.key + ' [P]', // match /api/{version}/foos?active=true and replace with api.base_url/api/{version}/foos?active=true&api_key=api.key
        '^/api/(.*)$ ' + config.api.base_url + '/api/$1?api_key=' + config.api.key + ' [P]' // match /api/{version}/foos and replace with api.base_url/api/{version}/foos?api_key=api.key
]));
app.use(express.static(config.files.static));
app.use(morgan('combined', {
      stream: logStream,
      skip: function (req, res) { return res.statusCode < 400 }
}));
app.use(errorhandler());
app.use(timeout(config.timeout));

if (app.get('env') === 'dev') {
    app.use(require('connect-livereload')({
        port: 35728,
        excludeList: ['.woff', '.flv']
    }));
} else {
    app.set('env', "production");
}

// HTTP Server for redirection
var httpServer = http.createServer(app);
httpServer.listen(config.port);
