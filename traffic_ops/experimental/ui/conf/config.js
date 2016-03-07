module.exports = {
    timeout: '60s',
    port: 8080,
    proxyPort: 8009,
    api: {
        base_url: 'http://localhost:3000',
        key: ''
    },
    files: {
        static: './app/dist/public/'
    },
    log: {
        stream: './server/log/access.log'
    }
};
