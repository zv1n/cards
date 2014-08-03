class window.CardsGame
  constructor: (@user, @game_id) ->
    @root = new Firebase(window.firebase)

    @black = new BlackDeck()
    @white = new WhiteDeck()

  start: () ->
    $('#game-id').text("Game ID: #{@game_id}")

  create: (@game_id) ->
    console.log("Creating game: #{@game_id}")

    @game_exists(@game_id, (exists) ->
      if exists
        alert('Oops. This game already exists. Refresh and try again.')
        window.location.refresh()
        return
      else
        console.log("Creating game: #{@game_id}")

        player_list = {}
        player_list[@user] = {
          wins: [],
          hand: [],
          selection: 0
        }

        @root.child('current_games').child(@game_id).set({
          owner: @user,
          players: player_list,
          cards: {
            active: [],
            discarded: [],
            round: {
              picker: @user
            }
          }
        })

        @navigate()
    )

  join: (@game_id) ->
    console.log("Joining game: #{@game_id}")

    @game_exists(@game_id, (exists) ->
      if !exists
        return @create(@game_id) if confirm(
          'This game does not appear to exist. '+
          'Do you wish to create it instead?'
        )

        return false
      else
        @navigate()
    )

  game_exists: (id, cb) ->
    _this = this

    @root.child('current_games').child(id).once('value', (snapshot) ->
      cb.call(_this, (snapshot.val() != null))
    )
    

  navigate: ->
    console.log('Entering Game...')
    Turbolinks.visit("/game?id=#{@game_id}&as=#{@user}")