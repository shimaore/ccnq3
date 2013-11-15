Check whether generic opensips configurations will compile OK.

Requirements:

  aptitude install opensips opensips-dbhttp-module opensips-json-module opensips-b2bua-module

    fs = require 'fs'
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

    compiler = require '../common/opensips/compiler'

    check_config_opensips = (cfg_path,next) ->
      console.log "Checking configuration file #{cfg_path}"
      exec '/usr/sbin/opensips', ['-C', '-D', '-E', '-f', cfg_path], next

    run_opensips = (cfg_path,next) ->
      console.log "Running OpenSIPS with #{cfg_path}"
      exec '/usr/sbin/opensips', ['-D', '-E', '-f', cfg_path], next

    mktemp = (name,cb) ->
      (require 'mktemp').createFile "opensips-#{name}-XXXXXX.cfg", (err,cfg_path) ->
        if err
          throw err
        try
          cb? cfg_path, ->
            # fs.unlink cfg_path

Here's the first test: test `complete` model with default options.

    check_provided_config = (name) ->
      port = 15500
      mktemp name, (cfg_path,next) ->
        base = (require 'path').join process.cwd(), '../common/opensips'

        options =
          opensips_base_lib: base
          runtime_opensips_cfg: cfg_path
          sip_domain_name: 'test'
          listen: ['127.0.0.1']
          port: port++

        for k,v of require "../common/opensips/#{name}.json"
          options[k] ?= v
        for k,v of require '../common/opensips/default.json'
          options[k] ?= v

        # local-vars
        options.local_ipv4 = '127.0.0.1'

        compiler options

        unless fs.existsSync cfg_path
          throw "Compiler did not create #{cfg_path}"

        check_config_opensips cfg_path, next

    for name in 'complete conference emergency outbound-proxy registrant'.split ' '
      do (name) ->
        check_provided_config name

Here's the second test: make sure the json module works.

    mktemp 'json-module', (cfg_path,next) ->
      fs.writeFile cfg_path, '''
        mpath = "/usr/lib/opensips/modules/"
        loadmodule "json.so"
        listen=127.0.0.1
        port=15061
        debug=5
        startup_route {

First test whether we can at least assign the empty object.
(This is something we do pretty often in our code.)

          $avp(foo) := '{}';
          $json(foo) := $avp(foo);
          $avp(foo) := null;

          if($json(foo)) {
            log("\nOK\n");
          } else {
            log("\nFailed\n");
          }

Then check for values in object.

          $avp(foo) := '{"bar":4}';
          $json(foo) := $avp(foo);
          $avp(foo) := null;

          if($json(foo/bar) == 4) {
            log("\nOK\n");
          } else {
            log("\nFailed\n");
          }

        }
        route {
          exit;
        }
      ''', ->
        run_opensips cfg_path, next
