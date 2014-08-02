class window.CardsGame
  constructor: (@user) ->

  create: (@game_id) ->

  join: (@game_id) ->

  navigate: ->
    Turbolinks.visit("/game?id=#{@game_id}&as=#{@user}")