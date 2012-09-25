do (jQuery) ->

  $ = jQuery

  make_id = (t,n) -> [t,n].join ':'
  host_username = (n) -> "host@#{n}"
  voicemail_username = (n) -> "voicemail@#{n}"

  container = '#content'

  profile = $(container).data 'profile'

  # FIXME: Retrieve the default value for host_couchdb_uri (public, no password embedded) from some configuration area.

  selector = '#host_record'

  all_apps = [
    # Order is important here due to dependencies.

    # Required on all servers
    "applications/host"
    "applications/monitor"
    # Applications for a manager
    "applications/usercode"
    "applications/provisioning"
    "applications/logging"
    "applications/roles"
    "applications/portal"
    "applications/inbox"
    "public"
    "applications/web"
    "applications/cdrs"
    "applications/locations"
    # Applications for a server running ccnq3-dns
    "applications/dns"
    # Applications for a server running ccnq3-voice
    "applications/freeswitch"
    "applications/opensips"
    "applications/traces"
    # Applications for a server running FreeSwitch
    "applications/cnam-client"
    "applications/voicemail"
    # Applications for a server running OpenSIPS
    "applications/registrant"
    "applications/emergency"
  ]

  log = (text,clear) ->
    console.log text
    if clear
      $('#host_log').html text+"\n"
    else
      $('#host_log').append text+"\n"

  host_tpl = $.compile_template ->

    _apps_description = {
      # On all servers
      "applications/host"           : "Host -- always turn it on"
      "applications/monitor"        : "System monitoring -- recommended"
      # Applications for a manager
      "applications/usercode"       : "(Manager) usercode"
      "applications/provisioning"   : "(Manager) provisioning"
      "applications/roles"          : "(Manager) roles"
      "applications/logging"        : "(Manager) logging"
      "applications/portal"         : "(Manager) portal"
      "applications/inbox"          : "(Manager) inbox"
      "public"                      : "(Manager) public"
      "applications/web"            : "(Manager) web"
      "applications/cdrs"           : "(Aggregate) cdrs"
      "applications/locations"      : "(Aggregate) locations"
      # Applications for a server running ccnq3-dns
      "applications/dns"            : "CCNQ3 DNS (requires ccnq3-dns package)"
      # Applications for a server running ccnq3-voice
      "applications/freeswitch"     : "FreeSwitch (requires ccnq3-voice package)"
      "applications/opensips"       : "OpenSIPS (requires ccqn3-voice package)"
      "applications/traces"         : "Traces (requires ccnq3-traces package)"
      # Applications for a server running FreeSwitch
      "applications/voicemail"      : "Voicemail (requires FreeSwitch)"
      "applications/cnam-client"    : "CNAM client (requires FreeSwitch)"
      # Applications for a server running OpenSIPS
      "applications/registrant"     : "Registrant (requires ccnq3-voice package)"
      "applications/emergency"      : "Emergency Router (requires ccnq3-voice package)"
    }

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
        value: @provisioning?.host_couchdb_uri ? (window.location.protocol + '//' + window.location.hostname + ':5984/provisioning') # FIXME

      textbox
        id:'provisioning.local_couchdb_uri'
        title: 'Local Provisioning database URI (CouchDB)'
        class:'url'
        value: @provisioning?.local_couchdb_uri

      textbox
        id:'logging.host_couchdb_uri'
        title: 'Logging database URI (CouchDB)'
        class:'required url'
        value: @logging?.host_couchdb_uri ? (window.location.protocol + '//' + window.location.hostname + ':5984/logging') # FIXME

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

      for app in @_apps
        checkbox
          id:"selected_applications.#{app}"
          title:_apps_description[app]
          value: @applications? and app in @applications

      if @applications?
        if 'applications/freeswitch' in @applications
          radio
            id:'sip_commands.freeswitch'
            title:'No FreeSwitch changes'
            value:''
            checked:true
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
            title:'No OpenSIPS changes'
            value:''
            checked:true
          radio
            id:'sip_commands.opensips'
            title:'Reload routes'
            value:'reload routes'

        if 'applications/registrant' in @applications
          radio
            id:'sip_commands.registrant'
            title:'No Registrant changes'
            value:''
            checked:true
          radio
            id:'sip_commands.registrant'
            title:'Start Registrant'
            value:'start'
          radio
            id:'sip_commands.registrant'
            title:'Stop Registrant'
            value:'stop'

        if 'applications/emergency' in @applications
          radio
            id:'sip_commands.emergency'
            title:'No Emergency Router changes'
            value:''
            checked:true
          radio
            id:'sip_commands.emergency'
            title:'Start Emergency Router'
            value:'start'
          radio
            id:'sip_commands.emergency'
            title:'Stop Emergency Router'
            value:'stop'

         if 'applications/voicemail' in @applications
          textbox
            id:'voicemail.userdb_base_uri'
            title: 'Voicemail: Base URI for user databases'
            class:'url'
            value: @voicemail?.userdb_base_uri
          textbox
            id:'voicemail.default_language'
            title: 'Voicemail: Default language'
            class:'text'
            value: @voicemail?.default_language
          textbox
            id:'voicemail.number_domain'
            title: 'Voicemail: Number domain (default: "local")'
            class:'url'
            value: @voicemail?.number_domain

      input type:'submit'

    $('form.validate').validate()

  $(document).ready ->

    app = $.sammy container, ->

      model = @createModel 'host'

      rewrite_host_couchdb_uri = (doc,field) ->
        username = host_username doc.host
        password = doc.password

        u = field.host_couchdb_uri.match ///
            ^
            (https?://)
            (?:[^@]*@)?
            (.*)
          ///i

        unless u
          alert 'Invalid provisioning URL'
          return

        field.host_couchdb_uri = u[1] + encodeURIComponent(username) + ':' + encodeURIComponent(password) + '@' + u[2]

      initialize_password = (doc) ->
        ###
          Password creation for host@#{hostname}
        ###
        password = hex_sha1 "a"+Math.random()

        ###
          Save the password so that the "create" method can retrieve it.
          (This isn't more of a security concern than storing it in the
          host_couchdb_uri.)
        ###
        doc.password = password

        rewrite_host_couchdb_uri doc, doc.provisioning
        rewrite_host_couchdb_uri doc, doc.logging

      model.extend
        beforeSave: (doc) ->

          log 'Preparing data'

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
          ###
          if not doc.admin?.system
            doc.provisioning.local_couchdb_uri = 'http://127.0.0.1:5984/provisioning'
          else
            doc.provisioning.local_couchdb_uri ?= doc.provisioning.couchdb_uri

          if doc.selected_applications?["applications/voicemail"]

            add_voicemail doc

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
          if doc.selected_applications?
            previous_apps = doc.applications
            doc.applications = []
            # Add any name that was selected
            doc.applications.push name for name, present of doc.selected_applications when present
            # Keep any name we do not know about.
            doc.applications.push name for name in previous_apps when name not in all_apps
          delete doc.selected_applications

          doc.mailer ?= {}
          doc.mailer ?= sendmail: '/usr/sbin/sendmail'

          if not doc.password?
            initialize_password doc
          else
            rewrite_host_couchdb_uri doc, doc.provisioning
            rewrite_host_couchdb_uri doc, doc.logging

          return doc

      # FIXME: if account creation fails on first attempt, the password for the account
      # and the password for userdb_base_uri are out-of-sync.
      # (In this case the user account needs to be deleted and re-created and userdb_base_uri
      # must be overwritten.)
      # FIXME: grant_rights does not work when the account is first created (by signup),
      # it needs to be called a second time??
      add_voicemail = (doc) ->

        # Username/password for the voicemail application
        username = voicemail_username doc.host
        password = hex_sha1 "a"+Math.random()

        # Update the host record accordingly
        doc.voicemail ?= {}
        # When logged in the profile is normally the user record.
        # doc.voicemail.userdb_base_uri ?= profile.profile?.userdb_base_uri # is missing authentication
        doc.voicemail.userdb_base_uri ?= window.location.protocol + '//' + encodeURIComponent(username) + ':' + encodeURIComponent(password) + '@' + window.location.hostname + ':5984' # FIXME

        # Create the user for the voicemail application
        p =
          name: username

        $.couch.signup p, password,

          error: (status) -> # This isn't what the documentation says, but that's what works.
            if status is 409 # Conflict = user already created
              do grant_rights
            else
              alert "Voicemail signup failed"
              log 'Voicemail user record creation failed.'

          success: grant_rights

        grant_rights = ->
          # Mark the user confirmed.
          $.ajax
            type: 'PUT'
            url: '/ccnq3/roles/admin/grant/'+encodeURIComponent(username)+'/confirmed'
            dataType: 'json'
            success: (data) ->
              if not data.ok
                log data.error ? data.forbidden
                return

              # Grant the user update:user_db: rights
              $.ajax
                type: 'PUT'
                url: '/ccnq3/roles/admin/grant/'+encodeURIComponent(username)+'/update/user_db' # No prefix
                dataType: 'json'
                success: (data) ->
                  if not data.ok
                    log data.error ? data.forbidden
                    return


      create_user = (doc,cb) ->

        ###
          Create the user account record for this host.
          (Hosts are given direct, read-only access to the provisioning
          database so that they can replicate it locally.)
        ###
        username = host_username doc.host
        password = doc.password

        ###
          Only admins may change the "roles" field. So we use
          applications/roles/zappa/admin.coffe as a proxy for
          non-admin users.
          This requires
            update:host:      # The role to be granted
            update:_users:    # Authorization to grant a role
          in "roles" for the requesting user.
        ###

        grant_rights = ->
            # Grant the `host` right
            log "Updating server rights."
            ee = $.ccnq3.admin.host username
            ee.on 'error', (error) ->
              alert 'Updating server rights failed.'
              log "Updating server rights failed: #{error}"
            ee.on 'success', cb

        ###
          Quite obviously this can only be ran by server-admins or update:_users: roles.
        ###
        log "Creating user record for #{username} with password #{password}."

        ee = $.ccnq3.admin.adduser username, password
        ee.on 'error', (error) ->
          alert 'Host signup failed.'
          log "User record creation failed: #{error}"

        ee.on 'success', grant_rights

      @bind 'error.host', (notice) ->
        log "An error occurred: #{notice.error}"

      # Show template (to create new host)
      @get '#/host', ->
        @swap host_tpl {_apps:all_apps}

      @get '#/host/:id', ->
        # Bug in sammy.js? This route gets selected for #/host
        if not @params.id?
          @swap host_tpl {_apps:all_apps}
          return

        @send model.get, @params.id,
          success: (doc) =>
            console.log "Success"
            doc._apps = all_apps
            @swap host_tpl doc
            delete doc._apps
            $(selector).data 'doc', doc
          error: =>
            console.log "Error"
            doc = {}
            @swap host_tpl {_apps:all_apps}
            $(selector).data 'doc', doc

      # Save
      @bind 'save-host', (event) ->

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
                create_user doc, push
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
          log '', true
          @trigger 'save-host'
        else
          log 'Please check your data.', true

        return

      Inbox.register 'host',

        list: (doc) ->
          return "Server #{doc.host}"

        form: (doc) ->
          id = encodeURIComponent make_id 'host', doc.host
          uri = doc.provisioning.host_couchdb_uri + '/' + id
          """
            <p><a href="#/host/#{id}">Edit</a></p>
            <p>Bootstrap: Install the <tt>ccnq3-client</tt> package on
            "#{doc.host}" with the following URI:</p>
            <pre>
            #{uri}
            </pre>
          """
