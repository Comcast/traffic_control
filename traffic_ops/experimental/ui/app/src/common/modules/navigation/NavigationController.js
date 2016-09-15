var NavigationController = function($scope, $log, $state, $location, $timeout, $uibModal, authService, trafficOpsService, userModel) {

    $scope.userLoaded = userModel.loaded;

    $scope.user = userModel.user;

    $scope.monitor = {
        isOpen: false,
        isDisabled: false
    };

    $scope.settings = {
        isOpen: false,
        isDisabled: false
    };


    $scope.navigateToPath = function(path) {
        $location.url(path);
    };

    $scope.isState = function(state) {
        return $state.current.name.indexOf(state) !== -1;
    };

    $scope.logout = function() {
        authService.logout();
    };

    $scope.releaseVersion = function() {
        trafficOpsService.getReleaseVersionInfo()
            .then(function(result) {
                $uibModal.open({
                    templateUrl: 'common/modules/release/release.tpl.html',
                    controller: 'ReleaseController',
                    size: 'sm',
                    resolve: {
                        params: function () {
                            return result;
                        }
                    }
                });
            });
    };

    var explodeMenu = function() {
        var isBig = $('body').hasClass('nav-md');

        $('.side-menu-category ul').slideUp();
        $('.side-menu-category').removeClass('active');
        $('.side-menu-category').removeClass('active-sm');

        if (isBig) {
            $('.current-page').parent('ul').slideDown().parent().addClass('active');
        } else {
            $('.current-page').closest('.side-menu-category').addClass('active-sm');
        }
    };

    var registerMenuHandlers = function() {
        $('.side-menu-category').click(function() {
            var isBig = $('body').hasClass('nav-md');
            if (isBig) {
                if ($(this).is('.active')) {
                    $(this).removeClass('active');
                    $('ul', this).slideUp();
                    $(this).removeClass('nv');
                    $(this).addClass('vn');
                } else {
                    $('#sidebar-menu li ul').slideUp();
                    $(this).removeClass('vn');
                    $(this).addClass('nv');
                    $('ul', this).slideDown();
                    $('#sidebar-menu li').removeClass('active');
                    $(this).addClass('active');
                }
            } else {
                $('#sidebar-menu li ul').slideUp();
                if ($(this).is('.active-sm')) {
                    $(this).removeClass('active-sm');
                    $(this).removeClass('nv');
                    $(this).addClass('vn');
                } else {
                    $(this).removeClass('vn');
                    $(this).addClass('nv');
                    $('ul', this).slideDown();
                    $('#sidebar-menu li').removeClass('active-sm');
                    $(this).addClass('active-sm');
                }
            }
        });

        $('.side-menu-category-item').click(function(event) {
            event.stopPropagation();
            var isBig = $('body').hasClass('nav-md');
            if (!isBig) {
                // close the menu when child is clicked only in small mode
                $(event.currentTarget).closest('.child_menu').slideUp();
            }
        });
    };

    $scope.$on('HeaderController::navExpanded', function() {
        explodeMenu();
    });

    var init = function() {
        $timeout(function() {
            explodeMenu();
            registerMenuHandlers();
        }, 100);
    };
    init();

};

NavigationController.$inject = ['$scope', '$log', '$state', '$location', '$timeout', '$uibModal', 'authService', 'trafficOpsService', 'userModel'];
module.exports = NavigationController;
