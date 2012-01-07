###
(c) 2010 Stephane Alnet
Released under the Affero GPL3 license or above
###

ddoc =
  _id: '_design/dns'
  language: 'javascript'
  views: {}
  shows: {}
  filters: {}

module.exports = ddoc

p_fun = (f) -> '('+f+')'

ddoc.views.domains =
  map: p_fun (doc) ->

    name_key = (name) ->
      domain.split('').reverse().join('')+'~'

    # Only return documents that will end up as domains that can be served
    if doc.type? and doc.type is 'domain' and doc.records?
      # Sort the documents so that the sub-domains are listed first.
      emit name_key(doc.domain), null

# The following view output the domain's name as key
# and a DNS record as content.
ddoc.views.names =
  map: p_fun (doc) ->
    return unless doc.type? and doc.type

    name_key = (name) ->
      domain.split('').reverse().join('')+'~'

    ip_to_name = {}

    switch doc.type
      when 'host'
        host_key = name_key doc.host
        if doc.interfaces?
          primary_ip = null
          primary_v6 = null
          for name, _ of doc.interfaces
            do (name,_) ->
              if _.ipv4
                if not rfc1918 _.ipv4
                  primary_ip ?= _.ipv4
                ip_to_name[_.ipv4] = name+'.'+doc.host
                emit host_key,
                  prefix:name
                  class:'A',
                  value:_.ipv4
              if _.ipv6
                primary_v6 ?= _.ipv6
                ip_to_name[_.ipv6] = name+'.'+doc.host
                emit host_key,
                  prefix:name
                  class:'AAAA'
                  value:_.ipv6

          primary_ip ?= primary_v6
          ip_to_name[primary_ip] = doc.host

        domain = doc.sip_domain_name
        domain_key = name_key domain

        if doc.sip_profiles?
          for name, _ of doc.sip_profiles
            do (name,_) ->
              if _.ingress_sip_ip?
                # different profiles with the same name in the same domain are reputed to be the same
                # Note: SRV records must use names. So if ip_to_name does not have a mapping there's
                # no valid way we can generate an SRV. (Also, ingress_sip_ip and egress_sip_ip are
                # supposed to be local addresses, so if the "interfaces" field is populated properly
                # this shouldn't be an issue.)
                emit domain_key,
                  prefix:'_sip._udp.ingress-'+name
                  class:'SRV'
                  value:[
                    10
                    10
                    _.ingress_sip_port
                    ip_to_name[_.ingress_sip_ip]
                  ]
                emit domain_key,
                  prefix:'_sip._udp.egress-'+name
                  class:'SRV'
                  value:[
                    10
                    10
                    _.egress_sip_port ? _.ingress_sip_port+10000
                    ip_to_name[_.egress_ip_ip ? _.ingress_sip_ip ]
                  ]

        if doc.opensips?
          emit domain_key,
            prefix:'_sip._udp'
            class:'SRV'
            value:[
              10
              10
              5060
              doc.host
            ]

        # if doc.portal?
