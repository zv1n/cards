class window.Hand

  constructor: (@fire, @white) ->
    @player = {}
    @picking = 'Loading...'

    _this = this

    source = $("#hand-template").html()
    @hand_template = Handlebars.compile(source)

    @fire.user.once 'value', (ss) ->
      if (ss.val() == null)
        _this.fire.user.set { hand: {} }, (error) ->
          unless error
            _this.player = { hand: {} }
            _this.update()
      else
        _this.player = ss.val()
        unless 'hand' of _this.player
          _this.player.hand = {}
        _this.update()

  draw: ->
    draw = @white.draw()
    @player.hand[draw.key] = draw.card
    @update_render()

  configure_card_sel: ->
    $('.hand .card').click (event) ->
      $target = $(event.currentTarget)
      $('.hand .card').removeClass('selected')
      $target.addClass('selected')

  hand: ->
    @player.hand

  update: ->
    while Object.keys(@player.hand).length < 7
      draw = @white.draw()
      @player.hand[draw.key] = draw.card

      @fire.user.update({
        hand: @player.hand
      })

    discarded = {}
    for f of @player.hand
      discarded[f] = true

    @fire.cards.child('discarded').update(discarded)
    @update_render()

  update_render: ->
    $('#hand').html(@hand_template({
      cards: @player.hand,
      picking: @picking
    }))

    @configure_card_sel()




