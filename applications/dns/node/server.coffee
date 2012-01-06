dns = require "../lib/dns"
zones = require "./zones"

server = dns.createServer(zones)
server.listen()
