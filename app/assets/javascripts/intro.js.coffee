
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
      event.preventDefault()
      $form = $(event.currentTarget)

      user = $form.find('#username').val()
      game = $form.find('#game_id').val()

      unless user.length > 0
        alert("Please enter a username.")
        return false

      unless game.length > 0
        alert("Please enter a Game ID.")
        return false

      game_instance = new CardsGame(user, game)

      switch $form.data('action')
        when 'create'
          console.log('Running create...')
          game_instance.create()
        when 'join'
          console.log('Running join...')
          game_instance.join()

      return false

  $(document).on 'page:load', configure_init
  $(document).on 'page:load', configure_create
)()