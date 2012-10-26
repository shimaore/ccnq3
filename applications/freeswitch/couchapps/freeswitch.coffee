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

# This is a local document, to be used by hosts.

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
  voicemail_port = doc.voicemail?.port ? 7123 # FIXME default_voicemail_port

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

      <X-PRE-PROCESS cmd="set" data="voicemail_port=#{voicemail_port}"/>

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
    send """

      <X-PRE-PROCESS cmd="set" data="profile_name=#{profile_name}"/>
      <X-PRE-PROCESS cmd="set" data="profile_type=#{profile.type}"/>
      <X-PRE-PROCESS cmd="set" data="ingress_target=#{profile.ingress_target}"/>
      <X-PRE-PROCESS cmd="set" data="egress_target=#{profile.egress_target}"/>
      <X-PRE-PROCESS cmd="set" data="enum_root=#{profile.enum_root}"/>
      <X-PRE-PROCESS cmd="set" data="default_language=#{profile.default_language ? doc.voicemail?.default_language ? 'en'}"/>

      <X-PRE-PROCESS cmd="include" data="dialplan/#{profile.handler}.xml.template"/>
      <X-PRE-PROCESS cmd="include" data="dialplan/send-call-to-#{profile.send_call_to ? 'socket'}.xml.template"/>

      """

  send "\n</section>"
  send "\n</include>"
  return {}

ddoc.shows.freeswitch_local_json_cdr = p_fun (doc,req) ->

  # Convert the first character (supposed to be an hex digit)
  # into a value 0-15.
  hex1_to_num = (c) ->
    if '0' <= c <= '9'
      return c.charCodeAt(0) - '0'.charCodeAt(0)
    if 'a' <= c <= 'f'
      return c.charCodeAt(0) - 'a'.charCodeAt(0) + 10
    if 'A' <= c <= 'F'
      return c.charCodeAt(0) - 'A'.charCodeAt(0) + 10

  # Convert the first two characters (supposed to be hex digits)
  # into a value 0-255.
  hex2_to_num = (str) ->
    hex1_to_num(str.charAt 0)*16+hex1_to_num(str.charAt 1)

  # Send out content
  start
    'Content-Type': 'text/xml'

  if not doc.cdr_uri
    return {}

  cdr_uri = doc.cdr_uri

  # Parse for password
  if m = cdr_uri.match /^(https?:\/\/)([^@\/]+)@(.+)$/
    cdr_uri = m[1] + m[3]
    cred = m[2]
    # De-URI encode the username and password.
    # This will break on multi-byte characters. RFC3986 specifies UTF-8
    # (section 2.5) but it's not clear what charset FreeSwitch's XML files use,
    # and the translation given here would have to detect UTF-8 in multi-byte,
    # asses their correctness, and generate proper output for CouchDB.
    cred = cred.replace /%([\da-f]{2})/ig, (str,p1) ->
      String.fromCharCode hex2_to_num p1
  else
    cred = ''

  log_b_leg = doc.log_b_leg ? false

  send """
    <param name="url" value="#{cdr_uri}" />
    <param name="cred" value="#{cred}" />
    <param name="log-b-leg" value="#{log_b_leg}"/>

  """
  return {}

ddoc.shows.freeswitch_local_modules = p_fun (doc,req) ->

  # Send out content
  start
    'Content-Type': 'text/xml'

  send "<include>\n"
  send "<!-- #{doc._id} #{doc._rev} -->\n"

  if doc.cdr_uri?
    send """
      <load module="mod_json_cdr"/>

    """

  send "\n</include>"
  return {}
