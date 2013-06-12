PBX
===

Profile: use "send call to socket" in "client-sbc" model with `profile_type` set to "france-pbx".

    esl = require 'esl'
    ccnq3 = require 'ccnq3'

    object_param = (o) ->
      ([k,v].join('=') for k,v of o).join(',')

    nighttime_on_message  = '/usr/share/freeswitch/sounds/transfer-est-actif.wav'
    nighttime_off_message = '/usr/share/freeswitch/sounds/transfer-est-inactif.wav'

    ccnq3.config (config)->

      server = esl.server (call) ->

        direction = call.body.variable_ccnq_direction

        switch direction

Ingress processing
------------------

For ingress we have the `local_number` as `destination_number`.
The `number_domain` must be guessed from the configured value for our profile.

          when 'ingress'
            user = call.body.destination_number
            profile = call.body.variable_ccnq_profile
            sip_profile = config.sip_profiles[profile]
            number_domain = sip_profile.number_domain
            egress_target = sip_profile.egress_target
            ingress_target = sip_profile.ingress_target

            retrieve_data( user, number_domain )
            .then( (data) ->

              thread_variables = {}

Choose `pbx.nighttime_rules` or `pbx.daytime_rules` based on the `pbx_settings.night` field.

              if data.pbx.ringback
                thread_variables.ringback = "local_stream://ringback/#{data.pbx.ringback}"

Select the ringback music based on `pbx.ringback`; also set the on-hold music based on `pbx.music`.

              if data.pbx.music
                thread_variables.transfer_ringback = "local_stream://music/#{data.pbx.music}"
              else
                thread_variables.transfer_ringback = "silence"

Build the `bridge` statement using the data from the `local_number`'s `user_database` `night` field in `pbx_setting`, and the `local_number`'s `pbx` data.

              rules = if data.pbx_settings.night
                        data.pbx.nighttime_rules
                      else
                        data.pbx.daytime_rules

              destinations = rules.map (x) ->

Each destination needs to be mapped to a URI.

                destination = null

The specifications say: either:

* sip URI where to send the call (similar to `cfa` etc)

                if x.destination.match /^sip/
                  destination = x.destination

* "voicemail" to use the `voicemail` field

                if x.destination is 'voicemail'
                  destination = data.pbx.voicemail

* "extension foo" to use the "foo" `short_numbers` field

                if m = x.destination.match /^extension (.*)$/
                  destination = "sip:#{data.pbx.short_numbers[m[1]]}@#{ingress_target}"

                if destination?
                  destionation = "sofia/egress-#{profile}/#{destination}"

* some number to send the call to the specified (external) number

                else
                  destination = "sofia/ingress-#{profile}/sip:#{x.destination}@#{egress_target}"

Regarding per-leg parameters (inside rule-set entries):

                leg_variables = {}

* delay: delay in seconds before this options is activated.

                if x.delay > 0
                  leg_variables.leg_delay_start = x.delay

* confirm: if true, the called must press a digit to confirm call is accepted.

                if x.confirm
                  leg_variables.group_confirm_file = config.pbx.group_confirm_file
                  leg_variables.group_confirm_key = config.pbx.group_confirm_key

                '[' + object_param(leg_variables) + ']' + destination

              args = '{' + object_param(thread_variables) + '}' + destinations.join(',')

              call.command 'bridge', args

            ).then( (call) ->

The `bridge` command completed: cleanup and hangup the call.

              call.hangup()

            )

Egress processing
-----------------

A special route is created and assigned to the numbers in a PBX so that they get special treatment.
This will allow us to control more finally some features (such as call )

For egress we have the `local_number` as `caller_id_number`.
The `number_domain` is retrieved from the `X-CCNQ3-Number-Domain` header.

          when 'egress'
            user = call.body.caller_id_number
            number_domain = call.body['sip_h_X-CCNQ3-Number-Domain']
            destination = call.body.destination_number

            retrieve_data user, number_domain
            .then( (data) ->

If the destination is a short number, translate it into some actionable item.

              if m = destination.match /^extension (.*)$/
                destination = data.pbx.short_numbers[m[1]]

                switch destination
                  when "voicemail"
                    args = "sofia/egress-#{profile}/#{data.pbx.voicemail}"
                    call.command 'bridge', args
                  when "nighttime_on"
                    set_nighttime(data,true)
                    .then ->
                      call.command 'playfile', # FIXME
                  when "nighttime_off"
                    set_nighttime(data,false)
                    .then ->
                      call.command 'playfile', # FIXME
                  else
                    args = "sofia/egress-#{profile}/sip:#{destination}@#{ingress_target}"
                    call.command 'bridge', args

If the destination is not a short number, simply bridge it.

              else

                args = "sofia/ingress-#{profile}/sip:#{destination}@#{egress_target}"
                call.command 'bridge', args

            ).then( (call) ->

Bridge completed, cleanup and handup the call.

              call.hangup()

            )

In case of invalid direction (neither ingress nor egress), hangup the call.

          else
            # FIXME say something
            call.command 'hangup'

Start the server
----------------

      server.listen config.pbx?.port ? 7000  # FIXME default_socket_port


Tools
=====

      supercouch = require 'supercouch'

Retrieve all data for a given local number (as a promise).

      provisioning = ccnq3.db.supercouch config.provisioning.host_couchdb_uri
      user_base = config.pbx.userdb_base_uri or config.voicemail.userdb_base_uri

### Retrieve data (local number record and user-database pbx-setting record) for a given local number ###

      retrieve_data = (number,number_domain) ->
        deferred = Q.defer()

First retrieve the `local_number`'s provisioning record.

        provisioning
        .get ccnq3.make_id 'number', "#{number}@#{number_domain}"
        .end (err,res) ->

          if err
            deferred.reject err

Then load the `pbx_settings` record in the `user_database`.

          supercouch(user_base)
          .db(res.user_database)
          .get( 'pbx_settings' )
          .end (err2,res2) ->
            if err2
              deferred.reject err2

            res.pbx_settings = res2 ? {}
            deferred.resolve res

Return the promise.

        deferred.promise

### Update the night-time status in a given user-database ###

      set_nighttime = (data,night) ->
        deferred = Q.defer()

        db = supercouch(user_base).db data.user_database

Retrieve the current `pbx_settings` record.

        db
        .get('pbx_settings')
        .end (err,res) ->
          if err
            deferred.reject err

Update the value.

          res.night = night

Save it back.

          db
          .update(res)
          .end (err2,res2) ->
            if err2
              deferred.reject err
            else
              deferres.resolve res2

Return the promise.

        deferred.promise
