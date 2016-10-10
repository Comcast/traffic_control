var ServerService = function(Restangular, messageModel) {

    this.getServers = function() {
        return Restangular.all('servers').getList();
    };

    this.getServer = function(id) {
        return Restangular.one("servers", id).get();
    };

    this.createServer = function(server) {
        return Restangular.service('servers').post(server)
            .then(
            function() {
                messageModel.setMessages([ { level: 'success', text: 'Server created' } ], true);
            },
            function() {
                messageModel.setMessages([ { level: 'error', text: 'Server create failed' } ], false);
            }
        );
    };

    this.updateServer = function(server) {
        return server.put()
            .then(
                function() {
                    messageModel.setMessages([ { level: 'success', text: 'Server updated' } ], false);
                },
                function() {
                    messageModel.setMessages([ { level: 'error', text: 'Server update failed' } ], false);
                }
            );
    };

    this.deleteServer = function(id) {
        return Restangular.one("servers", id).remove()
            .then(
                function() {
                    messageModel.setMessages([ { level: 'success', text: 'Server deleted' } ], true);
                },
                function() {
                    messageModel.setMessages([ { level: 'error', text: 'Server delete failed' } ], false);
                }
            );
    };

};

ServerService.$inject = ['Restangular', 'messageModel'];
module.exports = ServerService;