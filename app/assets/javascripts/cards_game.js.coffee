class window.CardsGame
  constructor: (@user, @game_id) ->
    @root = new Firebase(window.firebase).child('current_games').child(@game_id)
    @fire = {
      root: @root,
      chat: @root.child('chat'),
      cards: @root.child('cards'),
      user: @root.child('players').child(@user)
    }

    @black = new BlackDeck(@fire.cards)
    @white = new WhiteDeck(@fire.cards)
    @chat = new Chat(@fire.chat, @user)

    @players = {}
    @game = {}
    @selection = -1

  start: () ->
    _this = this

    @compile_templates()
    @hand = new Hand(@fire, @white, this)

    $('#game-id').text("(#{@game_id} - #{@user})")
    @init_game()

  is_picker: (name) ->
    name == @game.picker

  is_self: (name) ->
    name == @user

  is_winner: (name) ->
    name == @game.winner

  is_owner: (name) ->
    @game.owner == @user

  play_order: (name) ->
    @game.players[name].order

  all_players_picked: ->
    for f of @game.players
      return false if @game.players[f].selection == -1

    return true

  next_picker: ->
    picker_idx = @game.players[@game.picker].order + 1
    picker_idx = 0 if picker_idx == Object.keys(@game.players).length

    for f of @game.players
      return f if @game.players[f].order == picker_idx

    return Object.keys(@game.players)[0]

  round_winner: (user) ->
    next_picker = @next_picker()

    # Reset the local selection
    @selection = -1

    @chat.game_line("#{user} wins the round!")

    @fire.root.update({ winner: user })
    game_update = {
      winner: null,
      picker: next_picker,
      players: {}
    }

    won_card = @game.players[@game.picker].selection

    for f of @game.players
      game_update.players[f] = @game.players[f]
      game_update.players[f].selection = -1

      if f == user
        unless game_update.players[f].won
          game_update.players[f].won = {}
        game_update.players[f].won[won_card] = @black.card(won_card)

      if f == next_picker
        @selection = @black.draw().key

        if @selection == undefined
          @fire.root.update({ game_over: true })
          return

        game_update.players[f].selection = parseInt(@selection)
        @black.send_removal(@selection)


    console.log("Sel: #{game_update.players[next_picker].selection}")
    console.log(game_update)

    _this = this
    setTimeout( ->
      _this.root.update(game_update)
      _this.chat.game_line("Next up: #{next_picker}")
    , 5000)


  update_players: ->
    for f of @game.players
      unless @players[f]
        @players[f] = new Player(f, this)
      @players[f].update(@game.players[f])

    removals = []
    for p of @players
      unless p of @game.players
        @players[p].destroy()
        removals.push p

    for f in removals
      delete @players[f]
      if @user == f
        alert('You have been kicked from this game!')
        Turbolinks.visit('/')

    if @game.picker
      @black.remove_card(@game.players[@game.picker].selection)

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

    # console.log("White Cards Left: #{@white.cards_remaining()} of #{@white.cards_total()}")
    # console.log("Black Cards Left: #{@black.cards_remaining()} of #{@black.cards_total()}")

  game_over: ->
    alert('Looks like the game is over! No more black cards to select!') unless @alerted
    @alerted = true

  host_actions: ->
    _this = this
    $('#host-tab').fadeIn()

    $('#reset').click ->
      return unless confirm('Are you sure you want to reset the game?')
      _this.fire.root.update({ game_over: false })
      _this.fire.cards.update({ discarded: {}, won: {} })

  reset_game_state: ->
    @selection = -1

  displaying_winner: ->
    @game.winner != undefined

  update_round: ->
    return @game_over() if @game.game_over

    if @displaying_winner()
      @reset_game_state()
      for player of @players
        @players[player].update_winner(@game.winner)

    _this = this

    @update_picker()

    if @selection > -1
      bcard = @black.card(@selection)
      btext = $('#board #black-card-text')
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

  update_picker: ->
    return unless @game.players

    @picker = @game.players[@game.picker]

    if @picker.selection > -1 || !@is_picker(@user)
      @selection = @picker.selection

  create: ->
    console.log("Creating game: #{@game_id}")

    @game_exists (exists) ->
      if exists
        alert('Oops. This game already exists. Refresh and try again.')
        window.location.refresh()
        return
      else
        console.log("Creating game: #{@game_id}")
        @new_game()
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
        return @navigate() if @user of list.players

        player_info = {
          hand: {},
          won: {},
          selection: -1, 
          order: Object.keys(list.players).length
        }

        @fire.root.child('players').child(@user).update(player_info)
        @navigate()

  game_exists: (cb) ->
    _this = this

    @fire.root.once('value', (snapshot) ->
      cb.call(_this, snapshot.val())
    )

  init_game: ->
    _this = this

    @fire.root.once('value', (snapshot) ->
      _this.game = snapshot.val()

      if _this.is_owner(@user)
        _this.host_actions()

      _this.game_listeners.call(_this)
    )

  game_listeners: ->
    _this = this

    unless @user of @game.players
      alert('You must join the game first!')
      Turbolinks.visit('/')

    @update_cards()
    @update_players()
    @update_picker()
    @update_round()

    @fire.root.child('cards').on('value', (snapshot) ->
      _this.game.cards = snapshot.val()
      _this.update_cards.call(_this)
    )

    @fire.root.child('players').on('value', (snapshot) ->
      _this.game.players = snapshot.val()
      _this.update_players.call(_this)
    )

    @fire.user.on('value', (snapshot) ->
      _this.hand.update(snapshot.val())
    )

    @fire.root.on('value', (snapshot) ->
      _this.game = snapshot.val()
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

  new_game: ->
    @selection = @black.draw().key
    @black.send_removal(@selection)

    player_list = {}
    player_list[@user] = {
      wins: {},
      hand: {},
      selection: parseInt(@selection),
      order: 0
    }

    @fire.root.set({
      players: player_list,
      owner: @user,
      cards: {
        won: {},
        discarded: {}
      },
      picker: @user
    })
