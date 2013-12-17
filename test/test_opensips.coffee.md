    should = require 'should'

    exec = (command,args,next) ->
      run = (require 'child_process').spawn command, args
      run.stdout.pipe process.stdout
      run.stderr.pipe process.stderr
      run.on 'error', (e) ->
        next?()
        throw e
      run.on 'exit', (code,signal) ->
        next?()
        (code).should.equal 0, "#{command} #{args.join ' '} -> died with code = #{code}, signal = #{signal}"

    @check_config = (cfg_path,next) ->
      console.log "Checking configuration file #{cfg_path}"
      exec '/usr/sbin/opensips', ['-C', '-D', '-E', '-f', cfg_path], next

    @run = (cfg_path,next) ->
      console.log "Running OpenSIPS with #{cfg_path}"
      exec '/usr/sbin/opensips', ['-D', '-E', '-f', cfg_path], next
