FS = require 'esl'

fs_command = (cmd,cb) ->
  FS.client password:'CCNQ', (call) ->
    response = null
    outcome = call.sequence [
      -> @api cmd
      ->
        response = @body
        @
      -> @exit()
    ]
    outcome.then ->
      cb? null, response
    outcome.fail (reason) ->
      cb? reason
  .connect 8021, '127.0.0.1'

process_changes = (commands,cb) ->

  for profile_name, command of commands when profile_name.match /^(ingress-|egress-)/
    switch command
      when 'start'
        fs_command "sofia profile #{profile_name} start", cb
      when 'restart'
        fs_command "sofia profile #{profile_name} restart reloadxml", cb
      when 'stop'
        fs_command "sofia profile #{profile_name} stop", cb

  # Following commands are not module-specific.
  if commands.freeswitch?
    switch commands.freeswitch
      when 'reload sofia'
        fs_command "unload mod_sofia", ->
          fs_command "load mod_sofia", cb
      when 'pause inbound'
        fs_command "fsctl pause inbound", cb
      when 'pause outbound'
        fs_command "fsctl pause outbound", cb
      when 'resume inbound'
        fs_command "fsctl resume inbound", cb
      when 'resume outbound'
        fs_command "fsctl resume outbound", cb
      when 'restart elegant'
        fs_command "fsctl restart elegant", cb
      when 'restart asap'
        fs_command "fsctl restart asap", cb

      when 'calls count'
        fs_command "show calls count", cb

module.exports = process_changes
