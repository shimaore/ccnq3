@include = ->

  pico = require 'pico'
  uuid = require 'node-uuid'
  config = null
  require('ccnq3').config (c) -> config = c

  @put '/_ccnq3/voicemail/:number@:number_domain', ->

    if not @req.user?
      return @failure error:"Not authorized (probably a bug)"

    vm = @body

    # Locate number record

    # Note: couchdb_uri is only present on a manager host.
    provisioning = pico config.provisioning.couchdb_uri, @req.user, @req.pass

    id = "number:#{@params.number}@#{@params.number_domain}"
    provisioning.get id, (e,r,local_number) =>
      if e? then return @failure error:e, when:"retrieving #{id}"

      step2 = =>
        if not user_database.match /^u[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/
          return @failure error:"Invalid db name #{user_database}"
        target_db_uri = config.users.userdb_base_uri + '/' + user_database
        target_db = pico target_db_uri, @req.user, @req.pass

        users_db = pico config.users.couchdb_uri, @req.user, @req.pass

        # Use the view to gather information about the requested user database.
        users_db.view 'replicate', 'userdb', qs: {key:JSON.stringify user_database}, (e,r,b) =>
          if e? then return @failure error:e, when:"view users for #{user_database}"

          readers_names = (row.value for row in b.rows)

          # Create the database
          target_db.create =>

            # We do not check the return code:
            # it's OK if the database already exists.

            # Restrict number of available past revisions.
            target_db.request.put '_revs_limit',body:"10", (e,r,b) =>
              if e? then return @failure error:e, when:"set revs_limit for #{user_database}"

              # Make sure the users can access it.
              target_db.request.get '_security', json:true, (e,r,b) =>
                if e? then return @failure error:e, when:"retrieve security object for #{user_database}"

                b.readers ?= {}

                b.readers.names = readers_names
                b.readers.roles = [ 'update:user_db:' ] # e.g. voicemail

                target_db.request.put '_security', json:b, (e,r,b) =>
                  if e? then return @failure error:e, when:"update security object for #{user_database}"

                  # Create the voicemail_settings record
                  target_db.get 'voicemail_settings', (e,r,vm_settings) =>
                    if e? or not vm_settings?
                      vm_settings = vm
                      vm_settings._id = 'voicemail_settings'
                    else
                      vm_settings[k] = v for k,v of vm when not k.match /^_/
                    target_db.put vm_settings, (e) =>
                      if e? then return @failure error:e, when:"update voicemail_settings for #{user_database}"
                      @success
                        ok:true

       # Typically user_database will be a UUID
      user_database = local_number.user_database
      if not user_database?
        user_database = 'u'+uuid.v4()
        local_number.user_database = user_database
        provisioning.put local_number, (e) =>
          if e? then return @failure error:e, when:"local_number #{id}"
          do step2
      else
        do step2
