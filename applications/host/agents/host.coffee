#!/usr/bin/env coffee
###
(c) 2010 Stephane Alnet
Released under the GPL3 license
###

# Local configuration file

fs = require 'fs'
config_location = 'host.config'
config = JSON.parse(fs.readFileSync(config_location, 'utf8'))

util = require 'util'
vm   = require 'vm'

cdb         = require process.cwd()+'/../lib/cdb.coffee'
cdb_changes = require process.cwd()+'/../lib/cdb_changes.coffee'

log_cdb = cdb.new config.log_couchdb_uri

filter_name = "host/hostname"
hostname = os.hostname()
filter_params =
  hostname: hostname

cdb_changes.monitor config.provisioning_couchdb_uri, filter_name, filter_params, (p) ->
  if p.error?
    return util.log(p.error)

  runnables = p.runnables
  delete p.runnables

  cdb.put p, (r) ->
    if r.error then return util.log(r.error)

    for code in runnables
      do (code) ->
        result =
          type: 'runnable_result'
          hostname: hostname
          code: code
          start: Date.now()
        try
          vm.runInNewContext(code,{host:p})
        catch error
          result.error = error
        finally
          result.end = Date.now()
          result.freemem = os.freemem()
          result.loadavg = os.loadavg()

          log_cdb.post result, (s)
            if r.error then return util.log(r.error)
