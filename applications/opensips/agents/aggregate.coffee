# aggregate.coffee
# (c) 2012 Stephane Alnet
# License: AGPL3+

pico = require 'pico'

replicate = (config) ->

  return unless config.opensips_proxy?.usrloc_aggregate_uri?

  # Replicate the local "location" database
  source_uri = config.opensips_proxy?.usrloc_uri ? 'http://127.0.0.1:5984/location'
  # into the global one
  target_uri = config.opensips_proxy?.usrloc_aggregate_uri

  pico.replicate source_uri, target_uri, config.replicate_interval

module.exports = replicate
