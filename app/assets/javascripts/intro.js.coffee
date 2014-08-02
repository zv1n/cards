
(->

  configure_init = ->
    slideable = (target, slide) ->
      console.log(target)
      console.log(slide)
      if ($target = $(target)).length > 0
        $target.click (event) ->
          if ($slide = $(slide)).length > 0
            if $slide.is(':visible')
              $slide.slideUp()
            else
              $slide.slideDown()

    slideable('#host', '#new-game')
    slideable('#join', '#in-progress')

  $(document).on 'page:load', configure_init
)()