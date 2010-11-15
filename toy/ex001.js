#!/usr/bin/env node

// Purpose: try to have it all together:
//  xmpp client       // http://github.com/athoune/node-xmpp-client
//  web server        // http://expressjs.com/
//  couchdb client    // http://github.com/felixge/node-couchdb
//  mysql client      // https://github.com/sidorares/nodejs-mysql-native

var xmpp_client = require('xmpp-client').Client;
var express = require('express');
var sys = require('sys');
var couchdb = require('couchdb');
var mysql = require('mysql-native');

var c = new xmpp_client({
  jid: 'stephane@shimaore.net',
  password: 'beuha'
}, function() {
    sys.debug("I'm connected");
});

var app = express.createServer();

app.get('/', function(req, res){
    res.send('Hello World');
});

app.listen(3000);



var db = mysql.createTCPClient(); // localhost:3306 by default
db.auto_prepare = true;

db.auth("test", "testuser", "testpass");

function dump_rows(cmd) {
   cmd.addListener('row', function(r) { sys.puts("row: " + sys.inspect(r)); } );
}

dump_rows(db.query("select 1+1,2,3,'4',length('hello')"));
dump_rows(db.execute("select 1+1,2,3,'4',length(?)", ["hello"]));
db.close();
