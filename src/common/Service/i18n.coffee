

angular.module('i18n', [])
  .directive('trans', ()->
    link: (scope, element)->
      text = window.locale?[window.lang]?[element.text()]
      element.text(text) if text
  )