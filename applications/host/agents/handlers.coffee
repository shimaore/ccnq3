#!/usr/bin/env coffee
###
(c) 2010 Stephane Alnet
Released under the AGPL3 license
###

util = require 'util'

handler = {}

javascript_handler = (code,old_config,new_config) ->
  vm = require 'vm'

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

    util.log util.inspect result

coffeescript_handler = (code,old_config,new_config) ->
  CoffeeScript = require 'coffee-script'

  code = CoffeeScript.compile code
  javascript_handler code, old_config, new_config

exec_handler = (code,old_config,new_config) ->
  exec = require('child_process').exec
  child = exec code, (error,stdout,stderr) ->
    util.log "stdout: #{stdout}"
    util.log "stderr: #{stderr}"
    if error?
      util.log "error: #{error}"
  child.stdin.write new_config
  child.stdin.end()

handler['application/javascript'] = javascript_handler
handler['application/coffeescript'] = coffeescript_handler
handler['application/shell'] = exec_handler

module.exports = handler
