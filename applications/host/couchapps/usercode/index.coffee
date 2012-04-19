do (jQuery) ->

  $ = jQuery

  container = '#content'

  model = $(container).data 'model'

  model.require "host/host.js"
  model.require "host/traces.js"
