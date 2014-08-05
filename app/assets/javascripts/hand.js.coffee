class window.Hand

  constructor: (@fire, @white) ->
    @player = {}
    @selection = 'Loading...'

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

  set_black_card: (sel) ->
    _this = this
    @selection = sel

    if $('#black-card').html() != @selection
      $('#black-card').fadeOut(->
        $('#black-card').html(_this.selection).fadeIn()
      )

  draw: ->
    draw = @white.draw()
    @player.hand[draw.key] = draw.card
    @update_render()

  configure_card_sel: ->
    $('.hand .card').click (event) ->
      $target = $(event.currentTarget)
      return if $target.hasClass('disabled')
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
    _this = this

    $('#hand-content').html(@hand_template({
      cards: @player.hand,
      picking: @selection,
      picker: @picker
    }))

    $('.use-me').click (event) ->
      $target = $(event.currentTarget)
      card = $target.data('card')
      _this.fire.user.update({ picking: card })

    @configure_card_sel()




