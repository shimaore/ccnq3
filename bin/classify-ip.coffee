is_true = (b) -> if b then true else false

v4_loopback = (ip) ->
  is_true ip.match /^127\./

rfc_1918 = (ip) ->        # RFC 1918
  is_true ip.match /^10\.|172\.1[6789]\.|172\.2[0-9]\.|172\.3[01]\.|192\.168\./

rfc_3927 = (ip) ->        # RFC 3927
  is_true ip.match /^169\.254\.1\./

v4_is_private = (ip) ->
  v4_loopback(ip) or rfc_1918(ip) or rfc_3927(ip)

v6_linklocal = (ip) ->    # RFC 4291
  is_true ip.match /^fe[89ab][0-9a-f]:/i

rfc_4193 = (ip) ->        # RFC 4193
  is_true ip.match /^f[cd]/i

v6_multicast = (ip) ->    # RFC 4291
  is_true ip.match /^ff/i

v6_is_private = (ip) ->
  v6_linklocal(ip) or rfc_4193(ip) or v6_multicast(ip)

module.exports = {
  v4_loopback
  rfc_1918
  rfc_3927
  v4_is_private
  v6_linklocal
  rfc_4193
  v6_multicast
  v6_is_private
}
