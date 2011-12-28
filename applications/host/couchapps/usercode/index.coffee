do (jQuery) ->

  $ = jQuery

  make_id = (t,n) -> [t,n].join ':'
  host_username = (n) -> "host@#{n}"

  container = '#content'

  profile = $(container).data 'profile'

  # FIXME: Retrieve the default value for host_couchdb_uri (public, no password embedded) from some configuration area.

  host_tpl = $.compile_template ->

    form id:'host_record', method:'post', action:'#/host', class:'validate', ->

      textbox
        id:'host'
        title:'Host'
        class:'required text'
        value:@host

      textbox
        id:'provisioning.host_couchdb_uri'
        title: 'Provisioning database URI'
        class:'required url'
        value: @provisioning?.host_couchdb_uri ? (window.location.protocol + '//' + window.location.host + '/provisioning/')

      input type:'submit'

    $('form.validate').validate()

  $(document).ready ->
    $.sammy container, ->
      app = @
      model = @createModel 'host'

      # Show template (to create new host)
      @get '#/host', ->
        @swap host_tpl {}

      # Save
      @post '#/host', ->
        form_is_valid = $('#host_record').valid()

        if form_is_valid
          @trigger 'save-doc'

      @bind 'save-doc', ->

        $.ccnq3.save_doc
          app: @
          model: model
          push: 'provisioning'
          before: (doc) ->

            doc.type = 'host'
            doc._id = make_id 'host', doc.host

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
            doc.account ?= ''  # Required for replication to work.

            doc.provisioning ?= {}

            ###
              couchdb_uri is local for any non-manager host.
              Since manager hosts are bootstrapped using a script, not this interface,
              assume we are dealing with a non-manager host.
            ###
            doc.provisioning.couchdb_uri = 'http://127.0.0.1:5984/provisioning'

            ###
              applications/host is always required.
              FIXME provide an interface to add more applications, especially:
                applications/freeswitch
                applications/opensips
                applications/traces
            ###
            doc.applications ?= [
              "applications/host"
            ]

            doc.mailer ?= {}
            doc.mailer ?= sendmail: '/usr/sbin/sendmail'

            ###
              Account creation for host@#{hostname}
            ###
            username = host_username doc.host
            password = hex_sha1 "a"+Math.random()

            u = doc.provisioning.couchdb_uri.matches ///
                ^
                (https?://)
                (?:[^@]*@)?
                (.*)
              ///i

            unless u
              alert 'Invalid provisioning URL'
              return

            doc.provisioning.host_couchdb_uri = u[0] + encodeURI(username) + ':' + encodeURI(password) + '@' + u[1]

            ###
              Save the password so that the "create" method can retrieve it.
              (This isn't more of a security concern than storing it in the
              host_couchdb_uri.)
            ###
            doc.password = password

          create: (doc,cb) ->

            ###
              Create the user account record for this host.
              (Hosts are given direct, read-only access to the provisioning
              database so that they can replicate it locally.)
            ###
            username = host_username doc.host

            p =
              name: username
              roles: ["host"]

            ###
              Quite obviously this can only be ran by server-admins or users_writer.
            ###
            $.couch.signup p, doc.password,

              error: (xhr,status,error) ->
                alert "Host signup failed: #{error}"

              success: cb

      app = @

      Inbox.register 'host',

        list: (doc) ->
          return "Server #{doc.host}"

        form: (doc) ->
          host_tpl doc
