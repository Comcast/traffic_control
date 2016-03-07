module.exports = angular.module('trafficOps.private.administer.users.edit', [])
    .config(function($stateProvider, $urlRouterProvider) {
        $stateProvider
            .state('trafficOps.private.administer.users.edit', {
                url: '/{userId}',
                views: {
                    administerContent: {
                        templateUrl: 'common/modules/form/user/form.user.tpl.html',
                        controller: 'FormUserController',
                        resolve: {
                            user: function($stateParams, userService) {
                                return userService.getUser($stateParams.userId);
                            }
                        }
                    }
                }
            })
        ;
        $urlRouterProvider.otherwise('/');
    });
