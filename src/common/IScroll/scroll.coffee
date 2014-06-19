
angular.module( 'Scroll', [])

  .directive('zoomable', (PrefixedStyle, Popup)->
    (scope, element, attr)->

      render = (left, top, zoom)->
        #console.log "render", left, top. zoom
        Popup.alert "rennder #{zoom}"
        PrefixedStyle element[0], 'transform', "scale(#{zoom})"

      options =
        scrollingX: off
        scrollingY: off
        zooming: on
        el: element[0]
        callback: render

      scope.zoomView = zoomView = new ionic.views.Scroll(options)
      #Shoud reflow on element ready
      #Not everyone send a scroll.reload
      element.ready ->
        zoomView.resize()
  )
  .factory('Zoomable', (PrefixedStyle)->
    (el)->
      new EasyScroller(el, zooming:on)
  )
  .directive('scrollable', ($timeout)->
    (scope, element, attr)->

      scrollable = attr.scrollable
      complete = if attr.complete then (->scope.$eval(attr.complete)) else angular.noop
      options =
        scrollingX: scrollable is 'true' or scrollable is 'x'
        scrollingY: scrollable isnt 'x'
        paging: attr.paging?
        bouncing: not attr.paging?
        scrollingComplete: complete
        el: element[0]

      scope.scrollView = scrollView = new ionic.views.Scroll(options)
      #Shoud reflow on element ready
      #Not everyone send a scroll.reload
      element.ready ->
        scrollView.resize()

      # list reset
      scope.$on 'scroll.reload', ->
        $timeout (->scrollView.scrollTo(0, 0))

      # list reset or more item loaded
      scope.$on 'list.rendered', ->
        $timeout (->scrollView.resize())

      scrollView.getItemRect = (index)->
        item = element.children()[index]
        rect = item.getBoundingClientRect()
        x = 0
        if rect.left < 0
          x = rect.left
        else if rect.right > window.innerWidth
          x = rect.right - window.innerWidth
        y = 0
        if rect.top < 0
          y = rect.top
        else if rect.bottom > window.innerHeight
          y = rect.bottom - window.innerHeight
        @scrollBy(x, y)
        item.getBoundingClientRect()

  )
  .directive('refreshable', ($timeout, PrefixedStyle)->
    (scope, element, attr)->
      template = '<svg class="refresher"><circle cx="25" cy="25" r="15" fill="blue"/></svg>'
      raw = element[0]
      refresher = angular.element(template)
      raw.parentNode.insertBefore(refresher[0], raw)

      enableRefersh = false
      enableMore = false
      position = 0
      height = 50
      updatePosition = (pos)->
        if pos isnt null
          position = pos
          y = -((height-pos)/2).toFixed(2)
          ratio = (pos/height).toFixed(2)
          PrefixedStyle refresher[0], 'transform', "translate3d(0, #{y}px, 0) scale3d(#{ratio}, #{ratio}, 0)"
        else
          PrefixedStyle refresher[0], 'transform', null

      setAnimate = (prop)->
        PrefixedStyle refresher[0], 'animation', prop

      scroller = scope.scrollView
      element.on 'scroll', (e)->
        detail = (e.originalEvent || e).detail || {}
        top = detail.scrollTop
        if top >= 0
          if enableMore and top > scroller.getScrollMax().top > 0
            enableMore = false
            scope.$emit 'scroll.moreStart'

        else if enableRefersh
          if top >= -height
            updatePosition(-top)
          else if position != height
            updatePosition height
        null

      scroller.activatePullToRefresh height, (->), (->), ->
        if enableRefersh
          enableRefersh = false
          setAnimate('shrinking 0.5s linear 0 infinite alternate')
          scope.$emit 'scroll.refreshStart'

      #delay at least an animation duration
      scope.$on 'scroll.refreshComplete', ->
        $timeout (->
          scroller.finishPullToRefresh()
          setAnimate(null)
          scroller.resize()
          enableRefersh = true
        ), 1000

      scope.$on 'scroll.moreComplete', ()->

      scope.$on 'scroll.reload', ->
        enableRefersh = false
        enableMore = false

      #disable for a while or if no more item
      #browser rendering is not finished in fact
      #when loading more, if no item loaded, enableMore is off
      scope.$on 'list.rendered', ->
        $timeout (->
          enableRefersh = true
          enableMore = true
        ), 1000

      updatePosition(0)
  )
  .directive('dynamic', ($timeout)->
    (scope, element)->

      scope.dynamic = yes
      scroller = scope.scrollView
      n = 5
      start = end = lastTop =  0
      step = 200

      notify = (newStart, newEnd)->
        #add = remove = []
        children = element.find('li')
        length = children.length
        if newEnd > length then newEnd = length

        if newStart > start
          #remove = remove.concat [start..(newStart-1)]
          for i in [start..(newStart-1)]
            if i >= length then break
            #console.log "remove", i
            angular.element(children[i]).triggerHandler 'dynamic.remove'

        if newEnd < end
          #remove = remove.concat [newEnd..(end-1)]
          for i in [newEnd..(end-1)]
            if i >= length then break
            #console.log "remove", i
            angular.element(children[i]).triggerHandler 'dynamic.remove'

        if newStart < start
          #add = add.concat [newStart..(start-1)]
          for i in [newStart..(start-1)]
            if i >= length then break
            #console.log "add", i
            angular.element(children[i]).triggerHandler 'dynamic.add'

        if newEnd > end
          #add = add.concat [end..(newEnd-1)]
          for i in [end..(newEnd-1)]
            if i >= length then break
            #console.log "add", i
            angular.element(children[i]).triggerHandler 'dynamic.add'

        start = newStart
        end = newEnd
        #console.log "start #{start}, end #{end}"
#        children = element.children()
#        length = children.length
#        for i in remove
#          if i >= length then break
#          angular.element(children[i]).triggerHandler 'dynamic.remove'
#        for i in add
#          if i >= length then break
#          angular.element(children[i]).triggerHandler 'dynamic.add'

      update = ->
        item = element[0].firstElementChild

        if not item then return
        top = scroller.getValues().top
        itemHeight = item.offsetHeight
        containerHeight = element[0].parentNode.clientHeight
        numPerRow = Math.round element[0].clientWidth/item.offsetWidth

        #console.log "top: #{top}, itemHeight: #{itemHeight}, containerHeight: #{containerHeight}, numPerRow: #{numPerRow}"

        # row above fully invisible
        rowHide = Math.floor top/itemHeight
        if rowHide > n
          newStart = (rowHide-n)*numPerRow
        else
          newStart = 0

        # lastRow visible
        bottomRow = Math.ceil (top+containerHeight)/itemHeight
        newEnd = (bottomRow+n)*numPerRow

        #console.log "rowHide: #{rowHide}, bottomRow: #{bottomRow}, newStart is #{newStart}, newEnd is #{newEnd}"
        #console.log "Items keep: #{newEnd-newStart}, row: #{(newEnd-newStart)/numPerRow}"
        notify(newStart, newEnd)
        lastTop = top
        step =  itemHeight*3

      element.on 'scroll', (e)->
        detail = (e.originalEvent || e).detail || {}
        top = detail.scrollTop
        if Math.abs(top-lastTop) > step
          #console.log "onStep", top
          update()

      #list reset
      scope.$on 'scroll.reload', ->
        start = end = lastTop =  0

      scope.$on 'scroll.refreshComplete', ->
        start = end = 0
        #No way to listen to rendering complete now
        $timeout update, 1000

      #list reset or more item loaded
      scope.$on 'list.rendered', ->
        $timeout update, 100
  )