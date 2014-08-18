class window.Hand

  constructor: (@fire, @white, @game) ->
    @player = {}
    @black_card = 'Loading...'

    _this = this

    source = $("#hand-template").html()
    @hand_template = Handlebars.compile(source)

  set_black_card: (@picker, sel) ->
    _this = this
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
        if @player.selection == -1
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
    @player.hand = {} unless @player.hasOwnProperty('hand')

    if Object.keys(@player.hand).length < 7
      new_cards = []
      for card in [Object.keys(@player.hand).length..6]
        draw = @white.draw(false)
        new_cards.push draw.key
        @player.hand[draw.key] = draw.card

      @fire.user.update({
        hand: @player.hand
      })

      @white.send_removal(new_cards)

  update_discarded: ->
    discarded = {}
    for f of @player.hand
      discarded[f] = true

    @fire.cards.child('discarded').update(discarded)

  update_difference: ->
    new_cards = []

    for f of @player.hand
      if $("##{f}").length == 0
        new_cards.push f

    cards = $('#hand-content .card').map (ix,el) -> el.id
    for card in cards
      continue if card of @player.hand
      @update_card(card, new_cards.pop())

  update_hand: ->
    _this = this

    @populate_and_update_hand()
    @update_discarded()

    # Just return if there are no cards, they will be rendered correctly.
    return if $('#hand-content .card').length == 0

    @update_difference()

  update_card: (selection, new_card) ->
    _this = this
    $selection = $("##{selection}")
    $text = $selection.find('#card-text')
    $text.fadeOut -> $text.html(_this.white.card(new_card)).fadeIn()
    $selection.attr('id', new_card)

  update: (player) ->
    return unless player

    player.hand ||= {}

    if player != @player
      if player.hand != @player.hand
        @player.hand = player.hand
        @update_hand()

      @player = player

    @update_render()

  update_render: (changed) ->
    _this = this

    if $('#hand-content .card').length != 7
      $('#hand-content').html(@hand_template({
        cards: @player.hand,
        picking: @black_card,
        picker: @picker
      }))

      $cards = $('#hand-content .card')
      $cards.addClass('disabled') if @player.selection > -1 || @picker
      $cards.slideDown().removeClass('prehidden')

      $('.use-me').unbind('click').click (event) ->
        $target = $(event.currentTarget)
        $target.attr('disabled', true).addClass('disabled')
        card = $target.parent().attr('id')

        $('#hand-content .card').addClass('disabled')

        $("##{card} #card-text").fadeOut(->
          $("##{card}").removeClass('selected')
          $target.attr('disabled', false).removeClass('disabled')

          _this.fire.user.update({ selection: parseInt(card) })
          _this.fire.user.child('hand').child(card).remove()
        )

    @configure_card_sel()




