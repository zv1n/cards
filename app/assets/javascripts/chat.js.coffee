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

    chat_target = ($line) ->
      _this.send_chat($line.val())
      $line.val('')

    $('#chat').keypress (event) ->
      if event.which == 13
        $line = $(event.currentTarget)
        chat_target($line)

    $('#send').click (event) ->
      $line = $('#chat')
      chat_target($line)

    @container = $('.chat-container')

  update_chat: (@chat) ->
    last_id = undefined
    for f of @chat
      if $("##{f}").length == 0
        msg = @chat[f]
        msg.id = f

        if 'name' of msg
          $('#chat-box').append(@user_message(msg))
        else
          $('#chat-box').append(@admin_message(msg))

        $('#chat-box .timeago').timeago()

        last_id = f

    if last_id
      chatline = $("##{last_id}")
      @container.animate({
        scrollTop: chatline.position().top + chatline.height() + @container.scrollTop()
      }, 100)

  send_chat: (line) ->
    if line.length > 0
      @fire.push({
        name: @user,
        time: (new Date()).toISOString(),
        message: line
      })

  game_line: (line) ->
    @fire.push({
      time: (new Date()).toISOString(),
      message: line
    })
