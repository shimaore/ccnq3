###
(c) 2010 Stephane Alnet
Released under the Affero GPL3 license or above
###

ddoc =
  _id: '_design/freeswitch'
  filters: {}

module.exports = ddoc

# This is a _usercode_ document, to be used by hosts.

###
Translate a host document into valid FreeSwitch configuration files.

Typical installation in ccnq3:

  freeswitch_local_profiles (sofia profile) in /opt/freeswitch/conf/local-profiles.xml
  freeswitch_local_acl      (acl)           in /opt/freeswitch/conf/local-acl.xml
    (ACLs in /opt/freeswitch/conf/*.acl.xml are also loaded)
  freeswitch_local_vars     (include)       in /opt/freeswitch/conf/local-vars.xml
  freeswitch_local_conf     (dialplan)      in /opt/freeswitch/conf/local-conf.xml

The sip_profiles records contain:

  sip_profiles[profile_name] =

    # Sofia data
    template: sofia template name (e.g. "sbc-media", "sbc-nomedia")
    # For the "sbc*" types, we need:
    ingress_sip_ip: which IP (v4,v6) to bind for ingress processing
    ingress_sip_port: which port to bind for ingress processing
    egress_sip_ip: which IP (v4,v6) to bind for egress processing 
    egress_sip_port: which port to bind for egress processing [default: 10000+ingress_sip_port]

    # Dialplan data
    handler: dialplan template name (e.g. "client-sbc", "carrier-sbc")
    type: dialplan profile type (e.g. "usa", "usa-cnam", "fr" for processing="client-sbc")
    send_call_to: where to send the calls ("socket", "bridge") [default: "socket"]
    ingress_target: domain where to send ingress calls
    egress_target: domain where to send egress calls

Each host document that contains a "sip_profiles" array is therefor tagged for FreeSwitch.

Other parameters:

  sip_domain_name: domain name for this FreeSwitch instance
  rtp_ip: local IP to bind to for RTP [default: "auto"]

Note: any field not marked with a [default] tag MUST be specified.


Additionally the following fields might be specified:

  sip_commands[profile_name] =
    One of:
      start             sofia profile <profile_name> start
      rescan            sofia profile <profile_name> rescan reloadxml
      restart           sofia profile <profile_name> killgw  (followed by)
                        sofia profile <profile_name> rescan reloadxml
      force_restart     sofia profile <profile_name> restart reloadxml  [required to change IP or port, will drop calls]
      stop              sofia profile <profile_name> killgw

  Each command is only executed once (the agent tracks the last _rev processed to not process the same one twice).

###

ddoc.shows.freeswitch_local_profiles = (doc,req) ->
  send "<include>"
  for profile_name, profile of doc.sip_profiles
    egress_sip_port = profile.egress_sip_port ? profile.ingress_sip_port + 10000
    send """
      <!-- Prepaid profile -->
      <X-PRE-PROCESS cmd="set" data="profile_name=#{profile_name}"/>

      <X-PRE-PROCESS cmd="set" data="ingress_sip_ip=#{profile.ingress_sip_ip}"/>
      <X-PRE-PROCESS cmd="set" data="ingress_sip_port=#{profile.ingress_sip_port}"/>

      <X-PRE-PROCESS cmd="set" data="egress_sip_ip=#{profile.egress_sip_ip}"/>
      <X-PRE-PROCESS cmd="set" data="egress_sip_port=#{egress_sip_port}"/>

      <X-PRE-PROCESS cmd="include" data="sip_profiles/#{profile.template}.xml.template"/>
      """
  send "</include>"

ddoc.shows.freeswitch_local_acl = (doc,req) ->
  send "<include>"
  for profile_name, profile of doc.sip_profiles
    send """
      <list name="ingress-#{profile_name}" default="deny">
      </list>

      <list name="egress-#{profile_name}" default="deny">
      </list>
      """
  send "</include>"

###
The configuration file "vars.xml" contains more defaults.
###

ddoc.shows.freeswitch_local_vars = (doc,req) ->
  sip_voice = doc.sip_voice ? 'en/us/callie'
  rtp_ip = doc.rtp_ip ? 'auto'
  send """
    <include>
      <!-- Common variables -->
      <X-PRE-PROCESS cmd="set" data="sound_prefix=$${base_dir}/sounds/#{sip_voice}"/>

      <X-PRE-PROCESS cmd="set" data="domain=#{doc.sip_domain_name}"/>
      <!-- domain_name is a default, it's OK to overwrite it in scripts. -->
      <X-PRE-PROCESS cmd="set" data="domain_name=$${domain}"/>

      <X-PRE-PROCESS cmd="set" data="rtp_ip=#{rtp_ip}"/>

    </include>
    """

ddoc.shows.freeswitch_local_conf = (doc,req) ->
  send """
    <include>
      <section name="dialplan" description="Regex/XML Dialplan">
    """
  for profile_name, profile in doc.sip_profiles
    send_call_to = doc.send_call_to ? 'socket'
    send """
      <X-PRE-PROCESS cmd="set" data="profile_name=#{profile_name}"/>
      <X-PRE-PROCESS cmd="set" data="profile_type=#{profile.type}"/>
      <X-PRE-PROCESS cmd="set" data="ingress_target=#{profile.ingress_target}"/>
      <X-PRE-PROCESS cmd="set" data="egress_target=#{profile.egress_target}"/>

      <X-PRE-PROCESS cmd="include" data="dialplan/#{doc.handler}.xml.template"/>
      <X-PRE-PROCESS cmd="include" data="dialplan/send-call-to-#{send_call_to}.xml.template"/>
      """

  send """
      </section>
    </include>
    """

