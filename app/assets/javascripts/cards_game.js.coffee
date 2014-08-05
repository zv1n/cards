class window.CardsGame
  constructor: (@user, @game_id) ->
    @root = new Firebase(window.firebase).child('current_games').child(@game_id)
    @fire = {
      cards: @root.child('cards'),
      user: @root.child('players').child(@user)
    }

    @black = new BlackDeck(@fire.cards)
    @white = new WhiteDeck(@fire.cards)

    @game = {}

  start: () ->
    _this = this

    @compile_templates()
    @hand = new Hand(@fire, @white)

    $('#game-id').text("(#{@game_id} - #{@user})")
    @game_listener()

  is_picker: (name) ->
    name == @game.picker

  is_self: (name) ->
    name == @user

  is_owner: (name) ->
    @game.owner == @user

  points_for_player: (player) ->
    if player.hasOwnProperty('won')
      return Object.keys(player.won).length
    else
      return 0

  update_players: ->
    info = @game.players

    if @is_picker(@user)
      $('.you-are-picker').slideDown()
    else
      $('.you-are-picker').slideUp()

    for f of info
      info[f].user = f

    for f of info
      user_list = $('#users')
      user = $("##{f}")

      if user.length == 0
        user = $(@users_template(info[f]))
        user_list.append(user)
        user.fadeIn()
        @kick_action(user) if @is_owner(@user)

      user.find('.kick').removeClass('prehidden') if @is_owner(@user)
      user.find('#points').text(@points_for_player(info[f]))

      if @is_picker(f)
        user.addClass('picker')
      else
        user.removeClass('picker')

      if @is_self(f)
        user.addClass('self')
      else
        user.removeClass('self')

    user_list = $('#users ')

    @hand.update()

  kick_action: (target) ->
    target.click (event) ->
      console.log('TODO: $(event.currentTarget)')

  update_places: ->
    @game.places = []
    for f of @game.players
      continue if @game.players[f].picked || f == @game.picker
      @game.places.push f

  update_cards: ->
    unless @game.cards
      @game.cards = {
        discarded: {},
        won: {}
      }

    for f of @game.cards.discarded
      @white.remove_card(f)

    for f of @game.cards.won
      @black.remove_card(f)

    @black.remove_card(@game.players[@game.picker].picking)

    console.log("White Cards Left: #{@white.cards_remaining()} of #{@white.cards_total()}")
    console.log("Black Cards Left: #{@black.cards_remaining()} of #{@black.cards_total()}")

  update_round: ->
    @picker = @game.players[@game.picker]
    picking = @picker.picking

    if @is_picker(@user) && picking == undefined
      picking = @black.draw().key
      @fire.user.update({
        picking: picking
      })

    bcard = @black.card(picking)
    @hand.set_black_card(bcard)
    @hand.picker = @is_picker(@user)

    $('#board').html(@board_template({
      name: @game.picker,
      picking: @hand.picking,
      places: @game.places,
      show_cards: @game.places.length > 0
    }))

    @hand.update()

  create: ->
    console.log("Creating game: #{@game_id}")

    @game_exists (exists) ->
      if exists
        alert('Oops. This game already exists. Refresh and try again.')
        window.location.refresh()
        return
      else
        console.log("Creating game: #{@game_id}")
        @init_game()
        @navigate()

  join: ->
    console.log("Joining game: #{@game_id}")

    @game_exists (list) ->
      if list == null
        return @create(@game_id) if confirm(
          'This game does not appear to exist. '+
          'Do you wish to create it instead?'
        )

        return false
      else
        order = Object.keys(list.players).length

        player_info = {}
        player_info[@user] = {
          selection: 0,
          order: order,
          wins: {},
          hand: {}
        }

        @root.child('players').update(player_info)
        @navigate()

  game_exists: (cb) ->
    _this = this

    @root.once('value', (snapshot) ->
      cb.call(_this, snapshot.val())
    )

  game_listener: ->
    _this = this

    @root.on('value', (snapshot) ->
      _this.game = snapshot.val()
      _this.update_players.call(_this)
      _this.update_cards.call(_this)
      _this.update_places.call(_this)
      _this.update_round.call(_this)
    )

  navigate: ->
    console.log('Entering Game...')
    Turbolinks.visit("/game?id=#{@game_id}&as=#{@user}")

  compile_templates: ->
    source = $("#board-template").html()
    @board_template = Handlebars.compile(source)

    source = $("#users-template").html()
    @users_template = Handlebars.compile(source)

  init_game: ->
    player_list = {}
    player_list[@user] = {
      wins: {},
      hand: {},
      selection: 0,
      picker: true,
      order: 0
    }

    @root.set({
      players: player_list,
      owner: @user,
      cards: {
        won: {},
        discarded: {}
      },
      picker: @user
    })
