Check whether generic opensips configurations will compile OK.

Requirements:

```
aptitude install opensips opensips-dbhttp-module opensips-json-module opensips-b2bua-module
```

    fs = require 'fs'
    test = require './test_opensips'

    mktemp = (name,cb) ->
      (require 'mktemp').createFile "opensips-#{name}-XXXXXX.cfg", (err,cfg_path) ->
        if err
          throw err
        try
          cb? cfg_path, ->
            # fs.unlink cfg_path

Here's the first test: test `complete` model with default options.

    compiler = require '../common/opensips/compiler'

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

        test.check_config cfg_path, next

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
        test.run cfg_path, next

Here's the third test: make sure numerical port number works.

    mktemp 'port-as-integer', (cfg_path,next) ->
      fs.writeFile cfg_path, '''
        listen=127.0.0.1
        port=15062
        debug=0
        startup_route {

          $var(port) = 1234;
          $ru = "sip:foo@127.0.0.1";
          $rp = $var(port);

          if($ru == "sip:foo@127.0.0.1:1234") {
            log(0,"\nOK\n");
          } else {
            log(0,"\nFailed\n");
          }

          $var(port) = "1234";
          $ru = "sip:foo@127.0.0.1";
          $rp = $var(port);

          if($ru == "sip:foo@127.0.0.1:1234") {
            log(0,"\nOK\n");
          } else {
            log(0,"\nFailed\n");
          }


        }
        route {
          exit;
        }
      ''', ->
        test.run cfg_path, next
