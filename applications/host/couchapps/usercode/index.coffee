do (jQuery) ->

  $ = jQuery

  make_id = (t,n) -> [t,n].join ':'
  host_username = (n) -> "host@#{n}"

  container = '#content'

  # profile = $(container).data 'profile'
  # model = $(container).data 'model'

  # FIXME: Retrieve the default value for host_couchdb_uri (public, no password embedded) from some configuration area.

  selector = '#host_record'

  host_tpl = $.compile_template ->

    form id:'host_record', method:'post', action:'#/host', class:'validate', ->

      div id:'host_log'

      textbox
        id:'host'
        title:'Host'
        class:'required text'
        value:@host

      textbox
        id:'provisioning.host_couchdb_uri'
        title: 'Provisioning database URI'
        class:'required url'
        value: @provisioning?.host_couchdb_uri ? (window.location.protocol + '//' + window.location.host + '/provisioning')

      input type:'submit'

    $('form.validate').validate()

  $(document).ready ->

    app = $.sammy container, ->

      model = @createModel 'host'

      initialize_password = (doc) ->
        ###
          Password creation for host@#{hostname}
        ###
        username = host_username doc.host
        password = hex_sha1 "a"+Math.random()

        u = doc.provisioning.host_couchdb_uri.match ///
            ^
            (https?://)
            (?:[^@]*@)?
            (.*)
          ///i

        unless u
          alert 'Invalid provisioning URL'
          return

        doc.provisioning.host_couchdb_uri = u[1] + encodeURIComponent(username) + ':' + encodeURIComponent(password) + '@' + u[2]

        ###
          Save the password so that the "create" method can retrieve it.
          (This isn't more of a security concern than storing it in the
          host_couchdb_uri.)
        ###
        doc.password = password

      model.extend
        beforeSave: (doc) ->

          $('#host_log').html 'Preparing data'

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
            local_couchdb_uri is local for any non-manager host.
            Since manager hosts are bootstrapped using a script, not this interface,
            assume we are dealing with a non-manager host.
          ###
          doc.provisioning.local_couchdb_uri = 'http://127.0.0.1:5984/provisioning'

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

          if not doc.password?
            initialize_password doc

          return doc

      create_user = (doc,cb) ->

        ###
          Create the user account record for this host.
          (Hosts are given direct, read-only access to the provisioning
          database so that they can replicate it locally.)
        ###
        username = host_username doc.host
        password = doc.password

        p =
          name: username

        ###
          Quite obviously this can only be ran by server-admins or users_writer.
        ###
        $('#host_log').html "Creating user record for #{username} with password #{password}."
        console.log "Creating user record for #{username} with password #{password}."

        $.couch.signup p, password,

          error: (xhr,status,error) ->
            alert "Host signup failed: #{error}"
            $('#host_log').html 'User record creation failed.'

          ###
            Only admins may change the "roles" field. So we use
            applications/roles/zappa/admin.coffe as a proxy for
            non-admin users.
            This requires
              update:host:      # The role to be granted
              update:_users:    # Authorization to grant a role
            in "roles" for the requesting user.
          ###
          success: ->
            $.ajax
              type: 'PUT'
              url: '/roles/admin/grant/'+encodeURI(username)+'/host'
              dataType: 'json'
              success: (data) ->
                if data.ok
                  do cb
                else
                  $('#host_log').html data.error ? data.forbidden

      @bind 'error.host', (notice) ->
        console.log "Model error: #{notice.error}"
        $('#log').append "An error occurred: #{notice.error}"

      # Show template (to create new host)
      @get '#/host', ->
        @swap host_tpl {}

      # Save
      @bind 'save-doc', (event) ->

        doc = $(selector).data('doc') ? {}
        $.extend doc, $(selector).toDeepJson()

        push = ->
          $.ccnq3.push_document 'provisioning'

        if doc._rev?
          console.log 'Updating host'
          # No @send here, apparently
          model.update doc._id, doc,
            success: (resp) ->
              model.get resp._id (doc)->
                $(selector).data 'doc', doc
                do push
        else
          console.log 'Creating host'
          # No @send here, apparently
          model.create doc,
            success: (resp) ->
              model.get resp._id, (doc) ->
                $(selector).data 'doc', doc
                create_user doc, push

      @post '#/host', ->
        form_is_valid = $(selector).valid()

        if form_is_valid
          $('#host_log').html ''
          @trigger 'save-doc'
        else
          $('#host_log').html 'Please check your data.'

        return

      Inbox.register 'host',

        list: (doc) ->
          return "Server #{doc.host}"

        form: (doc) ->
          # FIXME $(selector).data 'doc', doc
          uri = doc.provisioning.host_coucdh_uri + '/' + encodeURIComponent doc.host
          """
            <p>Provisioning URI = <a href="#{uri}">#{uri}</a></p>
            <pre>
              # Run on host "#{doc.host}"
              cd /opt/ccnq3/src && sudo ./bootstrap-local.sh '#{uri}'
            </pre>
          """ + host_tpl doc
