@include = ->

  pico = require 'pico'
  uuid = require 'uuid'
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
        target_db_uri = config.voicemail.userdb_base_uri + '/' + user_database
        target_db = pico target_db_uri, @req.user, @req.pass

        # Create the database
        target_db.create =>

          # We do not check the return code:
          # it's OK if the database already exists.

          # Create the voicemail_settings record
          target_db.get 'voicemail_settings', (e,r,vm_settings) =>
            if e? or not vm_settings?
              vm_settings = vm
              vm_settings._id = 'voicemail_settings'
            else
              vm_settings[k] = v for k,v of vm when not k.match /^_/
            target_db.put vm_settings, (e) =>
              if e? then return @failure error:e, when:"update voicemail_settings for #{user_database}"
              @success {user_database}

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
