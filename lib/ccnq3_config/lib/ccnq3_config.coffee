
fs = require 'fs'
util = require 'util'

# XXX Test: is this going to use ccnq3_config's config_file, or the package, or the apps..?
config_location = process.env.npm_package_config_config_file

if not config_location?
  util.log "NPM did not provide a config_file parameter, process.env = #{ util.inspect process.env }"
  config_location = '/etc/ccnq3/host.json'

util.log "Using #{config_location} as configuration file."

exports.location = config_location

exports.config = JSON.parse fs.readFileSync config_location, 'utf8'

exports.update = (content) ->
  fs.writeFileSync config_location, JSON.stringify content

