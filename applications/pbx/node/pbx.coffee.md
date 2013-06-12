PBX
===

Usage
-----

This application is meant to be used inside a `sip_profile` that uses the `client-sbc` model, with `profile_type` set to `france-pbx` (or a modified version of that profile). Since this is an Event Socket server, use "send call to socket".

Dependencies
------------

    esl = require 'esl'
    ccnq3 = require 'ccnq3'
    supercouch = require 'supercouch'

Defaults
--------

    sounds_dir = '/usr/share/freeswitch/sounds'
    default_nighttime_on_message  = "#{sounds_dir}/transfer-activated.wav"
    default_nighttime_off_message = "#{sounds_dir}/transfer-deactivated.wav"
    default_confirm_message = "#{sounds_dir}/confirm.wav"
    default_confirm_key = "1"

Server
------

    ccnq3.config (config)->

      nighttime_on_message = config.pbx?.nighttime_on_message ? default_nighttime_on_message
      nighttime_off_message = config.pbx?.nighttime_off_message ? default_nighttime_off_message
      confirm_message = config.pbx?.confirm_message ? default_confirm_message
      confirm_key = config.pbx?.confirm_key ? default_confirm_key

The server is an `esl` server.

      server = esl.server (call) ->

        direction = call.body.variable_ccnq_direction

        switch direction

Ingress processing
------------------

          when 'ingress'

For ingress we have the `local_number` as `destination_number`.

            user = call.body.destination_number

The `number_domain` must be guessed from the configured value for our profile.

            profile = call.body.variable_ccnq_profile
            sip_profile = config.sip_profiles[profile]
            number_domain = sip_profile.number_domain

            egress_target = sip_profile.egress_target
            ingress_target = sip_profile.ingress_target

            retrieve_data( user, number_domain )
            .then (data) ->

              thread_variables = {}

Select the ringback music based on `pbx.ringback`.

              if data.pbx.ringback
                thread_variables.ringback = "local_stream://ringback/#{data.pbx.ringback}"

Also set the on-hold music based on `pbx.music`.

              if data.pbx.music
                thread_variables.transfer_ringback = "local_stream://music/#{data.pbx.music}"
              else
                thread_variables.transfer_ringback = "silence"

The `pbx_settings.night` field controls whether `pbx.nighttime_rules` or `pbx.daytime_rules` is used.

              rules = if data.pbx_settings.night
                        data.pbx.nighttime_rules
                      else
                        data.pbx.daytime_rules

The rule-set is mapped to a FreeSwitch `bridge` dialing rule.

              destinations = rules.map (x) ->

Each original destination needs to be mapped to a URI.

                destination = null

The specifications say the original destination may be either:

* a sip URI where to send the call (similar to `cfa`, `cfb`, etc.);

                if x.destination.match /^sip/
                  destination = x.destination

* "voicemail" to use the `voicemail` field;

                if x.destination is 'voicemail'
                  destination = data.pbx.voicemail

* "extension foo" to use the "foo" `short_numbers` field;

                if m = x.destination.match /^extension (.*)$/
                  destination = "sip:#{data.pbx.short_numbers[m[1]]}@#{ingress_target}"

                if destination?
                  destionation = "sofia/egress-#{profile}/#{destination}"

* or some number to send the call to the specified (external) number.

                else
                  destination = "sofia/ingress-#{profile}/sip:#{x.destination}@#{egress_target}"

Regarding per-leg parameters (inside rule-set entries):

                leg_variables = {}

* `delay` is the delay in seconds before this options is activated;

                if x.delay > 0
                  leg_variables.leg_delay_start = x.delay

* when `confirm` is true, the called must press a digit to confirm the call is accepted.

                if x.confirm
                  leg_variables.group_confirm_file = confirm_message
                  leg_variables.group_confirm_key = confirm_key

For each leg we concatenate the per-leg options with the destination,

                '[' + object_param(leg_variables) + ']' + destination

while we concatenate the thread-level variables with the legs.

              args = '{' + object_param(thread_variables) + '}' + destinations.join(',')

Then we send the call(s) out.

              call.command 'bridge', args

Eventually the `bridge` command completes: cleanup and hangup the call.

            .then (call) ->
              call.hangup()

Egress processing
-----------------

          when 'egress'

A special (local) outbound route is created and assigned to the numbers in a PBX so that they get special treatment.
This will allow us to control more finely some features (such as short numbers).

For egress we have the `local_number` as `caller_id_number`.

            user = call.body.caller_id_number

The `number_domain` is retrieved from the `X-CCNQ3-Number-Domain` SIP header.

            number_domain = call.body['sip_h_X-CCNQ3-Number-Domain']
            destination = call.body.destination_number

            retrieve_data( user, number_domain )
            .then (data) ->

If the destination is a short number, translate it into some actionable item.
Note that the translations we used to send an incoming call (i.e. applying the night- or day-time rulesets) do not apply here. If an internal number is called it is called directly. (FIXME: Maybe this should at least forward to voicemail?)

              if m = destination.match /^extension (.*)$/
                destination = data.pbx.short_numbers[m[1]]

The definitions of short numbers might include:

                switch destination

* "voicemail" to use the `voicemail` field;

                  when "voicemail"
                    args = "sofia/egress-#{profile}/#{data.pbx.voicemail}"
                    call.command 'bridge', args

* "nighttime_on" to start using the night-time ruleset;

                  when "nighttime_on"
                    set_nighttime(data,true)
                    .then ->
                      call.command 'playback', nighttime_on_message

* "nightime_off" to start using the day-time ruleset;

                  when "nighttime_off"
                    set_nighttime(data,false)
                    .then ->
                      call.command 'playback', nighttime_off_message

* or some (internal) local number.

                  else
                    args = "sofia/egress-#{profile}/sip:#{destination}@#{ingress_target}"
                    call.command 'bridge', args

If the destination is not a short number, simply bridge it.

              else

                args = "sofia/ingress-#{profile}/sip:#{destination}@#{egress_target}"
                call.command 'bridge', args

When the bridge completes, cleanup and hangup the call.

            .then (call) ->
              call.hangup()

Invalid direction
-----------------

In case of invalid direction (neither ingress nor egress), hangup the call. (Some kind of internal error occurred.)
FIXME play some error indication.
FIXME report this as an error in some logging system.

          else
            call.command 'hangup'

Start the server
----------------

      server.listen config.pbx?.port ? 7000  # FIXME default_socket_port

Tools
=====

The tools will need access to the `provisioning` database (more precisely, its local replica).

      provisioning = ccnq3.db.supercouch config.provisioning.host_couchdb_uri

They will also need access to the user-database associated with the number.

      user_base = config.pbx.userdb_base_uri or config.voicemail.userdb_base_uri

### Retrieve data (local number record and user-database pbx-setting record) associated with given local number ###

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

The `pbx_settings` record will be available as the `pbx_settings` field of the promise's value.

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

Save the record back.

          db
          .update(res)
          .end (err2,res2) ->
            if err2
              deferred.reject err
            else
              deferres.resolve res2

Return the promise.

        deferred.promise

### Convert an object (hash) to a FreeSwitch list of paramaters ###

    object_param = (o) ->
      ([k,v].join('=') for k,v of o).join(',')
