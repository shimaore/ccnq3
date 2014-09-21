@include = ->

  ccnq3 = require 'ccnq3'
  ccnq3.config (c) -> config = c

  @put '/_ccnq3/commands', ->

    if not @req.user?
      return @failure error:"Not authorized (probably a bug)"

    request = @body

    try
      ccnq3.command.send 'couch_daemon', request, (r) =>
        @success r
    catch e
      @failure error:e
    return
