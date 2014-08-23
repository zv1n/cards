class window.Player
  constructor: (@player, @game) ->

  points_for_player: (player) ->
    if player.hasOwnProperty('won')
      return Object.keys(player.won).length
    else
      return 0

  kick_action: (target) ->
    _this = this
    target.click (event) ->
      return unless confirm('Are you sure you want to delete this user?')
      player = $(event.currentTarget).parent().attr('id')
      _this.game.fire.root.child('players').child(player).remove()

  update: (@self) ->
    @update_players()
    @update_table()

  destroy: ->
    $("#users ##{@player}").fadeOut -> this.remove()
    $("##{@player}-table").fadeOut -> this.remove()

  update_players: ->
    user_list = $('#users')
    user = $("#users ##{@player}")

    if user.length == 0
      user = $(@game.users_template({player: @self, user: @player}))
      user_list.append(user)
      user.fadeIn()
      @kick_action(user.find('.kick')) if @game.is_owner(@game.user)

    if @game.is_owner(@game.user)
      user.find('.kick').removeClass('prehidden')

    user.find('#points').text(@points_for_player(@self))
    user.find('#order').text(@game.play_order(@player))

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

    $("##{@player}-card .select-me").unbind('click').click (event) ->
      $target = $(event.currentTarget)

      $('#board-content .card.white').addClass('no-select')
        .removeClass('selected').unbind('click')

      user = $target.data('user')
      _this.game.round_winner(user)

    unless @game.displaying_winner()
      $("##{@player}-name").fadeOut()
      $("##{@player}-winner").fadeOut()
      $("##{@player}-card").removeClass('disabled')

    @show_placeholder(@self.selection == -1, $card, $placeholder)
    @set_card_text($card, @game.white.card(@self.selection) || '')
    @show_card_text(@game.all_players_picked(), $card)

    setTimeout( ->
      _this.show_table_cards(_this.should_display_cards())
    ,
      500)
    return

  update_winner: (winner) ->
    if @player == winner
      $("##{@player}-winner").fadeIn()
    else
      $("##{@player}-card").addClass('disabled')

    $('#board-content .user').fadeIn()

  set_card_text: (card, text) ->
    cardtext = card.find('#card-text')

    if cardtext.html() != text
      cardtext.fadeOut( ->
        cardtext.html(text)
      )

  show_placeholder: (show, card, placeholder) ->
    if show
      card.fadeOut ->
        placeholder.fadeIn()
    else
      placeholder.fadeOut ->
        card.removeClass('no-select').fadeIn()

  should_display_cards: ->
    return (!@game.is_picker(@player)) && (@is_seated() || @has_selected())

  is_seated: ->
    return (@self.seated == undefined || @self.seated)

  has_selected: ->
    @self.selection != -1

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

