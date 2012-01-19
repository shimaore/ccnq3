###
(c) 2010 Stephane Alnet
Released under the Affero GPL3 license or above
###

ddoc =
  _id: '_design/freeswitch'
  language: 'javascript'
  shows: {}
  filters: {}

module.exports = ddoc

# This is a _usercode_ document, to be used by hosts.

###
Translate a host document into valid FreeSwitch configuration files.

Typical installation in ccnq3:

  freeswitch_local_profiles (sofia profile) in /opt/ccnq3/freeswitch/conf/local-profiles.xml
  freeswitch_local_acl      (acl)           in /opt/ccnq3/freeswitch/conf/local-acl.xml
    (ACLs in /opt/freeswitch/conf/*.acl.xml are also loaded)
  freeswitch_local_vars     (include)       in /opt/ccnq3/freeswitch/conf/local-vars.xml
  freeswitch_local_conf     (dialplan)      in /opt/ccnq3/freeswitch/conf/local-conf.xml

###

p_fun = (f) -> '('+f+')'

ddoc.shows.freeswitch_local_profiles = p_fun (doc,req) ->
  start
    'Content-Type': 'text/xml'

  send "<include>\n"
  send "<!-- #{doc._id} #{doc._rev} -->\n"
  for profile_name, profile of doc.sip_profiles
    egress_sip_ip   = profile.egress_sip_ip   ? profile.ingress_sip_ip
    egress_sip_port = profile.egress_sip_port ? profile.ingress_sip_port + 10000
    send """

      <X-PRE-PROCESS cmd="set" data="profile_name=#{profile_name}"/>

      <X-PRE-PROCESS cmd="set" data="ingress_sip_ip=#{profile.ingress_sip_ip}"/>
      <X-PRE-PROCESS cmd="set" data="ingress_sip_port=#{profile.ingress_sip_port}"/>

      <X-PRE-PROCESS cmd="set" data="egress_sip_ip=#{egress_sip_ip}"/>
      <X-PRE-PROCESS cmd="set" data="egress_sip_port=#{egress_sip_port}"/>

      <X-PRE-PROCESS cmd="include" data="sip_profiles/#{profile.template}.xml.template"/>

      """
  send "\n</include>"
  return {}

ddoc.shows.freeswitch_local_acl = p_fun (doc,req) ->
  start
    'Content-Type': 'text/xml'

  send "<include>\n"
  send "<!-- #{doc._id} #{doc._rev} -->\n"

  for profile_name, profile of doc.sip_profiles
    send """
      <list name="ingress-#{profile_name}" default="deny">
    """
    if profile.ingress_acl?
      send '<node type="allow" cidr="' + host + '"/>' for host in profile.ingress_acl
    send "</list>\n"

    send """
      <list name="egress-#{profile_name}" default="deny">
    """
    if profile.egress_acl?
      send '<node type="allow" cidr="' + host + '"/>' for host in profile.egress_acl
    send "</list>\n"

  send "\n</include>"
  return {}

###
The configuration file "vars.xml" contains more defaults.
###

ddoc.shows.freeswitch_local_vars = p_fun (doc,req) ->
  sip_voice = doc.sip_voice ? 'en/us/callie'
  rtp_ip = doc.rtp_ip ? 'auto'

  start
    'Content-Type': 'text/xml'

  send "<include>\n"
  send "<!-- #{doc._id} #{doc._rev} -->\n"
  send """

      <!-- Common variables -->
      <X-PRE-PROCESS cmd="set" data="sound_prefix=$${base_dir}/sounds/#{sip_voice}"/>

      <X-PRE-PROCESS cmd="set" data="domain=#{doc.sip_domain_name}"/>
      <!-- domain_name is a default, it's OK to overwrite it in scripts. -->
      <X-PRE-PROCESS cmd="set" data="domain_name=$${domain}"/>

      <X-PRE-PROCESS cmd="set" data="rtp_ip=#{rtp_ip}"/>

    """
  if doc.sip_variables?
    for name, value of doc.sip_variables
      send """
        <X-PRE-PROCESS cmd="set" data="#{name}=#{value}"/>
        """
  send "\n</include>"
  return {}

ddoc.shows.freeswitch_local_conf = p_fun (doc,req) ->
  start
    'Content-Type': 'text/xml'

  send "<include>\n"
  send "<!-- #{doc._id} #{doc._rev} -->\n"
  send """
      <section name="dialplan" description="Regex/XML Dialplan">\n
    """

  for profile_name, profile of doc.sip_profiles
    send_call_to = profile.send_call_to ? 'socket'
    send """

      <X-PRE-PROCESS cmd="set" data="profile_name=#{profile_name}"/>
      <X-PRE-PROCESS cmd="set" data="profile_type=#{profile.type}"/>
      <X-PRE-PROCESS cmd="set" data="ingress_target=#{profile.ingress_target}"/>
      <X-PRE-PROCESS cmd="set" data="egress_target=#{profile.egress_target}"/>
      <X-PRE-PROCESS cmd="set" data="enum_root=#{profile.enum_root}"/>

      <X-PRE-PROCESS cmd="include" data="dialplan/#{profile.handler}.xml.template"/>
      <X-PRE-PROCESS cmd="include" data="dialplan/send-call-to-#{send_call_to}.xml.template"/>

      """

  send "\n</section>"
  send "\n</include>"
  return {}
