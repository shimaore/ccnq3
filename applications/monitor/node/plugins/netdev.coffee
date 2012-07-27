@name = 'netdev'
@description = 'Network devices'

u = require './utils'

fields = 'rx_bytes rx_packets rx_errors rx_drop rx_fifo rx_frame rx_compressed rx_multicast tx_bytes tx_packets tx_errors tx_drop tx_fifo tx_collisions tx_carrier tx_compressed'.split /\s+/

@get = (cb) ->
  netdev = {}

  content = u.content_of '/proc/net/dev'
  for line in content when line.match /:/
    l = u.split_on_blanks line
    name = l.shift().replace /:$/, ''
    netdev[name] = {}
    netdev[name][key] = parseInt l[i] for key, i in fields

  cb netdev
