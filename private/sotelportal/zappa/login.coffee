###
(c) 2010 Stephane Alnet
Released under the AGPL3 license
###

@include = ->
  coffee '/p/login.js': ->

    extra_login = $.extra_login

    $.extra_login = (auth,next) ->

      ccnq2_login = (auth,next) ->
        ccnq2_options =
          type: 'post'
          url: '/portal/login'
          data:
            username: auth.username
            password: auth.password
          complete: ->
            next?()

        auth.notify 'Signing you into the voice portal.'
        auth.$.ajax(ccnq2_options)

      kayako_login = (auth,next) ->
        # kayako_options =
        #   type: 'post'
        #   url: '/portal/login'
        #   data:
        #     username: auth.username
        #     password: auth.password
        #   complete: ->
        #     next?()
        #
        # auth.notify 'Signing you into support.'
        # auth.$.ajax(kayako_options)
        next?()

      if extra_login?
        extra_login auth, -> ccnq2_login auth, -> kayako_login auth, next
      else
        ccnq2_login auth, -> kayako_login auth, next
