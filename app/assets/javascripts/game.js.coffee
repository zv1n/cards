$(document).on 'page:load', ->

  params = window.location.search.replace(/^\?/, '').split('&').reduce(
    (obj, value) ->
      info = value.split('=')
      obj[info[0]] = info[1]
      return obj
  , {})

  if params.hasOwnProperty('as') && params.hasOwnProperty('id')
    window.game = new CardsGame(params.as, params.id)
    window.game.start()
