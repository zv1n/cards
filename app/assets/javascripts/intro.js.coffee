
(->

  configure_init = ->
    slideable = (target, slide) ->
      if ($target = $(target)).length > 0
        $target.click (event) ->
          if ($slide = $(slide)).length > 0
            if $slide.is(':visible')
              $slide.slideUp()
            else
              $slide.slideDown()

    slideable('#host', '#new-game')
    slideable('#join', '#in-progress')

  configure_create = ->
    $('form').submit (event) ->
      $form = $(event.currentTarget)

      user = $form.find('#username').val()
      game = $form.find('#game_id').val()

      unless user.length > 0
        event.preventDefault()
        alert("Please enter a username.")
        return false

      unless game.length > 0
        event.preventDefault()
        alert("Please enter a Game ID.")
        return false

      game_instance = new CardsGame(user)

      switch $form.data('action')
        when 'create' then game_instance.create(game)
        when 'join' then game_instance.join(game)

      event.preventDefault()
      return false

  $(document).on 'page:load', configure_init
  $(document).on 'page:load', configure_create
)()