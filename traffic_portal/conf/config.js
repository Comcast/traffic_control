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

// see config-template.js for comments
module.exports = {
    timeout: '120s',
    useSSL: false,
    port: 8080,
    sslPort: 8443,
    proxyPort: 8009,
    ssl: {
        key:    '/path/to/ssl.key',
        cert:   '/path/to/ssl.crt',
        ca:     [
            '/path/to/ssl-bundle.crt'
        ]
    },
    api: {
        base_url: 'http://localhost:3000/api/',
        key: ''
    },
    files: {
        static: './app/dist/public/'
    },
    log: {
        stream: './server/log/access.log'
    },
    reject_unauthorized: 0 // 0 if using self-signed certs, 1 if trusted certs
};
