###
(c) 2010 Stephane Alnet
Released under the AGPL3 license
###

using 'querystring'

require('ccnq3_config').get (config)->

    def config: config

    cdb = require 'cdb'

    def prepaid_cdb: cdb.new config.prepaid.couchdb_uri


    get '/:account': ->
      # Query the view
      prepaid_cdb.exists (it_does) =>
        if not it_does
          throw it_does

        prepaid_cdb.get @account, (r) ->
          if r.error?
            throw r.error
          the_interval = r.interval

          account_key = "\"#{@account}\""
          options =
            uri: "/_design/prepaid/_view/current?group=true&key=#{querystring.escape(account_key)}"
          prepaid_cdb.req options, (r) ->
            if r.error?
              throw r.error
            send { interval: the_interval, value: r.value }

    post '/:account': ->
      # PUT a new record with account and interval
      prepaid_cdb.exists (it_does) =>
        if not it_does
          throw it_does

        rec =
          type: 'interval_record'
          account: @account
          intervals: - @intervals

        db.put rec, (r) ->
          if r.error?
            throw r.error
          send { ok: true }
