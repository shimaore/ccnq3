do (jQuery) ->

  $ = jQuery

  make_id = (t,n) -> [t,n].join ':'
  host_username = (n) -> "host@#{n}"

  container = '#content'

  profile = $(container).data 'profile'

  host_template = $.compile_template ->
    # CoffeeKup template here

  $(document).ready ->
    $.sammy container, ->
      app = @
      model = @createModel 'host'

      # Create new host
      @put '#/host', ->

        config = $('#config').toDeepJson()
        config.type = 'host'
        config._id  = make_id 'host', config.host
        ###
          Host are by default created at the root account.
          In order to read and modify such records the user must have
            access:provisioning:
          and
            update:provisioning:
          respectively, listed in their 'roles', effectively allowing them
          to modify _any_ provisioning records.
          Otherwise the user might specify any account they'd like, and users
          with access to that account (or any prefix) will be able to modify the
          matching host(s).
        ###
        config.account ?= ''  # Required for replication to work.

        username = "host@#{config.host}"
        password = hex_sha1 "a"+Math.random()

        p =
          name: username
          roles: ["host"]

        # Quite obviously this can only be ran by server-admins or users_writer.
        $.couch.signup p, password,

          error: (xhr,status,error) ->
            alert "Host user record created, but save failed: #{error}"

          success: ->

            @send model.create, config,
              success:
                $.post '/roles/replicate/push/provisioning', (data)->
                  if data.ok
                    alert "Host created OK."
                    window.location = '#/inbox'
                  else
                    alert "Host created, but replication failed."
                , 'json'
