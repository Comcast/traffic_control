module.exports = angular.module('trafficOps.private.configure.locations.list', [])
    .config(function($stateProvider, $urlRouterProvider) {
        $stateProvider
            .state('trafficOps.private.configure.locations.list', {
                url: '',
                views: {
                    locationsContent: {
                        templateUrl: 'common/modules/table/locations/table.locations.tpl.html',
                        controller: 'TableLocationsController',
                        resolve: {
                            locations: function() {
                                return [ { id: 'location-1' } ];
                            }
                        }
                    }
                }
            })
        ;
        $urlRouterProvider.otherwise('/');
    });
