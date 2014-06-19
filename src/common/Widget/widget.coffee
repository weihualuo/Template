

angular.module( 'Widget', [])
  .directive( 'fileSelect', ->
    restrict: 'E'
    replace: true
    scope:
      src: "@"
      file: "="
      name: '@'
      placeholder: '@'
    template: '<div>
                <div class="image-preview">
                  <div ng-hide="src || reading">{{placeholder}}</div>
                  <div ng-show="reading" class="image-loading"><i class="icon ion-load-a loading-rotate"></i></div>
                  <img ng-hide="reading" ng-src="{{src}}">
                </div>
                <input name="{{name}}" type="file"/>
               </div>'

    link: (scope, element) ->

      originSrc = null

      $input = element.find('input')
      $input.on 'change', (e)->

        #Save the origin src
        originSrc ?= scope.src
        file = e.target.files[0]
        if file and file.type.indexOf('image') >= 0

          reader = new FileReader()
          reader.onload = (e)->
            scope.reading = no
            scope.file = file
            scope.src = e.target.result
            scope.$apply()
          #read data take a while on mp
          reader.readAsDataURL(file)
          scope.reading = yes
          scope.$apply()
        # Set to origin src in case of no selection
#        else
#          scope.src = originSrc
#          scope.$apply()


  )
  .directive('inputFile', ->
    restrict: 'E'
    replace: true
    transclude: true
    scope:
      onSelect: '&'
    template: '<label>'+
                '<div ng-transclude></div>'+
                '<input type="file">'+
              '</label>'
    link: (scope, element, attr) ->
      $input = element.find('input')
      $input.attr('multiple', true) if attr.multiple?
      $input.on 'change', (e)->
        for file in e.target.files
          if file and file.type.indexOf('image') >= 0
            scope.onSelect file:file
        scope.$apply()

  )
  .directive('sidePane', (Swipe, PrefixedStyle, PrefixedEvent)->
    restrict: 'E'
    replace: true
    transclude: true
    template:  """
               <div class="side-pane" ng-transclude></div>
               """
    link: (scope, element, attr) ->

      x = 0
      snaping = false
      pane = element[0]

      if attr.closeOnResize?
        onResize = ->
          setAnimate('none')
          scope.$emit 'content.closed'
          window.removeEventListener 'resize', onResize
        window.addEventListener "resize", onResize

      PrefixedEvent element, "TransitionEnd", ->
        if snaping
          snaping = false
          resetState()

      updatePosition = (offset)->
        x = offset
        if offset
          PrefixedStyle pane, 'transform', "translate3d(#{offset}px, 0, 0)"
        else
          PrefixedStyle pane, 'transform', null

      setAnimate = (prop)->
        PrefixedStyle pane, 'transition', prop

      resetState = ()->
        if x is 0
          setAnimate(null)
        else
          setAnimate('none')
          scope.$emit 'content.closed'

      options =
        direction: attr.position
        onStart: ->
          setAnimate('none')
        onMove: (offset)->
          updatePosition offset
        onEnd: (offset, ratio)->
          if ratio
            snaping = true
            time = Math.round(ratio * 300)
            setAnimate "all #{time}ms ease-in"
            updatePosition offset
          else
            updatePosition offset
            resetState()

      element.ready ->
        Swipe element, options

  )
  .directive('modal', ()->
    restrict: 'E'
    link:(scope, element)->
      element.addClass 'modal-win'
      if window.innerWidth < 400
        element.css
          width: '100%'
          height: '100%'
          'border-radius': '0'
  )
  .directive('navable', ($compile, $animate, $http, $templateCache)->

    link:(scope, element, attr)->

      stack = []
      container = angular.element "<div style='position: absolute; width:100%'></div>"
      if ani = attr.animation
        container.addClass(ani)

      getContent = (url)->
        template = $templateCache.get(url)
        content = container.clone().html(template)
        $compile(content)(scope)

      current = getContent attr.navable
      element.empty()
      element.append(current)
      element.ready ->
        height = current[0].offsetHeight
        #At present: only set the height to first view,
        #the other view maybe hide if hight than first view
        #In that case, to update the diretive
        #height maybe set already
        if not element[0].style.height
          element.css
            height: height+'px'

      scope.navCtrl =
        go: (url)->
          child = getContent url
          stack.push current
          $animate.addClass(current, 'stacked')
          $animate.enter(child, element)
          current = child
          null
        back: ->
          if stack.length
            $animate.leave(current)
            current = stack.pop()
            $animate.removeClass(current, 'stacked')
          null
  )
  .directive('loading', ($parse)->
    link: (scope, element, attr)->

      indicator = angular.element '<div class="fill box-center"><i class="icon icon-large ion-loading-d"></i></div>'
      loading = false
      flag = $parse(attr.loading)
      # Display loading indicator when true
      scope.$watch flag, (value)->

        if value and not loading
          element.append indicator
          loading = yes
          #value if a promise objects
          value.then?(->
            indicator.remove()
            loading = no
          )

        if not value and loading
          indicator.remove()
          loading = no
  )
  .directive('textWatch', ($parse)->
    link: (scope, element, attr)->

      icons =
        $loading: '<i class="icon icon-large ion-loading-d"></i>'

      flag = $parse(attr.textWatch)
      config = scope.$eval(attr.textConfig)
      scope.$watch flag, (value)->
        content = config[value] or ''
        content = icons[content] or content
        element.html(content)

  )
  .directive('subView', ($templateCache, $controller, $compile)->
    restrict: 'E'
    terminal: true
    priority: 400
    controller: angular.noop
    transclude: 'element'
    link: (scope, element, attr, ctrl)->

      childScope = null
      update = (config)->
        console.log 'update', config
        if not config then return
        element.empty()
        childScope.$destroy() if childScope
        template = $templateCache.get(config.url)
        element.html(template)
        childScope = scope.$new()
        childScope.$controller = $controller(config.controller, $scope:childScope)
        $compile(element.contents())(childScope)

      scope.$watch(attr.subView, update)

  )
  .directive('draggable', (PrefixedStyle)->
    link: (scope, element, attr)->

      `
        function getCoordinates(event) {
          var touches = event.touches && event.touches.length ? event.touches : [event];
          var e = (event.changedTouches && event.changedTouches[0]) ||
              (event.originalEvent && event.originalEvent.changedTouches &&
                  event.originalEvent.changedTouches[0]) ||
              touches[0].originalEvent || touches[0];

          return {
            x: e.clientX,
            y: e.clientY
          };
        }
      `

      exp = attr.draggable
      startX = startY = currentX = currentY = 0

      updatePosition = (x, y)->
        currentX = x
        currentY = y
        if x or y
          PrefixedStyle element[0], 'transform', "translate3d(#{x}px, #{y}px, 0)"
        else
          PrefixedStyle element[0], 'transform', null

      onMove = (event)->
        event.preventDefault()
        event.stopPropagation()
        cords = getCoordinates(event)
        y = cords.y - startY
        x = cords.x - startX
        #console.log x, y, startX, startY
        updatePosition(x, y)

      onEnd = (event)->
        event.preventDefault()
        event.stopPropagation()
        element.off 'touchmove mousemove', onMove
        element.off 'touchend touchcancel mouseup', onEnd
        #updatePosition(0, 0)
        #console.log 'end'

      element.on 'touchstart mousedown', (event)->
        if scope.$eval(exp)
          event.preventDefault()
          event.stopPropagation()
          cords = getCoordinates(event)
          startX = cords.x - currentX
          startY = cords.y - currentY
          element.on 'touchmove mousemove', onMove
          element.on 'touchend touchcancel mouseup', onEnd

  )
  .directive( 'orderList', (PrefixedStyle, $document)->
    controller: ->
      this
    link: (scope, element, attr, ctrl)->

      `
        function getCoordinates(event) {
          var touches = event.touches && event.touches.length ? event.touches : [event];
          var e = (event.changedTouches && event.changedTouches[0]) ||
              (event.originalEvent && event.originalEvent.changedTouches &&
                  event.originalEvent.changedTouches[0]) ||
              touches[0].originalEvent || touches[0];

          return {
            x: e.clientX,
            y: e.clientY
          };
        }
      `
      clone = current = null
      startX = width = lastStep = left = diffx = 0

      swapRight = ()->
        objects = scope[attr.orderList]
        index = current.scope().$index
        if index + 1 < objects.length
          scope[attr.onSwap]?(index, index+1)
          scope.$digest()
          diffx = current[0].offsetLeft - left
        #console.log 'swap right', index
        #console.log left, current[0].offsetLeft

      swapLeft = ()->
        index = current.scope().$index
        if index > 0
          scope[attr.onSwap]?(index-1, index)
          scope.$digest()
          diffx = current[0].offsetLeft - left
        #console.log 'swap left', index
        #console.log left, current[0].offsetLeft

      updatePosition = (x)->
        if x
          PrefixedStyle clone[0], 'transform', "translate3d(#{x}px, 0, 0)"
        else
          PrefixedStyle clone[0], 'transform', null

      onMove = (event)->
        event.preventDefault()
        event.stopPropagation()
        cords = getCoordinates(event)
        x = cords.x - startX
        updatePosition(x)
        if x - lastStep > 10 and x - diffx > width/2 + 20
          lastStep = x
          swapRight()
        else if x - lastStep < -10 and x - diffx < -width/2 - 20
          lastStep = x
          swapLeft()

      onEnd = (event)->
        event.preventDefault()
        event.stopPropagation()
        $document.off 'touchmove mousemove', onMove
        $document.off 'touchend touchcancel mouseup', onEnd
        updatePosition(0)
        current.css visibility: null
        clone.remove()
        clone = current = null

      ctrl.onStart = (child, event)->
        current = child
        cords = getCoordinates(event)
        startX = cords.x
        clone = child.clone()
        width = child[0].offsetWidth
        left = child[0].offsetLeft
        lastStep = diffx = 0
        clone.css
          'position': 'absolute'
          'padding-bottom': '20px'
          'left': left+'px'
        element.append clone
        child.css visibility: 'hidden'
        $document.on 'touchmove mousemove', onMove
        $document.on 'touchend touchcancel mouseup', onEnd
  )
  .directive('orderable', ()->
    require: '^orderList'
    link: (scope, element, attr, ctrl)->
      exp = attr.orderable
      element.on 'touchstart mousedown', (event)->
        if scope.$eval(exp)
          event.preventDefault()
          event.stopPropagation()
          ctrl.onStart(element, event)
  )





