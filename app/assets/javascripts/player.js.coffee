class window.Player
  constructor: (@player, @game) ->

  points_for_player: (player) ->
    if player.hasOwnProperty('won')
      return Object.keys(player.won).length
    else
      return 0

  kick_action: (target) ->
    target.click (event) ->
      console.log('TODO: $(event.currentTarget)')

  update: (@self) ->
    @update_players()
    @update_table()

  update_players: ->
    user_list = $('#users')
    user = $("#users ##{@player}")

    if user.length == 0
      user = $(@game.users_template({player: @self, user: @player}))
      user_list.append(user)
      user.fadeIn()
      @kick_action(user) if @game.is_owner(@game.user)

    user.find('.kick').removeClass('prehidden') if @game.is_owner(@user)
    user.find('#points').text(@points_for_player(@self))

    if @game.is_picker(@player)
      user.addClass('picker')
    else
      user.removeClass('picker')

    if @game.is_self(@player)
      user.addClass('self')
    else
      user.removeClass('self')

  update_table: ->
    _this = this
    $card_list = $('#board-content')
    $card = $("#board-content ##{@player}-card")
    $placeholder = $("#board-content ##{@player}-placeholder")

    if $card.length == 0
      cards = $(@game.board_template({user: @player}))
      $card_list.append(cards)
      $card = $("#board-content ##{@player}-card")
      $placeholder = $("#board-content ##{@player}-placeholder")

    $("##{@player}-card .select-me").click (event) ->
      $target = $(event.currentTarget)

      $('#board-content .card.white').addClass('no-select')
        .removeClass('selected').unbind('click')

      user = $target.data('user')
      _this.game.round_winner(user)

    @show_placeholder(@self.selection == 0, $card, $placeholder)
    @set_card_text($card, @game.white.card(@self.selection) || '')
    @show_card_text(@game.all_players_picked(), $card)

    setTimeout( ->
      _this.show_table_cards(!_this.game.is_picker(_this.player))
    ,
      500)
    return

  set_card_text: (card, text) ->
    cardtext = card.find('#card-text')

    if cardtext.html() != text
      cardtext.fadeOut( ->
        cardtext.html(text)
        cardtext.fadeIn()
      )

  show_placeholder: (show, card, placeholder) ->
    if show
      card.fadeOut ->
        placeholder.fadeIn()
    else
      placeholder.fadeOut ->
        card.removeClass('no-select').fadeIn()

  show_table_cards: (show) ->
    if show
      $("##{@player}-table").fadeIn()
    else
      $("##{@player}-table").fadeOut()

  show_card_text: (show, card) ->
    $text = card.find('#card-text')
    if show
      $text.fadeIn()
    else
      $text.fadeOut()

