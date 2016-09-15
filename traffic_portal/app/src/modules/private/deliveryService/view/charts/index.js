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

module.exports = angular.module('trafficPortal.deliveryService.view.chart', [])
    .controller('DeliveryServiceViewChartsController', require('./DeliveryServiceViewChartsController'))
    .config(function($stateProvider, $urlRouterProvider) {
        $stateProvider
            .state('trafficPortal.private.deliveryService.view.chart', {
                url: '/chart',
                abstract: true,
                views: {
                    deliveryServiceViewContent: {
                        templateUrl: 'modules/private/deliveryService/view/charts/deliveryService.view.charts.tpl.html',
                        controller: 'DeliveryServiceViewChartsController'
                    }
                }
            });
        $urlRouterProvider.otherwise('/');
    });
