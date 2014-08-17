class window.Hand

  constructor: (@fire, @white, @game) ->
    @player = {}
    @black_card = 'Loading...'

    _this = this

    source = $("#hand-template").html()
    @hand_template = Handlebars.compile(source)

  set_black_card: (@picker, sel) ->
    _this = this
    console.log sel
    @black_card = sel

    if $('#black-card').html() != @black_card
      $('#black-card').fadeOut(->
        $('#black-card').html(_this.black_card).fadeIn()
      )

    if @picker
      $('.you-are-picker').slideDown()
      $('.hand .card').addClass('disabled')
    else
      $('.you-are-picker').slideUp()
      $('.hand .card').removeClass('disabled')

  configure_card_sel: ->
    $('.hand .card').click (event) ->
      $target = $(event.currentTarget)
      return if $target.hasClass('disabled')
      $('.hand .card').removeClass('selected')
      $target.addClass('selected')

    if @picker
      $('#board-content .card.white').click (event) ->
        $target = $(event.currentTarget)
        return if $target.hasClass('disabled') || $target.hasClass('no-select')
        $('#board-content .card.white').removeClass('selected')
        $target.addClass('selected')
    else
      $('#board-content .card.white').unbind('click')

  hand: ->
    @player.hand

  populate_and_update_hand: ->
    if Object.keys(@player.hand).length < 7
      new_cards = []
      for card in [Object.keys(@player.hand).length..7]
        draw = @white.draw(false)
        new_cards.push draw.key
        @player.hand[draw.key] = draw.card

      @fire.user.update({
        hand: @player.hand
      })
      @white.send_removal(new_cards)

  update_hand: ->
    _this = this

    new_card = null
    @player.hand = {} unless @player.hasOwnProperty('hand')

    @populate_and_update_hand()

    discarded = {}
    for f of @player.hand
      discarded[f] = true

    @fire.cards.child('discarded').update(discarded)

    for f of @player.hand
      if $("##{f}").length == 0
        new_card = f

    if new_card
      $selection = $("##{@player.selection}")
      $selection.find('#card-text').html(@white.card(new_card)).fadeIn()
      $selection.attr('id', new_card)

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

    if $('#hand-content .card').length != 7
      $('#hand-content').html(@hand_template({
        cards: @player.hand,
        picking: @black_card,
        picker: @picker
      }))

      $cards = $('#hand-content .card')
      $cards.addClass('disabled') if @player.selection > 0 || @picker
      $cards.slideDown().removeClass('prehidden')

      $('.use-me').unbind('click').click (event) ->
        $target = $(event.currentTarget)
        $target.attr('disabled', true).addClass('disabled')
        card = $target.data('card')

        $("##{card} #card-text").fadeOut(->
          $("##{card}").removeClass('selected')
          $target.attr('disabled', false).removeClass('disabled')
          $('#hand-content .card').addClass('disabled')

          _this.fire.user.update({ selection: card })
          _this.fire.user.child('hand').child(card).remove()
        )

    @configure_card_sel()




