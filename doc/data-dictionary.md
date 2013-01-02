This document describes the configuration parameters for ccnq3.

Conventions
===========

Database URI
------------

In this document the term *URI of database* signifies a URI of some CouchDB database, and is always a string.

These URIs might contain authentication usernames and passwords.

### On the manager server

The manager server uses direclty the central CouchDB database.

### On non-manager servers

Other servers use a local-only CouchDB instance (replicated from the central CouchDB database) for any read-access to the provisioning database, and to store some local values (CDRs, location information for a registration server).

These non-manager servers might also write data back to the central CouchDB database either as replication (for example to aggregate the CDRs in the `cdrs` database, or the location information in the `locations` database), or for logging purposes (the `logging` and `monitor` databases for example).

Authentication
--------------

In CouchDB, authentication is provided by the `_users` database for normal users; by the configuration system (section `admins`) for administrative users.

### On the manager server

On the manager server, most access will be done using an `admin` account. (Admin accounts normally do not show up in the `_users` database, their authentication is managed separately.)

The only exceptions are the `provisiong.host_couchdb_uri` which is required to use a `host@`+host-name username, and other URIs which _must not_ have authentication tokens, such as `session.couchdb_uri` (in the ccnq3-web project).

### On non-manager servers

Non-manager host use a local-only, non-authenticated CouchDB instance for all real-time accesses. No username is required to access the databases on that local CouchDB server. No administrative account is created either (the database is said to be in "Admin Party Mode").

For example, `provisioning.local_couchdb_uri` is simply `http://127.0.0.1:5984/provisioning`, `cdr_uri` is `http://127.0.0.1:5984/cdr`.

On the other hand, when accessing the central CouchDB database (normally located on the manager server, or on some other central server), non-manager hosts should _never_ use an `admin` account; the following two types of accounts (which must be created in that central CouchBD database) are recommended:

* For each `host`, a user named `host@`+host-name with its roles set (at least) to `["host"]`.

  This should be used for any URI where the host needs access to the central CouchDB database (e.g. for replication of the provisioning database, or to upload CDRs, locations, logging data, etc.).

  Use this username in fields such as `provisioning.host_couchdb_uri`, `opensips_proxy.usrloc_aggregate_uri`, `cdr_aggregate_uri`, `logging.host_couchdb_uri`, `monitor.host_couchdb_uri`.

* For each 'voicemail' server, a user named `voicemail@`+host-name with the roles set (at least) to `["update:user_db:","access:_users:"]`. (Notice the extra colon `:` at the end of each value.)

  This should be used for any URI related to `applications/voicemail`, to allow the voicemail server to manipulate the databases where messages are stored (hence `update:user_db`) and query for databases linked to a specific user (hence `access:_users:`).

  Use this username in fields such as `voicemail.userdb_base_uri`.

Applications
============

Applications are modules inside the CCNQ3 system which may be added or removed on a server after installation of the Debian packages.  Each application may come with database updates, new local processes, and sometimes offer remotely-accessible services.

In a template CCNQ3 system, you would typically have two types of servers, _manager_ servers and _call-processing_ servers.
A manager server would typically have the `ccnq3` package installed, and run the following applications:

    # Core database management
    applications/provisioning
    # Aggregation
    applications/cdrs
    applications/locations

A call-processing server would typically have the `ccnq3-voice` package installed, and run the following applications:

    # Applications for a server running ccnq3-voice
    applications/freeswitch
    applications/opensips
    applications/traces
    # Additional applications for a server running FreeSwitch
    applications/voicemail
    # Additional applications for a server running OpenSIPS
    applications/registrant
    applications/emergency

Finally, at least two servers (for redundancy purposes) must have the `ccnq3-dns` package installed, and run the following application:

    applications/dns

Moreover all servers, regardless of intended purpose, must run the following application:

    applications/host

Some of these applications are automatically installed. For example, a `manager` host (created using the `bootstrap-manager` script) will have most services enabled except the aggregation services. Removing automatically-installed applications in this case will lead to loss of functionality or breakage.

After adding or removing one or more applications on a given host, you must run

    aptitude reinstall ccnq3

on that host to ensure that the proper dependencies are updated.
This operation will in most cases lead to loss of calls on call-processing servers.

The following applications are available:

* applications/host

  The base host support application.

  Install on: all servers.

  Required: yes.

* applications/provisioning

  Support for provisioning.

* applications/cdrs

  A CDR aggregation application.

  Install on: the server that will aggregate the CDRs.

* applications/locations

  Registered endpoints location aggregation.
  Install on: the server that will aggregate the data.

* applications/dns

  A database-driven DNS server.

  Install on: a server running the ccnq3-dns package.

* applications/freeswitch

  FreeSwitch support application.
  Install on: any server running FreeSwitch.

* applications/opensips

  OpenSIPS support application.
  Install on: any server running OpenSIPS.

* applications/traces

  Support for access to local traces.
  Install on: servers with the ccnq3-traces package, typically OpenSIPS and FreeSwitch hosts.

* applications/voicemail

  FreeSwitch support for voicemail.
  Install on: a FreeSwitch server that will provide voicemail.

* applications/voicemail-store

  Database support for voicemail.
  Install on: a server with direct access to the users databases.

* applications/cnam-client (unstable)

  A CNAM client application.

  Install on: a server running FreeSwitch client-side.

* applications/registrant

  OpenSIPS server providing batch registration to an upstream server.

  Install on: a server running OpenSIPS; will start a separate OpenSIPS instance for client registration.

* applications/emergency

  An emergency call routing server.

  Install on: a server running OpenSIPS; will start a separate OpenSIPS instance for 302 emergency calls redirection.

* applications/monitor

  Monitors the local host and pushes statistics about it into a CouchDB database.

* applications/couchdb_daemon

  Provided the extended API (see below *Extended API*) embedded in the central CouchDB database.

  Install on: the central CoudhDB server.

  See the file `bin/manager.ini` for how to embed within CouchDB. (The embedding is done automatically if the manager server is also the CouchDB server.)

provisioning database
=====================

The provisioning database contains the master copy of all provisioning information
for an entire system.

It contains different types of records, which can be identified by their "type" field.
The type is also the first part of the records' identifier, to avoid identifier collisions.

host (provisioning records)
---------------------------

The local configuration file for a host, normally found in
`/etc/ccnq3/host.json`, is a copy of the `host` record for that
specific server as found in the master CouchDB provisioning database.

(In the code, this is referred to as the `config` object. This is the object managed by the `ccnq3.config` class.)

There must be exactly one `host` record for each server in the system.
Servers are identified by their (arbitrary) Fully Qualified Domain Name (FQDN).

Most changes in `host` records might require you to:

*   either restart the ccnq3 processes to apply the changes:

        /etc/init.d/ccnq3 restart

    (This should be sufficient in most cases.)

*   in some cases reinstall the ccnq3 package:

        aptitude reinstall ccnq3

    This is especially true when adding an application, so that
    the proper dependencies might be installed for the new application.

However this does not apply to commands (such as the ones in `sip_commands`),
which are executed immediately.

Operational note:
In a lot of cases, restarting, reinstalling, or submitting commands
will cause calls to disconnect. These operations are best used during
dedicated maintenance windows and should be avoided during production use.

Currently the main freeswitch, opensips, and medaproxy processes are not started by ccnq3.
These processes might be controlled using their respective /etc/init.d/ scripts.

Developper note:
As suggested above, the `host` record for a particuler server is referred to as the `config` record for that server inside most applications.

### Common section (host provisioning record) ###

All the fields in this section are pre-populated by the installation scripts.
There is no reason to change them after the initial installation of a server.
Only the `applications` array will need to be expanded.

Installation caveat: `provisioning.host_couchdb_uri` might need to be fixed if the system cannot guess
your installation.

*   `_id`: type+":"+host

*   `account`: ""    (the empty string)

*   `updated_at`: integer, update timestamp in ms [required]

    `new Date().getTime()`  for example

*   `type`: "host"

*   `host`: string; hostname, preferably FQDN

    This value must match what the `hostname` command returns.

*   `interfaces`: {} of {}, fields:
    * `ipv4`: IP (if interface supports v4)
    * `ipv6`: IP (if interface supports v6)

    The keys of the records in the `interfaces` hash must be unique, so they cannot just be the interface's name,
    since an interface may have multiple v4 or v6 IP addresses.

    The key `primary` has a special meaning (see next item).

*   `interfaces.primary.ipv4`,
    `interfaces.primary.ipv6`

    If present, these are selected as the addresses for the host itself.
    Otherwise a random non-private IPv4 address is selected, and a
    random IPv6 address is selected, from the ones present in the
    "interfaces" records.

*   `amqp`

    AMQP URI with access for the local host, complete with `ccnq3` vhost. (Similar authentication as `provisioning.host_couchdb_uri`.)

    (Under development) AMQP is used to forward logging data, send command to servers (replaces the obsolete `sip_commands` and `traces.run`) and retrieve data (traces, registrant).

Changing any of the following settings would require to restart the matching
services, since configuration is read (in most cases) once at startup.

*   `admin`:   (only present for bootstrap-system hosts normally; there's no reason to modify these)
    * `couchdb_uri`: server admin URI [required for a Manager host]
    * `amqp`: amqp admin URI (with `/ccnq3` path to access the `ccnq3` vhost)
    * `amqp_mgmt`: http(s) admin URI for API access (with `/api` path included)
    * `system`: true   (indicates this host is the one that should do system updates)

*   `users`:
    * `couchdb_uri`: `_users` database admin URI

    Normally only present on the manager server and a voicemail-store server.

*   `applications`: [] of strings, list of applications that need to be installed

    These are simply relative paths to the matching "package" for that application.
    To apply changes to the list of applications, you must `aptitude reinstall ccnq3` on the host.

    Example:

        [ "applications/host", "applications/traces", "applications/freeswitch" ]

*   `provisioning`:
    * `couchdb_uri`: URI of the provisioning database (with database admin authentication) [used by couchapps apps to insert new applications]

      Normally only present on a manager host (and only used by installation scripts)

    * `host_couchdb_uri`: URI of the provisioning database (read-only), allows access to the main provisioning database from any host. [required for a non-Manager host]

      This URI is used as the source for replication of the provisioning database onto a non-manager host
      Replication will work better if this URI points directly to CouchDB (rather than a reverse proxy, for example).

      This URI is also used by ccnq3_config to locate the host's configuration; if it is not present only the local (file-based) configuration will be used.

    * `local_couchdb_uri`: URI of a local replica of the provisioning database [used by local applications such as opensips]

      Generally `http://127.0.0.1:5984/provisioning` [no authentication to keep things faster]

      Realtime (call-handling) applications should only rely on this database as their primary source.

      Must have db admin access to the database (so that applications can push their design documents).

### Other generic sections

*   `install`: (normally not defined)

    This feature is used to force re-installation of the corresponding databases (for example to change the URI)

    * `provisioning`:
      * `couchdb_uri`

* `replicate_interval`: integer; milliseconds [default: 5 minutes]

    Sometimes CouchDB replicate processes might die.
    An automated process will restart them at `replicate_interval` milliseconds.

*   `logging`:

    This feature allows centralized logging from CCNQ3 hosts.
    All logging is pushed into a single central CouchDB database; no local logging database is created.

    * `couchdb_uri`: string, only on the manager server; the database (with admin access) where data should be stored.

    * `host_couchdb_uri`: string, required; the database (with host access) where data should be stored

### When running `applications/monitor`

*   `monitor`:

    This feature is used on hosts running the `applications/monitor` service.
    All monitoring data is parsed and pushed into a CouchDB database at set intervals as a JSON record.
    For analysis, reporting, and graphing, use CouchDB and other tools.

    * `couchdb_uri`: string, only on the manager server; the database (with admin access) where data should be stored.

    * `host_couchdb_uri`: string, required; the database (with host access) where data should be stored

    * `interval`: integer; the interval in milliseconds between two runs of the data collection [default: 5 minutes]

    * `plugins`: array of strings; the list of monitor plugins that need to be activated [default: all of them]

      The following plugins are available:
      * `os`: Node.js `os` module data, plus `/proc/version`
      * `process`: Node.js `process` module data (information about the monitor application itself)
      * `processes`: `/proc/[pid]/(comm|cmdline|oom_score|stat|statm)` (currently does not support thread-level data)
      * `interrupts`: `/proc/interrupts` data
      * `diskstats`: `/proc/diskstats` data
      * `meminfo`: `/proc/meminfo` data
      * `netdev`: `/proc/net/dev` data
      * `stat`: `/proc/stat` data
      * `vmstat`: `/proc/vmstat` data

    * `couchdb_uri`: string; administrative access to the database where data is stored (this is only used to create the database and should only be present on the host running that database).

### Specific to hosts running FreeSwitch ###

To add a FreeSwitch host:

1. Configure the fields in this section

   (You'll need to configure at least `sip_domain_name`.)

   (You'll need to configure one `sip_profiles[]` in order to be able to place calls.)

2. Add `applications/freeswitch` to the applications field [and restart ccnq3]

Configuration options:

*   `sip_domain_name`:  string (required); FQDN accepted by the server

    This should be the "cluster name" for servers running similar
    configurations. This is used by applications/dns to create
    SRV records for these services. This is also used by applications/opensips
    to create gateway entries for the `egress_gwid` in those domains/clusters.
    Finally, this is the domain name accepted by OpenSIPS servers in that cluster.

*   `rtp_ip`: local IP to bind to for RTP [default: "auto"]

*   `cdr_uri`: URI where the local CDRs should be written to [default: none, no CDRs are generated]; recommended value: "http://127.0.0.1:5984/cdr"
*   `log_b_leg`: boolean; whether a CDR should be generated for the b-leg of a call [default: false, log only the a-leg]
*   `cdr_aggregate_uri`: URI where the local CDRs should be replicated to [no default]
      Note: must contain authentication (for the local host).

*   `sip_profiles`: {} of profiles descriptions:

    *   `sip_profiles[profile_name]`:

      * Sofia data
        * `template`: sofia template name (e.g. "sbc-media", "sbc-nomedia")
      * For the "sbc*" types, we need:
        * `ingress_sip_ip`: which IP (v4,v6) to bind for ingress processing
        * `ingress_sip_port`: which port to bind for ingress processing [in the range 5060 to 5299]
        * `ingress_acl`: [] of CIDR records "ip/masklen" source IPs allowed for ingress processing
        * `egress_sip_ip`: which IP (v4,v6) to bind for egress processing [default: ingress_sip_ip]
        * `egress_sip_port`: which port to bind for egress processing [default: 10000+ingress_sip_port; in the range 15060 to 15299]
        * `egress_acl`: [] of CIDR records "ip/masklen" source IPs allowed for the egress processing
        * `egress_gwid`: optional; a (unique) alphanumerical gateway id or name to be used in routing rules.

        Note: port numbers must be in the range 5060 to 5299 or 15060 to 15299 to be compatible with the "traces" application.

        Note: look in doc/port-numbers.md for port numbers conventions.

        Note: `egress_gwid` must be unique amongst all gateway IDs, including the ones in "gateway"-type records.

      * Dialplan data
        * `handler`: dialplan template name (e.g. "client-sbc", "voicemail")
        * `egress_target`: domain where to send egress calls

      * For handler="client-sbc"
        * `type`: dialplan profile type (e.g. "usa", "france")
        * `send_call_to`: where to send the calls ("socket", "bridge") [default: "socket"]
        * `ingress_target`: domain where to send ingress calls
        * `number_domain`: for inbound calls, how to locate the local numbers in the proxy [default: "local"]

      * For handler on one of the carrier-sbc's
        * `enum_root`: Carrier ENUM root for inbound routing

      * For handler="voicemail"
        * `default_language`: string; default voicemail language [default: this host's voicemail.default_language, see below]

      Changes (except for `*_sip_ip` and `*_sip_port`) are automatically applied.

*   `sip_commands`: {} of profiles commands:

    *   `sip_commands[sofia_profile]`: string
          One of:
            "start"       sofia profile <profile_name> start
            "restart"     sofia profile <profile_name> restart reloadxml  [required to change IP or port]
            "stop"        sofia profile <profile_name> killgw

    *   `sip_commands.freeswitch`: string
          One of:
            "reload sofia"    unload mod_sofia, load mod_sofia            [required to add a new profile]
            "pause inbound"   fsctl pause inbound
            "pause outbound"  fsctl pause outbound
            "resume inbound"  fsctl resume inbound
            "resume outbound" fsctl resume outbound

    All these commands will cause calls to drop if any is present on that profile.

    The "sofia_profile" key is either "egress-#{profile_name}" or "ingress-#{profile_name}" so that each direction
    can be restarted independently.

    Add a command then remove it from the hash to prevent accidental misfiring of commands.

    A special "sofia_profile" key "opensips" is used to send events to a running OpenSIPS process (rather than a
    FreeSwitch sofia profile). See below for more information.

    A special "sofia_profile" key "registrant" is used to send events to a running registrant process (rather than a
    FreeSwitch sofia profile). See below for more information.

*   `sip_variables`: {} of global (FreeSwitch) variables; defaults to {}

    The idea is that these can be used on a per-host basis by additional dialplans, profiles, etc.

    These should also show up in CDRs. FIXME confirm this is the case

### Specific to hosts running OpenSIPS. ###

To add an OpenSIPS host:

1. Configure the fields in this section
2. Add "applications/opensips" to the applications field [and restart ccnq3]
3. Run common/mediaproxy/install.sh to install mediaproxy FIXME still requires some work

Configuration options:

*   `opensips_proxy`:

    * `port`:34340   integer, required, do not change [default]

    * `hostname`:"127.0.0.1"   string, required, do not change [default]

    * `usrloc_uri`: URI of the location database (used to save registration data)

      This should be "http://127.0.0.1:5984/location" [default]

    * `usrloc_aggregate_uri`: URI where the location database should be replicated to [no default]

      Must contain authentication (for the local host).

*   `opensips`:

    * `model`: `"complete"`, or any other model defined in common/opensips [required]

      Currently supported: `complete`, `outbound-proxy`, `emergency`, `registrant`.

    * `number_domain`: string; the default `number_domain` used on this server if none is provided [default: "local"]

      This value is used if:
      * for outbound calls, the `endpoint` record contains no `number_domain`;
      * for inbound calls, the `client-sbc` `sip_profiles` record contains no `number_domain`.

    * `listen`: [] of strings "host:port" to which OpenSIPS will bind()  [default is the empty array, in which case OpenSIPS binds to all interfaces on port 5060]

        For example, if you wish for OpenSIPS to only listen on local interfaces for test purposes, you might set `listen` to:

            [
              "127.0.0.1:5060",
              "[::1]:5060"
            ]

    * `local_ipv4`: for models using it (`"conference"`), IP where to send all INVITE messages

    * `local_ipv6`: reserved

    * `voicemail_notifier`: incoming SUBSCRIBE messages are sent to this host:port or name

        Typically should point to the egress-* voicemail profile's NAPTR record.

        If this parameter is not defined, forwarding of message waiting indication (MWI) via SUBSCRIBE and NOTIFY messages will not work.

    * `lineside_extra_info`: OpenSIPS string containing variables to include in a `X-CCNQ3-Extra` header.

        The output is recorded in CDRs in the `variables.ccnq_extra` field.

        In the `complete` model it defaults to "$pr $si $sp -> $Ri $Rp $json(src_endpoint/endpoint) $au $ad $ar $ci $ru $fu $tu $ua".
        Other models do not use the `X-CCNQ3-Extra` header.

    There are plenty other OpenSIPS configuration parameters; all of them can be modified via the database.
    The list of parameters can be found in the source code, in the JSON configuration files under `common/opensips/`.
    However in normal operation there is no reason to modify parameters except for those listed above.

*   `sip_commands.opensips`: string

      One of:
        "reload routes"         [apply "rule" or "gateway" record changes]

### Specific to hosts running SIP traces. ###

To start traces:

1. install the ccnq3-traces package
2. configure the fields in this section
3. add "applications/traces" to the applications field
4. make sure users who need to run traces have the "access:traces:" role.

Installation note: this is not enabled by default even after you install the ccnq3-traces package.
You must specify which interfaces will be used for traces by using the `traces.interfaces` array.

*   `traces`:

    * `interfaces`: [] of interfaces names

    There's no reason to modify the following parameters for traces.

    * `filesize`: integer, maximum size of the sniffer traces (in ko) [default: 10000]
    * `ringsize`: integer, maximum number of sniffer trace files [default: 50]
    * `workdir`: string, directory used to store the traces [default: "/opt/ccnq3/traces"]
    * `filter`: string, pcap filter for traces [default: ports used by ccnq3 applications]

    To obtain data from the trace files, use `traces.run`.

    * `run`: {} of traces to run; the index is the TCP port number; content:

        * `to_user`     string; To username (destination number)
        * `from_user`   string; From username (calling number)
        * `call_id`     string; Call-ID
        * `days_ago`    integer; only lookup for this number of days ago (0 = today)
        * `format`      string; either 'pcap' or 'json'

        For each entry in `traces.run`, a single-shot web server will be started on the specified port number.
        That server will send back either a JSON or a PCAP document which will contain packets found
        in the available trace files on the server.
        (Since the trace files are rotated to not exceed a given disk space, it is possible that a
        trace might not be found even though a call was placed.)

        The JSON ouput is an array of hash record; the records might contain the following fields:
            "frame.time"
            "ip.version"
            "ip.dsfield.dscp"
            "ip.src"
            "ip.dst"
            "ip.proto"
            "udp.srcport"
            "udp.dstport"
            "sip.Call-ID"
            "sip.Request-Line"
            "sip.Method"
            "sip.r-uri.user"
            "sip.r-uri.host"
            "sip.r-uri.port"
            "sip.Status-Line"
            "sip.Status-Code"
            "sip.to.user"
            "sip.from.user"
            "sip.From"
            "sip.To"
            "sip.contact.addr"
            "sip.User-Agent"
        To obtain the complete data use the PCAP download.

        Application note: this type of request is highly CPU intensive for the target host.
        It is only meant as a troubleshooting tool for administrators, not as a generically available service.
        Use the cdr database to obtain per-call information as a generic service.

### Specific to hosts running as registrants. ###

Related: applications/registrant

*   `registrant`:

    * `local_ipv4`: string, IP where to send incoming calls (generally the local server)

    * `local_port`: integer, port where to send incoming calls (generally, the port of the local `sip_profile` that accepts those calls)

    * `proxy_port`: integer, the port for this SIP service [default: 5070]

    * `source_ip`: string, IP to send outbound calls from (generally the public IP of the local server)

*   `sip_commands.registrant`: string

    One of:
        "restart"         Restart the registrant server.
        "start"           Start the registrant server.
        "stop"            Stop the registrant server.

    Registrant entries (generated by using the `registrant_password` field in global numbers records) are
    pushed into the registrant's process configuration as they appear; however they are not applied until
    a `restart` command is issued.

### Specific to hosts running as emergency servers. ###

Related: applications/emergency

*   `emergency`: {}

    The configuration hash may be empty, but needs to be present for the service to start.

    * `proxy_port`: integer, the port for this SIP service [default: 5072]

*   `sip_commands.emergency`: string

    One of:
        "start"           Start the emergency server.
        "stop"            Stop the emergency server.

### Specific to hosts running voicemail ###

Voicemail is stored inside a user's own CouchDB database.
This section specifies the parameters for applications/voicemail.

*   `voicemail`:

    * `userdb_base_uri`: string, required; the URI prefix (including authentication for the "voicemail manager") to a user's database.

        The value of the `user_database` field in a local number provisioning record is appended to this prefix.

    * `port`: integer, optional; the (local) port for the voicemail ESL server [default: 7123]

    * `min_duration`: integer, optional; the minimal duration for a voicemail fragment [default: 5]

    * `max_duration`: integer, optional; the maximal duration for a voicemail fragment [default: 300]

    * `min_pin_length`: integer, optional; the minimum length for the PIN (password) [default: 6]

    * `default_language`: language used if none is specified in the sip_profile [default: 'en']

    * `timezone`: timezone used if none is specified in the user's `voicemail_settings` [default: UTC]

    * `number_domain`: string; the default `number_domain` used to identify local numbers if none is available in the call [default: "local"]

      Normally the `number_domain` is passed along with an incoming call to the voicemail server. If for some reason it is not available, this value is used instead.

    * `record_streaming`: boolean;
        if true stream recording of messages (only available with non-encapsulated formats such as "PCMU")
        if false messages are first recorded on the local server then uploaded to the message store
        [default: false]

    * `playback_streaming`: boolean; if true stream playback of messages [default: true]

    * `message_format`: string; voicemail message format [default: "wav"]

      See http://wiki.freeswitch.org/wiki/Mod_native_file for an explanation; meaningul values would be "PCMU" or "PCMA" in most cases, if the default is not suitable.

    * `max_parts`: integer; the maximum number of segments/parts that might be recorded in a voicemail message [default: 1]

    * `sender`: string; the email address used to send email notifications from, if none is specified for a number.

    * `file_base`: string; a prefix used to locate the format files used by the email notifier.

        On Unix this string must be terminated by a slash.

    * `callback`:  Configuration to allow users to call the number that left a voicemail message

      When sending to a proxy, make sure the voicemail server has a matching endpoint record with its "sbc" field set to type 10 so that it is authorized to pass charging information along.

      * `profile`   "ingress-#{profile_name}" or "egress-#{profile_name}", an existing `sip_profile` to use to dial out.

      * `domain`    the domain name where the call should be sent to.

    * `notifier_port`: which local port to bind to for SIP MWI notifications [default: 7124]

#### Voicemail notifications

The notifier will first build filenames by concatenating `voicemail_notification`, `voicemail_notification_with_attachment`, or `voicemail_notification_do_not_record`, then the user's language, then the component of the email message (subject, text body, or HTML body).
For example, for a notification without attachment nor `do_not_record` flag, using language 'en', the following filenames will be used:
    voicemail_notification.en.subject, voicemail_notification.en.body, voicemail_notification.en.html

The notifier will then try to locate those filenames.
If the local host's configuration contains attachments with those filenames, these attachments will be used as templates.
If not found as attachment, but present on the filesystem at the path specified by `file_base`, the content of those files will be used as templates.
Otherwise default templates (in English) will be used.

The templates are [Mustache](http://mustache.github.com/mustache.5.html) templates.
The parameters for the template will consist of the content of the voicemail message record. (See the "voicemail records" section below.)

Especially the following parameters are available:

    caller_id
    timestamp

The default templates are:

* `voicemail_notification.en.subject`, `voicemail_notification_with_attachment.en.subject`:

      New message from {{caller_id}}

* `voicemail_notification.en.body`, `voicemail_notification_with_attachment.en.body`:

      You have a new message from {{caller_id}}

* `voicemail_notification.en.html`, `voicemail_notification_with_attachment.en.html`:

      <p>You have a new message from {{caller_id}}

### Specific to hosts running the voicemail-store ###

The `voicemail-store` service must be ran on a manager host.

The service is responsible for managing the user databases (see below the section about *user database*) that store individual voicemail messages and need to be created correctly for that purpose.

*   `voicemail`

    * `userdb_base_uri`: base URI (with admin access) where to create the users' databases.

### Specific to hosts running the cdrs (CDR aggregation) service. ###

To activate the CDR aggregation service:
1. Set the "aggregate.cdrs_uri" URI in the target host; make sure the CouchDB system has enough storage.
2. Add "applications/cdrs" to the list of applications on the target host. Restart the ccnq3 service to activate.
3. On each source host (hosts which are running FreeSwitch and generating global CDRs; normally your inbound-carrier and outbound-carrier SBCs), set the "cdr_aggregate_uri" to the target's host URI, with the local (source) host authentication.

For example
on the target host, set "aggregate.cdrs_uri" to http://admin:password@target.example.net/cdrs
on the source host, set "cdr_aggregate_uri" to http://host%40source.example.net@target.example.net/cdrs
(both URIs point to the same database, but the authentication is different).

*   `aggregate`

    * `cdrs_uri`: string;  URI for the database where the CDRs should be aggregated [no default]

        The URI must contain authentication (it is used e.g. to create the database)

### Specific to hosts running the locations (Location aggregation) service. ###

To activate the locations aggregation service:
1. Set the "aggregate.locations_uri" URI in the target host.
2. Add "applications/locations" to the list of applications on the target host. Restart the ccnq3 service to activate.
3. On each source host (hosts which are running OpenSIPS with registration), set the "opensips_proxy.usrloc_aggregate_uri" to the target's host URI, with the local (source) host authentication.

For example
on the target host, set "aggregate.locations_uri" to http://admin:password@target.example.net/locations
on the source host, set "opensips_proxy.usrloc_aggregate_uri" to http://host%40source.example.net@target.example.net/locations
(both URIs point to the same database, but the authentication is different).

*   `aggregate`

    * `locations_uri`

### Specific to hosts running the CNAM-client ###

*   `cnam_client`:
    * `port`    FreeSwitch ESL `socket` port [default: 7124]
    * `uri`     URI to query

### Attachments ###

Attachments of type "application/javascript" are executed after each change.
The attachments might use any core Node.js modules.

FIXME test this feature


domain (provisioning records)
-----------------------------

These records are normally used to populate the DNS server ("applications/dns").

Alternatively, if "support_alternate_domains" is enabled in the OpenSIPS configuration,
an OpenSIPS server will accept any domain listed here.
(By default only sip_domain_name is accepted.)

*   `_id`: type+":"+domain

*   `account`: ""    (the empty string)

*   `type`:"domain"

*   `domain`: string; the name of the DNS domain

### ccnq3-dns service

  If "applications/dns" is configured on the host, "domain" provisioning records may be used to populate DNS records.
  In this case the "account" field is optional (which can only be done on the main provisioning database).
  The following fields are available:

*   `ENUM`: boolean; true if the domain is to be used to provide "number"-type records as a Carrier ENUM service

*   `ttl`: integer, time-to-live for the records

      Application note: For an ENUM domain, the ttl will influence how the database changes are propagated. It is better to keep it low in that case.

*   `admin`: optional string, the contact value of the domain's SOA [default: "hostmaster."+domain]

*   `records`: [] of {}; the fields of the records are as follows:

    * `prefix`: a prefix to the domain (local name) [optional]

    * `ttl`: integer, individual record's ttl [overrides domain's default]

    * `class`: "A", "NS", etc. [default: "A"] (only "IN" classes are supported)

    * `value`: either a string (if only one value is provided, for example for A, CNAME, NS, etc.), or an array of response values.

      An array value is used for example for SRV records or NAPTR records.

Example:

    records: [
      {class:'NS', value:'ns1.example.net.'}
      {class:'NS', value:'ns2.example.net.'}
      {prefix:'s1',value:'192.168.1.10'}
      {prefix:'_sip._udp',class:'SRV',value:[20,7,5060,"sip1.example.net."]}
      {class:"NAPTR",value:[20,10,'u','E2U+sip',"!^.*$!sip:foo@example.net!", ""]

    ]

By design "applications/dns" runs on port 53053. To allow remote hosts to access the application on port 53, install the ccnq3-dns package.

account_forwarder (provisioning records)
----------------------------------------

For non-trusted host that are allowed to submit P-Charge-Info, list of accounts they may submit.

*   `_id`: type+":"+account+'@'+endpoint
*   `account`: account
*   `type`:"account_forwarder"
*   `endpoint`: endpoint

endpoint (provisioning records)
-------------------------------

*   `_id`: type+":"+endpoint

*   `account`: string

*   `type`:"endpoint"

*   `endpoint`: string, required; either a static IP, or a user@domain registration username

    If a static IP, it must be identical to the user_ip field.

    If a registration endpoint, password, ha1, and ha1b are required.

### Registration endpoint fields ###

*   `password`: string; password used for authentication, or null if authentication not used

*   `ha1`: authentication string; hex_md5([username,challenge,password].join(":"))

*   `ha1b`: authentication string; hex_md5([username+'@'+challenge,challenge,password].join(":"))

If the "challenge" configuration parameter is empty (the default), the domain name of the To: header (for REGISTER) or From: header (for other messages) is used as the challenge. In other words: normally the challenge should be the same as the domain name used for the endpoint.

*   `bypass_from_auth`:  boolean
    Applies to authorized calls coming from this endpoint.
    If false (the default), the From username must equal the Authentication ID, otherwise the call is rejected.
    If true, the From username is not checked. In this case you probably want to enable `check_from` (below) to ensure that the From username is valid.

### Static endpoint fields ###

*   `user_ip`         string  Static endpoint's IP address [required for static endpoints]

    Must be identical to the endpoint field if used.

*   `user_port`       integer Static endpoint's port number [optional]

*   `disabled`        boolean If true, this IP is prevented from talking to the switch.
    (Used to build a black-list of IP addresses.)

### Inbound call routing (dst_endpoint) ###

*   `dst_disabled`    boolean If true, calls towards this endpoint are blocked

*   `strip_digit`     boolean If true, remove the first digit of the destination username

*   `user_force_mp`   boolean If true, attempt to force media_proxy insertion

*   `user_srv`        string  Final user's domain (compatible with user_via)

    Design note: a valid design to allow for easy migration of customers IP addresses
    is to have:

    * one endpoint with an identifier (not an IP address nor a `username@domain`)
      which is used to route inbound calls; that endpoint uses the `user_srv` field
      to terminate the calls on the proper customer system;
    * one or more endpoints (using IP addresses as identifiers) to allow these
      IP addresses to route outbound calls.

    With this design a customer can migrate IP addresses temporarily or permanently by:
    * adding or removing the IP addresses (used for outbound calls)
    * updating the `user_srv` field of the endpoint used for inbound calls.

*   `user_via`        string  If present, calls are routed via this SBC

    Usage note: This requires a type of SBC which has not yet been ported to ccnq3.

### Outbound call routing (src_endpoint)

*   `number_domain`: string; the local number's `number_domain` [default: the proxy's `number_domain`]

    Used to locate a local number's record.

*   `dialog_timer`: integer; maximum call (dialog) duration (in seconds)

*   `outbound_route`: integer

    See the description under *Rule (provisioning record)*.

*   `check_from`      boolean
    If true, the call can only be placed if the endpoint for the From username is the same as this endpoint.

*   `sbc`             integer This endpoint is an outbound SBC that sends calls to us towards a carrier.

    Our own outbound SBCs
    *  1: SBC provides originator endpoint information as Sock-Info or source RURI param
    *  2: SBC provides account info in P-Charge-Info (no checks) (for example, a client-sbc)

    Customer outbound SBCs
    * 10: SBC provides account info in P-Charge-Info, account is checked against account_forwarder

*   `inbound_sbc`     integer This endpoint is an inbound SBC that sends calls to us from a carrier.

    Our own inbound SBCs
    *  1: upstream SBC [inbound]

*   `location`        string  An identifier for a location record

    Might be overriden by the calling number's location.

*   `src_disabled`    boolean All outbound calls are disabled.

*   `user_force_mp`   boolean If true, attempt to force media_proxy insertion

*   `emergency_domain`: string

    This domain is used when an outbound-proxy sends a query to an emergency server.
    The emergency server will use this domain in its 302 Redirect response to the outbound-proxy.
    (Configure this field in the endpoints that are defined for the outbound proxies.)


number (provisioning records)
-----------------------------

*   `_id`: type+":"+number

*   `account`: string [required]

*   `type`:"number"

*   `number`: string

      For global numbers (between a carrier-sbc and a client-sbc), formatted as "E.164-without-plus".

      For client-side local-numbers, a locally-formatted number @ the client-sbc's `number_domain`.

### Global-number properties ###

*   `inbound_uri`: string (URI)  a URI used by an outbound-proxy to bypass LCR and route a number directly, or an inbound Carrier SBC to route the number.

    These are used to build Carrier ENUM records.

*   `outbound_route`: integer; allows to select a specific `rule` based on the rule's `groupid`.

    For a global number this indicates the LCR route that will be selected to route the call out.

    If a number has no `outbound_route`, the `outbound_route` of the endpoint (sending SBC) is used.
    If the number and the endpoint both have `outbound_route`, the two rule sets are used in order.
    See additional information in *Rule (provisioning record)*.

*   `registrant_password`: password for applications/registrant

    You must issue a `restart` registrant command for the changes to be applied.

*   `registrant_remote_ipv4`: remote server for applications/registrant

*   `registrant_host`: host(s) where this registration should be effective

    This parameter can actually be either a string (single host) or an array of strings (multiple hosts).

*   `registrant_expiry`: integer, expiry parameter, in seconds [default: 3600, one hour]

*   `registrant_realm`: string; the `realm` used to authenticate outbound calls through the registrant server.

Please note that for a number to use the registrant function, both `registrant_password` and `registrant_host` must be specified.


### Local-number properties ###

*   `endpoint` [required]

*   `outbound_route`: integer; allows to select a specific `rule` based on the rule's `groupid`.

    For a local number this is used to define the local dialplan, including call restrictions, access to voicemail and services, ...

    If a number has no `outbound_route`, the `outbound_route` of the endpoint is used.
    If the number and the endpoint both have `outbound_route`, the two rule sets are tried in order.
    See additional information in *Rule (provisioning record)*.

*   `location`:  string; the location identifier for this specific number (used for emergency location services)

    If present, overrides the endpoint's location.

*   `cfa`:  string, URI; if present, all calls are forwarded to this URI

*   `cfb`:  string, URI; if present, busy calls are forwarded to this URI

*   `cfda`: string, URI; if present, unanswered calls are forwarded to this URI

*   `cfnr`: string, URI; if present, non-registered endpoints are forwarded to this URI

*   `dialog_timer`: integer; maximum call duration

*   `inv_timer`: integer; maximum ringback duration

*   `privacy`: boolean

    If true, a Privacy: id (mask calling number) header is added to outbound calls

*   `asserted_number`: string

    If present, a P-Asserted-Identity (Caller-ID) header is added to outbound calls

*   `reject_anonymous`: boolean

    If true, reject anonymous inbound calls

*   `use_blacklist`: boolean

    If true, reject inbound calls from the blacklist

*   `use_whitelist`: boolean

    If true, accept inbound calls from the whitelist

*   `user_database`:  string; the name of the user's own CouchDB instance (for the user who "owns" this number)

    This database is used by the voicemail system to locate the voicemail_settings record and record or playback voicemail
    messages.

*   `voicemail_sender`: string; the email address used to send out voicemail notifications for this number

    If not present, the "voicemail.sender" configuration parameter of the host running voicemail is used.
    If neither are present, the recipient's email address is used as as stop-gap.


whitelist/blacklist (provisioning records)
------------------------------------------

A local number may reject or accept calls from specific numbers.

*   `_id`: type+':'+number+'@'+calling_number

*   `type`: 'list'

*   `number`: string; a local number '@' number_domain

*   `calling_number`: string; a locally-formatted calling number

*   `blacklist`: boolean

*   `whitelist`: boolean

Either (or both) of `blacklist` and/or `whitelist` must be true for the matching action to be taken.

rule (provisioning records)
---------------------------

Rules are used to route outbound calls in OpenSIPS.

### Which rule sets are selected ###

When a call has to be routed towards a trunk, one or two rule sets might be applied:

* the rule set indicated by the `outbound_route` of the `number`, if any;
* the rule set indicated by the `outbound_route` of the `endpoint`, if any.

If no `outbound_route` is provided, or both rule sets are unable to route the call (no matching prefix, etc.), the call is rejected with `404 User Not Found` (local number) or `502 No Route` (global number).

The first matching rule selected (either from the number's `outbound_route` rule-set, or from the endpoint's `outbound_route` rule-set) is used to route the call.

### How rules are matched ###

Out of all the rules in a rule set, at most one will eventually be selected.

The selection criterias are described under *Rule selection* below.

### How routing is done ###

Once a rule is selected, the call is forwarded to the destination gateway(s) or carrier(s) for that rule.

Carrier's names are pre-pended with a hash `#` sign, while gateway names are inserted as-is, separated by comma `,`. (But remember that carrier and gateway names must be alphanumeric.)

Although `rule`s and `gateway`s are defined on a per-`sip_domain_name` basis, carriers defined on a per-`host` basis.
This allows you do have domain-generic routes and gateways, but each host can route to a preferred set of gateways (e.g. closest-gateway first) if desired. In that last case, make sure you assign higher weights to the preferred gateways for each `carrier`.

The `attrs` field of the selected rule is made available in the CDRs.
This feature can be used for example to store rating information so that they do not need to be looked up again (using longest-prefix match) at rating time.

Operational note:
Changes to rules, gateways, and carriers are not applied automatically. Use `sip_commands.opensips = "reload routes"`` to apply the changes.

### Rule identifiers ###

*   `_id`: type+":"+rule

*   `account`: ""    (the empty string)

*   `type`: "rule"

*   `rule`:

    Either, if no `timerec` field is present:

        sip_domain_name+":"+groupid+":"+prefix

    or, if a `timerec` field is present:

        sip_domain_name+":"+groupid+":"+prefix+":"+timerec+":"+priority

*   `sip_domain_name`: the `sip_domain_name` of the hosts on which OpenSIPS is running and using this rule/`outbound_route`

### Rule selection ###

The following four fields are used to select a rule.
The set of applicable rules is narrowed down as each field is applied in order.

*   `groupid`: integer; this is the `outbound_route` of the number or endpoint. All rules with the same `groupid` constitute a rule set.

    Although it seems OpenSIPS might support having one or more groupid for a given rule we currently do not support this option.

*   `prefix`: string; the routing (destination number) prefix (might be ""), longest-prefix match

*   `timerec`: string; a time specification [optional; defaults to ""]

*   `priority`: integer; ruleset ordering criteria (within the groupid and prefix, for matching `timerec`s, the rule with the highest priority is chosen) [optional; defaults to 1]

At the end of the selection process, at most one rule is selected from the rule set.

For the complete specification, see section *Routing Rule Processing* in <http://www.opensips.org/html/docs/modules/1.8.x/drouting.html>

### Rule output ###

The following fields are the output of the selection process, and are used to route the call, once a rule has been selected.

The gateway list indicates which gateways (either `gateway` records or `egress_gwid` sip_profiles) are used to route the call.

*   `gwlist`: string; a comma-separated list of gateways or carriers.

    Carrier IDs must be prefixed with a `#`. Weight are assigned by following the `gwid` or `carrierid` with `=` and a numerical weight.

    Examples:

        "gw1,gw2,#car1"

        "gw1=25,gw2=25,#car1=50"

    The gateways and/or carriers specified in the rule are tried in the order given.

*   `attrs`: string [default: the empty string]
    This output field is present in the call's CDR as `variables.ccnq_attrs` on outbound calls.

carrier (provisioning records)
------------------------------

Carriers are used by the Least Cost Rules as targets for call routing.

Operational note:
Changes to rules, gateways, and carriers are not applied automatically. Use sip_commands.opensips = "reload routes" to apply the changes.

*   `_id`: type+":"+carrier

*   `account`: ""    (the empty string)

*   `type`: "carrier"

*   `carrier`: host+":"+carrierid

*   `host`: string; the `host` on which OpenSIPS is running and using this carrier.

*   `carrierid`: alphanumerical; a unique identifier for the carrier inside this `sip_domain_name`; used in the `gwlist` field of a `rule` record (prefixed with `#`).

*   `gwlist`: the comma-separated list of `gwid` for the target gateways.

    To assign weights to the gateways append `=` and a numerical weight after each `gwid`.

    Examples:

        `gw1,gw2,gw3`

        `gw1=25,gw2=25,gw3=50`

The following fields are optional.

*   `flags`: integer [default: 0]

    The following flags are supported; you normally do not need to modify the default.

    1 - if set, use weights for sorting; if not set [default], uses `gwlist` order
    2 - if set, after sorting, use only the first gateway; if not set [default], after sorting, try all gateways
    4 - if set, disable this carrier; if not set [default], enable this carrier

    (Add the numerical values of the flags if multiple are set.)

*   `attrs`:  string

gateway (provisioning records)
------------------------------

Gateways are used by the Least Cost Rules as targets for call routing.

You do not need to create gateway records for sip_profiles which have an `egress_gwid` field, these are created automatically using the host's `sip_domain_name` and the `egress_gwid`. (They will not show up in the database but will be accessible to all the OpenSIPS hosts within that `sip_domain_name`.)
This feature means that you normally should not have to manually create `gateway`-type records for Least Cost Routing, since all the interesting records should be created automatically.

However you will have to create gateway records for calls to servers in a different `sip_domain_name` such as voicemail servers or emergency servers.

Operational note:
Changes to rules, gateways, and carriers are not applied automatically. Use sip_commands.opensips = "reload routes" to apply the changes.

*   `_id`: type+":"+gateway

*   `account`: ""    (the empty string)

*   `type`: "gateway"

*   `gateway`: sip_domain_name+":"+gwid

*   `sip_domain_name`: the sip_domain_name of the hosts on which OpenSIPS is running and using this gateway.

*   `gwid`: alphanumerical; a unique identifier for the gateway inside this sip_domain_name; used in the `gwlist` field of a `rule` record or in the `gwlist` field of a `carrier` record.

    *Alphanumerical* means the `gwid` (or `egress_gwid` for that matter) must only contain the following ASCII characters: `a` through `z`, `A` through `Z`, `0` through `9`, and the underscore `_`. Any other character in a gateway id will cause OpenSIPS to crash.

*   `address`: the address of the gateway (IP, IP:port, etc.)

The following fields are optional.

*   `probe_mode`: 0

    The following modes are available:
      0: no probing
      1: probing only when disabled (however our scripts do not use dr_disable())
      2: probing at all times

*   `strip`: 0

*   `pri_prefix`:  string

*   `attrs`: string; currently has a special meaning, do not use.

location (provisioning records)
-------------------------------

*   `_id`: type+":"+location

*   `account`: string

*   `type`: "location"

*   `location`:  string; a unique identifier for this location

*   `routing_data`:  string; specific to the emergency routing system used

    In France this would be the INSEE code of the commune.

emergency (provisioning records)
--------------------------------

This is currently used to implement a French emergency call router.

These records are used by the `applications/emergency` application.

* `_id`: type + ":" + number + "#" + routing_data

* `type`: "emergency"

* `number`: string

    In France this could for example be a local number "112", or (more probably) a global number "330112".

    Implementation note:
    The prefix "330" is used in our French dialplan to allow OpenSIPS to route emergency calls using its standard Least Cost Routing module,
    which does not allow anything but digits as the routing element.

* `routing_data`: string, matching the routing_data field of the location record.

    In France this would be the INSEE code of the commune.

* `destination`: string; a target phone number expressed in the emergency_domain of the server that sent the request.

    The Contact URI returned by the emergency sever in its 302 message will consist of `destination`@`emergency_domain`.

    The `emergency_domain` used is the one found in the `endpoint` record for the host that sent the INVITE message to
    the emergency server.


_users database
===============

The `_users` database is CouchDB's standard authentication and authorization database.

Authentication is provided by setting the `password` field in a user record.

Authorization is provided by setting the `roles` field in a user record.

host records
------------

These records are used to allow hosts (servers) within the system access to some functionality:

* replicate the provisioning database from the master to their local copies;
* replicate their local CDRs onto a master CDR database;
* replicate their local database of user locations onto a master `locations` database.

The records follow the format outlined in the previous section.
They are documented here separately for convenience.

Servers should have the `host` role assigned.

* `_id`: "org.couchd.user:"+name
* `type`: "user"
* `name`: "host@" + hostname
* `password`
* `roles`: ["host"]

voicemail records
-----------------

These records are used to allow voicemail servers access to:

* read and update voicemail settings and voicemail messages in a *user database*;
* read the `_users` database to list `user_database` fields.

Their `_users` profile is as follows:

* `_id`: "org.couchd.user:"+name
* `type`: "user"
* `name`: "voicemail@" + hostname
* `password`
* `roles`: ["update:user_db:","access:_users:"]

Other records
-------------

Regular `_user` record may also contain:

* `user_database`: the name of a *user database* this user has access to. (These are maintained by the `voicemail-store` application.)

endpoint-location database
==========================

The record in this database are read-only.
(In other words you should not attempt to modify them.)
They are updated by OpenSIPS.

There should be one location database local to each OpenSIPS server that provides registration services.

Additionally the locations records might be aggregated in a central `locations` database, see the documentation for `locations_aggregate_uri`.

endpoint-location records
-------------------------

Identifier

*   `id`: username+"@"+domain (registration username)
*   `username`: string; username part of the registration username@domain
*   `domain`: string; domain part of the registration username@domain

Information received from the client

*   `callid`: string
*   `contact`: string
*   `cseq`: integer
*   `q`: integer (-1 if none is provided by the endpoint)
*   `user_agent`: string

Information stored by the server to manage the registration

*   `last_modified`: string (datetime, UTC)
*   `expires`: string (datetime, UTC)
*   `received`: string (IP:port from which the registration packet originated)
*   `socket`: string (IP:port on which we received the registration packet)
*   `methods`: integer
*   `path`: string
*   `cflags`: integer
*   `flags`: 0

user database
=============

Each user is assigned a private *user database*.

> Usage note: *user databases* are named using the convention "u"+UUID.
> If your application creates user databases make sure to follow that convention as well.
>
> Additionally, note that a single user database may be shared by multiple users.

An application may create the database itself (server-side) using the standard CouchDB API, if it has database-level administrative access.
However databases created that way are world-readable; it is your responsability to ensure that the database will get proper security tokens.

voicemail_settings record
-------------------------

A user's voicemail settings are stored in this record.

*   `_id`: 'voicemail_settings'

*   `pin`: string of digits; the user's voicemail PIN [optional]

    If no "pin" is specified then no authentication is required to access the voicemail box.

*   `language`: language string for this user's voicemail

*   `timezone`: timezone string for this user's voicemail

*   `email_notifications`: hash; the key is the target email address; the values should be a hash containing:

    * `attach_message`: boolean; if true the voice message is sent along with the notification

* `do_not_record`: boolean; if true, no voice messages are recorded, only the prompts are played

* `send_then_delete`: boolean; if true, the message is removed after an email is sent, as long as the email contains the message as attachments (`attach_message` is true) or no message was recorded (`do_not_record` is true).

  If neither `attach_message` or `send_then_delete` is true, this option is ignored.

*   `_attachments`:

    * `prompt.wav`  voicemail prompt
    * `name.wav`    name prompt

voicemail records
-----------------

Each new voicemail message is stored in an individual voicemail record.

*   `_id`: type + timestamp + caller_id

*   `type`: 'voicemail'

*   `timestamp`: string; JSON timestamp e.g. "2012-02-13T14:05:21.247Z"

*   `caller_id`: string; caller_id

*   `box`: string; 'new' or 'archive'

*   `_attachments`:

    The fragments of the message, in the order they were recorded.

    * `part1.wav`
    * `part2.wav`
    * etc.

    The message may contain no fragments if none was recorded or it was too short.

    By default (`max_parts` == 1) only one fragment is recorded, so only `part1.wav` might be present.

    The filename extension depends on the voicemail server's `format` setting. It defaults to `wav`.

API
===

CouchDB API
-----------

The native CouchDB API is available to a server-side or client-side application.

Extended API
------------

Integrated with CouchDB is a set of ccnq3-specific APIs accessible using the same URI as the CouchDB instance on the manager host.
Make sure `applications/couchdb_daemon` is enabled for these APIs to be available via CouchDB.

The API calls are authentified using the Basic Authentication header and regular CouchDB username and password (the content of the authentication header is used by the APIs to authenticate their calls to CouchDB).

This API offers the following functions:

### Test

`GET /_ccnq3`

### Voicemail box creation

`PUT /_ccnq3/voicemail/:local_number`

  Create a voicemail box for the specified local number, if none exist.

  The PUT body is merged with any `voicemail_settings` document in the local number's `user_database`.

  Return a JSON content with a `user_database` field on success.

  Note: `applications/voicemail-store` must be installed for the user database to be properly initialized.
