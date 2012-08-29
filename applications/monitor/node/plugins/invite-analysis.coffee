@name = 'invite-analysis'
@description = 'INVITE analysis'

@get = (cb) ->

  a = require '../../../traces/agents/invite-analysis'
  a.invite_analysis 5, cb
