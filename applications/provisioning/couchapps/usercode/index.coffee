
do(jQuery,Sammy) ->

  $ = jQuery

  make_id = (t,n) -> [t,n].join ':'

  container = '#content'

  model = $(container).data 'model'

  model.require "provisioning/endpoint.js"
  model.require "provisioning/number.js"
  model.require "provisioning/rule.js"
