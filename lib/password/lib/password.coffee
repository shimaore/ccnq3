

fs = require 'fs'

wordlist_file = require.resolve './wordlist.json'
wordlist = JSON.parse(fs.readFileSync(wordlist_file, 'utf8'))

# cdb = require process.cwd()+'/../../../lib/cdb.coffee'

module.exports = (l) ->
  words = (wordlist.words[Math.floor(Math.random()*wordlist.words.length)] for i in [1..l])
  return words.join(' ')

