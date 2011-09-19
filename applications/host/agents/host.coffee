#!/usr/bin/env coffee
###
(c) 2010 Stephane Alnet
Released under the AGPL3 license
###

# The host records in the provisioning database may contain
# so-called "change_handlers", whose job it is to maintain
# invariants inside the given host. ("PUT/POST/DELETE"-type
# of operations.)

ccnq3_logger  = require 'ccnq3_logger'
vm            = require 'vm'

run_handler = (code,old_config,new_config) ->

  result =
    hostname: hostname
    code: code
    start: Date.now()

  try
    # Similarly to CouchDB, a runnable must return a function.
    f = vm.runInNewContext(code)
    # The function receives three arguments. old_config and new_config
    # should not be modified; result can be used to report errors, etc.
    f(result,old_config,new_config)
  catch error
    result.error = error
  finally
    result.end = Date.now()
    result.freemem = os.freemem()
    result.loadavg = os.loadavg()

    ccnq3_logger.log result

# Main

util = require 'util'
cdb_changes = require 'cdb_changes'

require('ccnq3_config').get (config) ->
  options =
    uri: config.provisioning.couchdb_uri
    filter_name: "host/hostname"
    filter_params:
      hostname: config.host

  new_config = config

  cdb_changes.monitor options, (p) ->
    if p.error? then return util.log(p.error)

    [old_config,new_config] = [new_config,p]

    for handler in new_config.change_handlers
      run_handler handler, old_config, new_config
