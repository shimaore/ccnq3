# aggregate.coffee
# (c) 2012 Stephane Alnet
# License: AGPL3+

pico = require 'pico'

replicate = (config) ->

  # Replicate the local "location" database
  source_uri = config.opensips_proxy.usrloc_uri
  # into the global one
  target_uri = config.opensips_proxy.usrloc_aggregate_uri

  pico.replicate source_uri, target_uri, config.replicate_interval

module.exports = replicate
