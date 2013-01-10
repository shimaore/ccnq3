# Concept: the response is stored either as:
#
# * a CouchDB record with the original request as main doc + JSON content as `packets`
# * a CouchDB record with the original request as main doc + PCAP content as attachment `packets.pcap`
#
# This allows for storage of large responses (a potential issue with AMQP).


