angular.module( 'app', [ 'ngRoute', 'ngTouch', 'ngAnimate', 'ngSanitize',
                         'templates-app', 'templates-common', 'Model', 'MESSAGE'
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

    #prevent webkit drag
    $document.on 'touchmove', (e)->e.preventDefault()
    window.addEventListener 'resize', -> $timeout ->
      $rootScope.$broadcast('resize')
  )
  .controller('AppCtrl', ($scope) ->
  )





