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
        form_is_valid = $('form.validate').valid()

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
            doc.provisioning.couchdb_uri = 'http://127.0.0.1:5984/provisioning'
            doc.applications ?= [
              "applications/host"
            ]
            doc.mailer ?= {}
            doc.mailer ?= sendmail: '/usr/sbin/sendmail'

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
            doc.password = password

          create: (doc,cb) ->

            username = host_username doc.host

            p =
              name: username
              roles: ["host"]

            # Quite obviously this can only be ran by server-admins or users_writer.
            $.couch.signup p, doc.password,

              error: (xhr,status,error) ->
                alert "Host signup failed: #{error}"

              success: cb

      app = @

      Inbox.register 'partner_signup',

        list: (doc) ->
          return "Server #{doc.host}"

        form: (doc) ->
          app.swap host_tpl doc
