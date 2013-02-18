dgram = require 'dgram'
opensips_command = (port,command) ->
  # Connect to the MI datagram port
  # Send command
  message = new Buffer(command)
  client = dgram.createSocket "udp4"
  client.send message, 0, message.length, port, "127.0.0.1", (err, bytes) ->
    # FIXME we might receive data (and might want to report it)
    # FIXME the proper way to do so is to collect it then implement a timeout (say 1s)
    #       to declare the UDP session over with.
    client.close()

module.exports = opensips_command
