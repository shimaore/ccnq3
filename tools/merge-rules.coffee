PouchDB = require 'pouchdb'
byline = require 'byline'

config = require '/etc/ccnq3/host.json'

db = new PouchDB config.provisioning.couchdb_uri

domain = process.argv[2]
rule = parseInt process.argv[3]

db
.allDocs startkey:"rule:#{domain}:#{rule}:", endkey:"rule:#{domain}:#{rule};", include_docs: true
.then (res) ->
  rules = {}
  rules[doc.prefix] = doc for doc in res.rows

  lines = byline process.stdin

  lines.on 'data', (line) ->
    [prefix,gwlist,cdr] = line.split /;/

    if rules[prefix]?
      doc = rules[prefix]
      doc.gwlist = gwlist
      doc.attrs ?= {}
      doc.attrs.cdr = cdr
    else
      doc =
        _id: "rule:#{domain}:#{rule}:#{prefix}"
        attrs: {cdr}
        groupid: rule
        gwlist: gwlist
        prefix: prefix
        rule: "#{domain}:#{rule}:#{prefix}"
        sip_domain_name: domain
        type: 'rule'
      rules[prefix] = doc

  lines.on 'end', (line) ->
    db
    .bulkDocs rules
    .then ->
      console.log 'Done'
