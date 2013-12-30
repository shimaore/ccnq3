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
        debug=0
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


    mktemp 'rabbitmq', (cfg_path,next) ->
      fs.writeFile cfg_path, '''
        mpath="/usr/lib/opensips/modules"
        listen=127.0.0.1
        port=15063
        debug=5
        loadmodule "event_rabbitmq.so"
        startup_route {
          # subscribe_event("E_SCRIPT_REPORT","rabbitmq:guest:guest@127.0.0.1/ccnq3/test");
          subscribe_event("E_SCRIPT_REPORT","rabbitmq:guest:guest@127.0.0.1/test");
          $avp(event-names) := null;
          $avp(event-values) := null;
          $avp(event-names) = "event";
          $avp(event-values) = "startup";
          raise_event("E_SCRIPT_REPORT",$avp(event-names),$avp(event-values));
        }
        route {
          exit;
        }
        timer_route[tester,10] {
          $avp(event-names) := null;
          $avp(event-values) := null;
          $avp(event-names) = "event";
          $avp(event-values) = "timer";
          $avp(event-names) = "foo";
          $avp(event-values) = "bar";
          raise_event("E_SCRIPT_REPORT",$avp(event-names),$avp(event-values));
        }
      ''', ->
        test.run cfg_path, next

    mktemp 'crash-drouting-1.11.0', (cfg_path,next) ->
      fs.writeFileSync cfg_path, '''
        mpath="/usr/lib/opensips/modules"
        listen=127.0.0.1
        port=15063
        debug=5
        loadmodule "db_text.so"
        loadmodule "tm.so"
        loadmodule "drouting.so"
        modparam("drouting","db_url","text:///tmp")
        modparam("drouting","ruri_avp","$avp(dr_ruri)")
        modparam("drouting","gw_id_avp","$avp(gw_id)")
        modparam("drouting","gw_attrs_avp","$avp(gw_attrs)")
        modparam("drouting","gw_priprefix_avp","$avp(gw_priprefix)")
        modparam("drouting","rule_id_avp","$avp(rule_id)")
        modparam("drouting","rule_attrs_avp","$avp(rule_attrs)")
        modparam("drouting","rule_prefix_avp","$avp(rule_prefix)")
        modparam("drouting","carrier_id_avp","$avp(carrier_id)")
        modparam("drouting","carrier_attrs_avp","$avp(carrier_attrs)")
        route {
          do_routing("14");
          exit;
        }
      ''', flags:'w'
      fs.writeFileSync '/tmp/version', '''
        table_name(str) table_version(int)
        dr_gateways:6
        dr_groups:1
        dr_carriers:1
        dr_rules:1

      ''', flags:'w'
      fs.writeFileSync '/tmp/dr_gateways', '''
        id(int) gwid(str) type(int) address(str) strip(int) pri_prefix(str,null) attrs(str,null) probe_mod(int) description(str)
        1:gw1:0:192.168.1.10:0:::0:gw1
        2:gw2:0:192.168.1.11:0:::0:gw2

      ''', flags:'w'
      fs.writeFileSync '/tmp/dr_groups', '''
        id(int) username(str) domain(str) groupid(int) description(str)

      ''', flags:'w'
      fs.writeFileSync '/tmp/dr_carriers', '''
        id(int) carrierid(str) gwlist(str) flags(int) attrs(str,null) description(str)

      ''', flags:'w'
      fs.writeFileSync '/tmp/dr_rules', '''
        ruleid(int) groupid(str) prefix(str) timerec(string) priority(int) routeid(str,null) gwlist(str) attrs(str,null) description(str)
        1:14:1536::0::gw1,gw2:attrs_here:very expensive
        2:14:1627::0::gw1,gw2:attrs_here:very expensive

      ''', flags:'w'
      test.run cfg_path, next
