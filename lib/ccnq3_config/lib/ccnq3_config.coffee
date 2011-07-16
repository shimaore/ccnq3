
fs = require 'fs'

# XXX Test: is this going to use ccnq3_config's config_file, or the package, or the apps..?
config_location = process.env.npm_package_config_config_file # or '/etc/ccnq3/host.json'

exports.location = config_location

exports.config = JSON.parse fs.readFileSync config_location, 'utf8'

exports.update = (content) ->
  fs.writeFileSync config_location, JSON.stringify content

