angular.module('app.home', ['restangular'])

  .controller( 'ListCtrl', ($scope, name, $timeout, $q, $routeParams, $location, Restangular, Many) ->

    ctrl = this
    ctrl.auto = on
    collection = objects = null

    @reload = (search=$location.search(), sub=$routeParams)->

      #console.log "reload", name, search, sub

      if angular.isObject(sub) and angular.isUndefined(sub.parent)
        $scope.$emit('filter.update', name, search)
      # Make sure there is a reflow of empty
      # So that $last in ng-repeat works
      $scope.objects = []
      #search maybe a promise object
      $scope.promise = $q.when(search).then (search)->
        $scope.collection = collection = Many(name, sub)
        objects = collection.list(search)
        #Use timeout to force a reflow of empty objects
        objects.$promise.then -> $timeout ->
          $scope.objects = objects
          $scope.haveMore = objects.meta.more
          $scope.totalCount = objects.length + $scope.haveMore
          $scope.$broadcast('scroll.reload')

      $scope.promise


    #Load more objects
    @more = ->
      if not $scope.haveMore
        $scope.$broadcast('scroll.moreComplete')
        console.log "no more"
        return
      promise = collection.more()
      if promise
        $scope.loadingMore = true
        promise.then( ->
          $scope.haveMore = objects.meta.more
        ).finally ->
          $scope.loadingMore = false
          $scope.$broadcast('scroll.moreComplete')

    #Refresh the list
    @refresh = ->
      collection.refresh().finally ->
        $scope.$broadcast('scroll.refreshComplete')

    $scope.$on '$scopeUpdate', -> ctrl.reload() if ctrl.auto
    $scope.$on 'scroll.refreshStart', ctrl.refresh
    $scope.$on 'scroll.moreStart', ctrl.more

    this
  )
  .controller( 'HomeCtrl', ($scope, $controller, $timeout, When, Nav) ->

    $scope.listCtrl =  $controller('ListCtrl', {$scope:$scope, name: 'data'})

    $scope.onMore = ->
      $scope.listCtrl.more() if not $scope.loadingMore

    $scope.moreText =
      false: _U('More')
      true: _U('Loading')

    $scope.date = $scope.maxDate = new Date()
    $scope.onDateOpen = ($event)->
      $event.preventDefault()
      $event.stopPropagation()
      $timeout -> $scope.dateOpened = true

    updateDataSet = ->
      if $scope.objects.$resolved
        if $scope.product?.id
          $scope.dataset = _.filter($scope.objects, product:$scope.product.id)
        else
          $scope.dataset = $scope.objects
      else
        # in case get a empty list
        $scope.dataset = []

    allProduct = id:0, title: _U('All')
    When($scope.meta).then (meta)->
      $scope.user = meta.user
      $scope.customer = meta.user.company?[0]
      $scope.products = meta.products
      $scope.products.unshift allProduct
      $scope.product = $scope.products[0]
      $scope.$watch 'product', updateDataSet

    $scope.$watchCollection 'objects', updateDataSet

    $scope.$watch 'date', (date, old)->
      console.log date
      if date isnt old
        param =
          date: [date.getFullYear(), date.getMonth()+1, date.getDate()].join('-')
        console.log param
        Nav.go({name:'home', search:param})

    $scope.productName = (id)->
      p = _.find($scope.products, id:id)
      p?.title


  )



