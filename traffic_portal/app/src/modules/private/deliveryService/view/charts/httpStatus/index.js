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

module.exports = angular.module('trafficPortal.deliveryService.view.chart.httpStatus', [])
    .config(function($stateProvider, $urlRouterProvider) {
        $stateProvider
            .state('trafficPortal.private.deliveryService.view.chart.httpStatus', {
                url: '/http-status-by-class',
                views: {
                    chartDatesContent: {
                        templateUrl: 'common/modules/chart/dates/chart.dates.tpl.html',
                        controller: 'ChartDatesController',
                        resolve: {
                            customLabel: function() {
                                return 'Data';
                            },
                            showAutoRefreshBtn: function() {
                                return true;
                            }
                        }
                    },
                    chartContent: {
                        templateUrl: 'common/modules/chart/httpStatus/chart.httpStatus.tpl.html',
                        controller: 'ChartHttpStatusController',
                        resolve: {
                            entity: function(user, $stateParams, deliveryServicesModel) {
                                return deliveryServicesModel.getDeliveryService($stateParams.deliveryServiceId);
                            }
                        }
                    }
                }
            });
        $urlRouterProvider.otherwise('/');
    });
