###
(c) 2010 Stephane Alnet
Released under the AGPL3 license
###

@include = ->
  coffee '/p/login.js': ->

    extra_login = $.extra_login

    $.extra_login = ($,next) ->

      ccnq2_login = ($,next) ->
        ccnq2_options =
          type: 'post'
          url: '/portal/login'
          data:
            username: $('#login_username').val()
            password: $('#login_password').val()
          complete: ->
            next?()

        $('#login_error').html('Signing you into the voice portal.')
        $.ajax(ccnq2_options)

      kayako_login = ($,next) ->
        # kayako_options =
        #   type: 'post'
        #   url: '/portal/login'
        #   data:
        #     username: $('#login_username').val()
        #     password: $('#login_password').val()
        #   complete: ->
        #     next?()
        #
        # $('#login_error').html('Signing you into support.')
        # $.ajax(kayako_options)
        next?()

      if extra_login?
        extra_login $, -> ccnq2_login $, -> kayako_login $, next
      else
        ccnq2_login $, -> kayako_login $, next
