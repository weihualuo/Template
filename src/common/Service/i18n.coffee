

angular.module('i18n', [])
  .run(->
    window._U = (text)->
      window.locale?[window.lang]?[text] or text
  )
  .directive('trans', ()->
    link: (scope, element)->
      text = window.locale?[window.lang]?[element.text()]
      element.text(text) if text
  )