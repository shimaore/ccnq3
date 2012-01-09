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
        title:'Host (FQDN)'
        class:'required text'
        value:@host

      textbox
        id:'provisioning.host_couchdb_uri'
        title: 'Provisioning database URI (CouchDB)'
        class:'required url'
        value: @provisioning?.host_couchdb_uri ? (window.location.protocol + '//' + window.location.hostname + ':5984/provisioning')

      textbox
        id:'interfaces.primary.ipv4'
        title:'Primary IPv4'
        class:'ipv4'
        value:@interfaces?.primary?.ipv4

      textbox
        id:'interfaces.primary.ipv6'
        title:'Primary IPv6'
        class:'ipv6'
        value:@interfaces?.primary?.ipv6

      textbox
        id:'interfaces.private.ipv4'
        title:'Secondary/private IPv4'
        class:'ipv4'
        value:@interfaces?.private?.ipv4

      textbox
        id:'interfaces.private.ipv6'
        title:'Secondary/private IPv6'
        class:'ipv6'
        value:@interfaces?.private?.ipv6

      textbox
        id:'sip_domain_name'
        title:'SIP domain / cluster'
        class:'text'
        value:@sip_domain_name

      if 'applications/freeswitch' in @applications
        radio
          id:'sip_commands.freeswitch'
          title:'No FreeSwitch operation'
          value:''
        radio
          id:'sip_commands.freeswitch'
          title:'Reload Sofia (to add a new profile -- will drop calls)'
          value:'reload sofia'
        radio
          id:'sip_commands.freeswitch'
          title:'Pause inbound calls'
          value:'pause inbound'
        radio
          id:'sip_commands.freeswitch'
          title:'Pause outbound calls'
          value:'pause outbound'
        radio
          id:'sip_commands.freeswitch'
          title:'Resume inbound calls'
          value:'resume inbound'
        radio
          id:'sip_commands.freeswitch'
          title:'Resume outbound calls'
          value:'resume outbound'

      if 'applications/opensips' in @applications
        radio
          id:'sip_commands.opensips'
          title:'No OpenSIPS operation'
          value:''
        radio
          id:'sip_commands.opensips'
          title:'Reload routes'
          value:'reload routes'

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

      @get '#/host/:id', ->
        # Bug in sammy.js? This route gets selected for #/host
        if not @params.id?
          @swap host_tpl {}
          return

        @send model.get, @params.id,
          success: (doc) =>
            console.log "Success"
            @swap host_tpl doc
            $('#host_record').data 'doc', doc
          error: =>
            console.log "Error"
            doc = {}
            @swap host_tpl doc
            $('#host_record').data 'doc', doc

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
              model.get resp.id, (doc)->
                $(selector).data 'doc', doc
                do push
        else
          console.log 'Creating host'
          # No @send here, apparently
          model.create doc,
            success: (resp) ->
              model.get resp.id, (doc) ->
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
          id = encodeURIComponent make_id 'host', doc.host
          uri = doc.provisioning.host_couchdb_uri + '/' + id
          """
            <p><a href="#/host/#{id}">Edit</a></p>
            <p>Provisioning URI = <a href="#{uri}">#{uri}</a></p>
            <p>Bootstrap: Run on host "#{doc.host}" as root:</p>
            <pre>
              cd /opt/ccnq3/src && ./bootstrap-local.sh '#{uri}'
            </pre>
          """
