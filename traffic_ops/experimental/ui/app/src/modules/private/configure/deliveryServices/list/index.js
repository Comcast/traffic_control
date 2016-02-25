module.exports = angular.module('trafficOps.private.configure.deliveryServices.list', [])
    .config(function($stateProvider, $urlRouterProvider) {
        $stateProvider
            .state('trafficOps.private.configure.deliveryServices.list', {
                url: '',
                views: {
                    deliveryServicesContent: {
                        templateUrl: 'common/modules/table/deliveryServices/table.deliveryServices.tpl.html',
                        controller: 'TableDeliveryServicesController',
                        resolve: {
                            deliveryServices: function(user, deliveryServiceService) {
                                return deliveryServiceService.getDeliveryServices(false);
                            }
                        }
                    }
                }
            })
        ;
        $urlRouterProvider.otherwise('/');
    });
