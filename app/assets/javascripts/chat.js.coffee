class window.Chat
  constructor: (@fire, @user) ->
    _this = this

    source = $("#user-msg-template").html()
    @user_message = Handlebars.compile(source) if source

    source = $("#admin-msg-template").html()
    @admin_message = Handlebars.compile(source) if source

    @fire.on('value', (snapshot) ->
      _this.update_chat.call(_this, snapshot.val())
    )

    $('#chat').keypress (event) ->
      if event.which == 13
        $line = $(event.currentTarget)
        if $line.val().length > 0
          _this.send_chat($line.val())
        $line.val('')

  update_chat: (@chat) ->
    for f of @chat
      if $("##{f}").length == 0
        msg = @chat[f]
        msg.id = f

        if 'name' of msg
          $('#chat-box').append(@user_message(msg))
        else
          $('#chat-box').append(@admin_message(msg))

        $('.chat-container').animate({
          scrollTop: $("##{f}").position().top
        }, 0)

  send_chat: (line) ->
    @fire.push({ name: @user, message: line })

  game_line: (line) ->
    @fire.push({ message: line })
