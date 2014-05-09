PouchDB = require 'pouchdb'
byline = require 'byline'

config = require '/etc/ccnq3/host.json'

db = new PouchDB config.provisioning.couchdb_uri

domain = process.argv[2]
rule = parseInt process.argv[3]
console.log "Loading data for rule:#{domain}:#{rule}:*"

db
.allDocs startkey:"rule:#{domain}:#{rule}:", endkey:"rule:#{domain}:#{rule};", include_docs: true
.then (res) ->
  rules = {}
  rules[doc.prefix] = doc for doc in res.rows

  process.stdin.setEncoding 'utf8'
  lines = byline process.stdin
  lines.setEncoding 'utf8'

  n = 0

  lines.on 'data', (line) ->
    n++
    [prefix,gwlist,cdr] = line.split /;/
    throw "Invalid prefix #{prefix}" unless prefix.match /^\d+$/

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
    docs = []
    docs.push doc for key,doc of rules
    console.log "Saving changes from #{n} lines with #{docs.length} updates."
    db
    .bulkDocs docs
    .then ->
      console.log 'Done'
