class window.Hand

  constructor: (@fire, @white) ->
    @player = {}
    @black_card = 'Loading...'

    _this = this

    source = $("#hand-template").html()
    @hand_template = Handlebars.compile(source)

  set_black_card: (sel) ->
    _this = this
    @black_card = sel

    if $('#black-card').html() != @black_card
      $('#black-card').fadeOut(->
        $('#black-card').html(_this.black_card).fadeIn()
      )

  configure_card_sel: ->
    $('.hand .card').click (event) ->
      $target = $(event.currentTarget)
      return if $target.hasClass('disabled')
      $('.hand .card').removeClass('selected')
      $target.addClass('selected')

  hand: ->
    @player.hand

  update_hand: ->
    _this = this

    new_card = null
    @player.hand = {} unless @player.hasOwnProperty('hand')

    if Object.keys(@player.hand).length < 7
      for card in [Object.keys(@player.hand).length..7]
        draw = @white.draw(false)
        @player.hand[draw.key] = draw.card

      @fire.user.update({
        hand: @player.hand
      })

    discarded = {}
    for f of @player.hand
      discarded[f] = true

    @fire.cards.child('discarded').update(discarded)

    for f of @player.hand
      if $("##{f}").length == 0
        new_card = f

    console.log(@player.selection)
    console.log(new_card)

  update: (player) ->
    player.hand ||= {}

    if player != @player
      if player.hand != @player.hand
        @player.hand = player.hand
        @update_hand()

      @player = player

    @update_render()

  update_render: ->
    _this = this

    if $('#hand-content .hand').length == 0
      $('#hand-content').html(@hand_template({
        cards: @player.hand,
        picking: @black_card,
        picker: @picker
      }))

      $('.use-me').unbind('click').click (event) ->
        $target = $(event.currentTarget)

        card = $target.data('card')
        _this.fire.user.update({ selection: card })
        _this.fire.user.child('hand').child(card).remove()

        $("##{card} #card-text").fadeOut()

    @configure_card_sel()




