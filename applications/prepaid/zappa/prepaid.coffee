###
(c) 2010 Stephane Alnet
Released under the AGPL3 license
###

querystring = require 'querystring'
cdb = require 'cdb'

require('ccnq3_config').get (config)->

  prepaid_cdb = cdb.new config.prepaid.couchdb_uri

  prepaid_cdb.exists (it_does) =>
    if not it_does
      throw it_does

    zappa = require 'zappa'
    zappa.run config.prepaid.port, config.prepaid.hostname, ->

      @use 'bodyParser'

      @get '/:account': ->
        # Query the view
        prepaid_cdb.get @params.account, (r) =>
          if r.error?
            throw r.error
          the_interval = r.interval

          account_key = "\"#{@params.account}\""
          options =
            uri: "/_design/prepaid/_view/current?group=true&key=#{querystring.escape(account_key)}"
          prepaid_cdb.req options, (r) =>
            if r.error?
              throw r.error
            @send { interval: the_interval, value: r.value }

      @post '/:account': ->
        # PUT a new record with account and interval
        rec =
          type: 'interval_record'
          account: @params.account
          intervals: - @body.intervals

        db.put rec, (r) =>
          if r.error?
            throw r.error
          @send { ok: true }
