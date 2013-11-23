Conventions
===========

Most commands on this page must be ran as root. The only exception would be the `gpg` commands; in that case make sure you run `apt-key` as root.

Requirements
============

Base system
-----------

Your base system _must_ be a current Debian/testing system.

Hostnames and DNS
-----------------

Hostnames for the different servers MUST be:

1. FQDN (e.g. "server.example.com", not "server")
2. Valid DNS names (that resolve using A and/or AAAA queries)

These are both required to ensure clients can properly access the server.

Note: compare the output of

    cat /etc/hostname
    hostname
    hostname --fqdn

to make sure they all report the name you expect.

Note: ccnq3 contains a DNS server package that will automatically provide proper records for all servers configured in the system, so this requirement can be met relatively easily.  See below for more information on `ccnq3_dns`.

Required Services
-----------------

You MUST have a reliable clock on the system. This is necessary to do proper billing and greatly facilitates troubleshooting. Therefor:

    aptitude install ntp ntpdate

IPv6
====

The Node.js packages downloaded during installation are downloaded from hosts that do not support IPv6 (for example github.com, or the npm registry).

Therefor installation and upgrades _must_ currently be done with some kind of connectivity to the global IPv4 network.

Add Repository
==============

Add

    deb http://debian.sotelips.net/shimaore shimaore main

to your existing /etc/apt/sources.list using the following commands:

    aptitude install -y python-software-properties
    REPOSITORY=debian.sotelips.net
    apt-add-repository "deb http://${REPOSITORY}/shimaore shimaore main"

Add Key
=======

Add the GPG key for stephane@shimaore.net, which is used to sign the "shimaore" distribution:

    MAINTAINER='Stephane Alnet (Packaging) <stephane@shimaore.net>'
    # You might need to run the following command twice the first time.
    gpg --recv-keys "F24B9200"
    gpg --armor --export "=${MAINTAINER}" | apt-key add -

Update System, Install Packages
===============================

Update and upgrade your system:

    aptitude update
    aptitude -y dist-upgrade

Start Installation
==================

Finally start the installation of CCNQ3 itself.

"manager" host
--------------

The first host you will install is your "manager" host.

    aptitude -y install ccnq3-manager

Make sure to locate and save the `CCNQ3 Master interface` URL printed at the end of the installation process.

However, this package will overwrite any local CouchDB configuration.  If you have an existing CouchDB/BigCouch installation you'd like to re-use (located on the same host or on a different system), use

    aptitude -y install ccnq3-manager-shared

instead. You will need to provide administrative access to that existing database via a URL such as `http://admin:password@host:5984`.

Normally you should not run voice services on the manager, however if you intend to do so you will need to install the `ccnq3-voice` package as well.

Securing services on the manager host
-------------------------------------

You should use HTTPS and AMQPS services instead of the default, HTTP and AMQP services.

### Traffic Encryption for CouchDB

Note: CouchDB 1.4.0 does not properly support SSL. For now please front-end CouchDB with `stunnel4` instead of using the following procedure.

To enable HTTPS on CouchDB, add the following to `/etc/couchdb/local.ini` and make sure the SSL certificate and private key are available as `/etc/couchdb/cert.pem` and `/etc/couchdb/key.pem`, respectively:

    [daemons]
    httpsd = {couch_httpd, start_link, [https]}

    [ssl]
    cert_file = /etc/couchdb/cert.pem
    key_file = /etc/couchdb/key.pem

Then restart CouchDB (as root):

    /etc/init.d/couchdb restart

This will enable HTTPS access on port 6984. (HTTP access is still available on port 5984 but we recommend you do not use it.)
Make sure to update the URIs in the `provisioning` `host` records to point to the HTTPS URI (`https://....:6984/provisiong` instead of `http://...:5984/provisioning`, etc.).

### Traffic Encryption for RabbitMQ

To enable AMQPS and HTTPS on RabbitMQ, add the following to `/etc/rabbitmq/rabbitmq.config` and make sure the SSL certificate, private key, and CA certificate are available as `/etc/rabbitmq/cert.pem`, `/etc/rabbitmq/key.pem`, and `/etc/rabbitmq/cacert.pem`, respectively:

    [
      {rabbit, [
        {ssl_listeners, [5671]},
        {ssl_options, [{certfile,"/etc/rabbitmq/cert.pem"},
                       {keyfile, "/etc/rabbitmq/key.pem"}]}
      ]},
      {rabbitmq_management, [
        {listener, [
          {port, 55672},
          {ssl, true},
          {ssl_opts, [
            {cacertfile, "/etc/rabbitmq/cacert.pem"},
            {certfile,   "/etc/rabbitmq/cert.pem"},
            {keyfile,    "/etc/rabbitmq/key.pem"}
          ]}
        ]}
      ]}
    ].

This will enable AMQPS access on port 5671, and replace the management HTTP on port 55672 with HTTPS access on the same port. (AMQP access is still available on port 5672 but we recommend you do not use it.)
Make sure to update the URIs in the `provisioning` `host` records to point to the AMQPS URI (`amqps://....:5671/ccnq3` instead of `amqp://..../ccnq3`) and HTTPS URI (`https://....:55672/` instead of `http://....:55672/`).

Client (non-manager) hosts
--------------------------

On a non-manager host you will use:

    aptitude install ccnq3-client

You will need to provide it the URI assigned by the provisioning system.  (See the [provisioning] documentation for how to obtain that URI.)

Installing the `ccnq3-client` package will overwrite any local CouchDB configuration. This package cannot be co-located with non-ccnq3 applications that might use CouchDB.

Client hosts with voice services
--------------------------------

After you complete the steps above for a client host, install:

    aptitude install ccnq3-voice

This will install OpenSIPS, FreeSwitch, and their dependencies.

Alternatively, if you'd rather install OpenSIPS and FreeSwitch on different hosts, do:

    aptitude install ccnq3-voice-freeswitch

or

    aptitude install ccnq3-voice-opensips

If you need mediaproxy on a host running OpenSIPS, you _must_ manually run

    cd "`ccnq3 get_config_source`/common/mediaproxy"
    ./install.sh

because of some important caveats regarding IPv6.

Setup of traces
---------------

If you intend to use the `ccnq3-traces` package (and the `applications/traces` application), make sure the permissions are set properly on `/usr/bin/dumpcap` by running

    dpkg-reconfigure wireshark-common

and selectiong "Yes" when asked "Should non-superusers be able to capture packets?"

Installation of CCNQ3 DNS server
--------------------------------

The CCNQ3 DNS server is a master-only DNS server that must be installed to provide inbound routing for numbers. We recommend you install that service on at least two physically independent servers for redundancy purposes.

The CCNQ3 DNS server uses UDP port 53 and will conflict with any other application, such as another DNS server, which would use that port. Therefor make sure there are no other DNS resolver or proxy on the host where you install the CCNQ3 DNS server.

Moreover you should not have the local host rely on the service provided by the CCNQ3 DNS server for its name resolution, since the service will not forward requests or provide recursive resolution.

Therefor the host(s) that run the CCNQ3 DNS service _must_ use non-local nameservers; make sure to configure those in `/etc/resolv.conf`.

Additionally install the `ccnq3-dns` package on any host running the CCNQ3 DNS server:

    aptitude install ccnq3-dns

This package will forward UDP port 53 to UDP port 53053 on the local host.

Next steps
----------

The base system is installation is now complete.

For more information and follow-up steps refer to the [provisioning] documentation.

The following sections provide additional information but are not required.

Automated (scripted) installation
=================================

You may provide the URI for `ccnq3-client` in `/etc/ccnq3/uri` before installing the package.

You may provide the URI for `ccnq3-manager-shared` in `/etc/ccnq3/admin_uri` before installing the package.

Tune-Up
=======

Additionally I recommend modifying the rsyslog configuration to either a centralized syslog server, or a smaller local configuration such as:

    tee /etc/rsyslog.conf >/dev/null <<'EOT'
    $ModLoad imuxsock # provides support for local system logging
    $ModLoad imklog   # provides kernel logging support (previously done by rklogd)
    $ActionFileDefaultTemplate RSYSLOG_TraditionalFileFormat
    $SystemLogRateLimitInterval 0
    $SystemLogRateLimitBurst 0
    $FileOwner root
    $FileGroup adm
    $FileCreateMode 0640
    $DirCreateMode 0755
    auth,authpriv.*             /var/log/auth.log
    *.info;auth,authpriv.none  -/var/log/syslog
    # Uncomment the following line to gather debug messages
    # *.debug                  -/var/log/debug
    EOT

    /etc/init.d/rsyslog restart

Alternative ways
================

Add repository
--------------

You may manually add the `shimaore` repository as follows:

    REPOSITORY=${REPOSITORY:-debian.sotelips.net}
    tee -a /etc/apt/sources.list > /dev/null <<EOT
    deb http://${REPOSITORY}/shimaore shimaore main
    EOT

Add key
-------

You may manually install the proper GPG key as follows:

    apt-key add - <<'GPG'
    -----BEGIN PGP PUBLIC KEY BLOCK-----
    Version: GnuPG v1.4.11 (GNU/Linux)

    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
    3FuSepTWd4opF5wgYQ3ZtPM=
    =+BNA
    -----END PGP PUBLIC KEY BLOCK-----
    GPG
