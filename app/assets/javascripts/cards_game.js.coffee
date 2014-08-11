class window.CardsGame
  constructor: (@user, @game_id) ->
    @root = new Firebase(window.firebase).child('current_games').child(@game_id)
    @fire = {
      cards: @root.child('cards'),
      user: @root.child('players').child(@user)
    }

    @black = new BlackDeck(@fire.cards)
    @white = new WhiteDeck(@fire.cards)

    @players = {}
    @game = {}

  start: () ->
    _this = this

    @compile_templates()
    @hand = new Hand(@fire, @white, this)

    $('#game-id').text("(#{@game_id} - #{@user})")
    @game_listener()

  is_picker: (name) ->
    name == @game.picker

  is_self: (name) ->
    name == @user

  is_winner: (name) ->
    name == @game.winner

  is_owner: (name) ->
    @game.owner == @user

  all_players_picked: ->
    for f of @game.players
      return false if @game.players[f].picking == 0

    return true

  next_picker: ->
    picker_idx = @game.players[@game.picker].order + 1
    picker_idx = 0 if picker_idx == @game.players.length

    for f of @game.players
      return f if @game.players[f].order == picker_idx

    return Object.keys(@game.players)[0]

  round_winner: (user) ->
    @root.update({ winner: user })
    game_update = {
      winner: null,
      picker: @next_picker(),
      players: {}
    }

    for f of @game.players
      game_update.players[f] = @game.players[f]
      game_update.players[f].selection = 0

    _this = this
    setTimeout( ->
      _this.root.update(game_update)
    , 5000)


  update_players: ->
    for f of @game.players
      unless @players[f]
        @players[f] = new Player(f, this)
      @players[f].update(@game.players[f])

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

    @black.remove_card(@game.players[@game.picker].selection)

    # console.log("White Cards Left: #{@white.cards_remaining()} of #{@white.cards_total()}")
    # console.log("Black Cards Left: #{@black.cards_remaining()} of #{@black.cards_total()}")

  update_round: ->
    @picker = @game.players[@game.picker]
    picking = @picker.picking

    if @is_picker(@user) && picking == null
      picking = @black.draw().key

      @black.send_removal(picking)
      @fire.user.update({
        selection: picking
      })

    bcard = @black.card(picking)
    btext = $('#board #black-card-text')
    _this = this
    if btext.html() != bcard
      btext.fadeOut ->
        btext.html(bcard)
        btext.fadeIn()

    picker = $('#board #picker')
    if picker.html() != @game.picker
      picker.fadeOut ->
        picker.html(_this.game.picker)
        picker.fadeIn()

    @hand.set_black_card(@is_picker(@user), bcard)
    @hand.update(@game.players[@user])

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
