angular.module( 'app', [ 'ngRoute', 'ngTouch', 'ngAnimate', 'ngSanitize',
                         'ui.bootstrap',
                         'templates-app', 'templates-common', 'Model', 'i18n'
                         'app.utils', 'app.home',
                         'CacheView', 'Service', 'Popup', 'Scroll', 'Widget'
])
  .config( ($routeProvider, $compileProvider, $httpProvider) ->
#    // Needed for phonegap routing
    $compileProvider.aHrefSanitizationWhitelist(/^\s*(https?|ftp|mailto|file|tel):/)
    #$locationProvider.html5Mode(true)
    $httpProvider.defaults.xsrfHeaderName = 'X-CSRFToken'
    $httpProvider.defaults.xsrfCookieName = 'csrftoken'

    if window.SERVER
      $httpProvider.defaults.withCredentials = true
      $httpProvider.defaults.headers.common['X-CSRFToken'] = localStorage.csrf

    $routeProvider.when( '/',
      name: 'home'
      controller: 'HomeCtrl'
      templateUrl: 'home/home.tpl.html'
      cache: yes
    )
    .otherwise(
      redirectTo: '/'
    )
  )
  .run( ($location, $document, $rootScope, $timeout)->
    # simulate html5Mode
    if !location.hash
      $location.path(location.pathname)
  )
  .controller('AppCtrl', ($scope, Single) ->
    $scope.meta = Single('meta').get()
  )





