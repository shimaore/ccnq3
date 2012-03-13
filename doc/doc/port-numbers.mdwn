Port assignments:

These are required to be managed so that multiple services can be
co-located.

RTP ports:
  MediaProxy:    40000:41998 (1000 sessions, up to 500 calls)
  FeatureServer: 42000:42998 (500 sessions, up to 250 calls)
  SBC+media:     43000:43998 (500 sessions, up to 250 calls)

SIP ports (Sofia profiles):
  The ports indicated are the external ports for SBC "ingress" profiles.
  The internal "egress" profiles use port N+10000.

  Normally use ports 5060, 5062, etc. for the carrier-SBCs.

  Registrant server: 5070
  Emergency server: 5072
  FeatureServer:  5100

  Cust SBC:     15200:15299 (internal -- towards customer proxy)
                5200:5299 (external -- towards inbound/outbound proxy)

  OpenSIPS:     5060 *

Other ports:
  MediaProxy  25060
