About
=====

This document is a quick guide meant to show you how to bootstrap your system. It runs you through the tools available to manually edit records.

It is however your responsability to write a proper provisioning front-end for your administrative users and your customers. CCNQ3 only provides the API.

Example layout
--------------

In this document we will assume that your main domain for installation is `phone.example.net`. IP Addresses are assigned from a block in RFC5737 as follows:

    vm1.phone.example.net  198.51.100.51
    vm2.phone.example.net  198.51.100.52
    vm3.phone.example.net  198.51.100.53

We will use two SIP domains, `a.phone.example.net` for client-side, and `trunk.phone.example.net` for the carrier-side.

Host `vm1` will be the manager host; host `vm2` will be a client-side server, and host `vm3` will be a carrier-side server.

Note: In a realistic deployment at least the two voice servers would be duplicated to provide redundancy.

Conventions in this document
============================

Running as user `ccnq3`
-----------------------

The `ccnq3` commands must be issued as user `ccnq3`. You can either do:

    sudo -u ccnq3   <command>

or run a shell as the `ccnq3` user and type the commands in that shell:

    su -s /bin/bash ccnq3

Accessing the CouchDB interface `Futon`
---------------------------------------

CouchDB provides a web interface. The `Futon` database manager is available as `/_utils/` on the server that runs your master CouchDB service.

For example:

    http://vm1.example.net:5984/_utils/

If you installed SSL for CouchDB, use instead:

    https://vm1.example.net:6984/_utils/

Prerequisites
=============

The following steps must be performed after the steps in [the installation document](install), which explains how to install the packages and bootstrap the servers.

Create a managing user
----------------------

We recommend you use your email address as identifier for the CouchDB database.

Run the following commands as user `ccnq3`, replacing `bob@example.net` and `my_password` with your email address and the password you would like to use to access CouchDB, respectively:

    ccnq3 'add user' bob@example.net my_password
    ccnq3 'admin' bob@example.net

DNS
===

The following step is to enable the `ccnq3_dns` service, which will provide dedicated
DNS responses based on your provisioning data.

Standard DNS layout
-------------------

We recommend that most hosts use a locally-installed DNS cache resolver (such as the plain bind9
package). Their /etc/resolv.conf file should therefor contain:

    nameserver 127.0.0.1

These hosts will require no further changes related to DNS.

Hosts running the `ccnq3_dns` service
-------------------------------------

The environment contains a dynamic, database-driven, DNS service which must be enabled on at least one host. These DNS-serving hosts must be configured with the `applications/dns` application. Additionally, the `ccnq3-dns` package must installed on these DNS-serving hosts.

See the [installation documentation](installation) for more details on how to configure these servers.

Domains to be created
---------------------

Most DNS entries are dynamically created based on the configuration stored in the CouchDB database.

However you must manually create two records in the provisioning database:

* one record for the main domain `phone.example.net`
* one record for the subdomain `enum.phone.example.net`

Using `Futon`, insert two records layed out as follows into the `provisioning` database. To do so, open `Futon`, open the `provisioning` database, then click `New document`. In the new document, switch to the `Source` tab, double-click the content and paste the record content. Once done, click `Save document`.

Record #1:

    {
      "_id":"domain:phone.example.net",
      "type":"domain"
      "domain":"phone.example.net",
      "records":[
        {"class":"NS","value":"vm1.phone.example.net"}
      ]
    }

Record #2:

    {
      "_id":"domain:enum.phone.example.net",
      "type":"domain",
      "domain":"enum.phone.example.net",
      "ttl":60,
      "ENUM":true,
      "records":[
        {"class":"NS","value":"vm1.phone.example.net"}
      ]
    }

Notes:

* Any DNS-serving host, with `applications/dns` listed as an application, should be listed as `NS`. In a realistic deployment you MUST have more than one such host.

Add a new "voice" host
======================

* On the manager server, run the following command as user `ccnq3` to add an entry for host `vm2.phone.example.net`:

      ccnq3 add_host vm2.phone.example.net

  (You may run the script multiple times.)

  The script will print out the `Host CouchDB URI`. Copy that value.

* On the host, install the `ccnq3-client` package. During the installation process you will be asked to provide the URL you copied in the previous step.

* After the packages are installed, on the new host, as the `ccnq3` user do:

      cat /etc/ccnq3/host.json

  Copy the output of the command (a JSON record starting with `{` and ending with `}`).

* Using `Futon`, open the `provisioning` database. In the `Jump to:` field, type `host:` followed by the hostname, and Enter to open that record.
  In the record, switch to the `Source` tab, double-click the JSON source content, and paste the JSON record you copied in the previous step.
  Click `Save Document`.

* Still in the host document, switch to the `Fields` tab, click `Add Field`, enter `sip_domain_name` for the field and `a.phone.example.net` for the value.

* Still in the `Field` tab, the `applications` array should be extended to contain at least (in the following order):

      [
        "applications/host",
        "applications/freeswitch",
        "applications/opensips",
        "applications/traces"
      ]

* `Add Field` named `opensips` with its value set to:

      {
        "model": "complete"
      }

* `Add Field` named `traces` with its value set to:

      {
        "interfaces": [ "eth0" ]
      }

  (assuming the main interface is called `eth0`).

* Click on `Save Document`.

* On the host, run as `root`:

      sudo aptitude install ccnq3-voice
      sudo aptitude reinstall ccnq3
      # Normally at this point, freeswitch and opensips are still not running.
      sudo /etc/init.d/opensips start
      sudo /etc/init.d/freeswitch start
      # If running MediaProxy:
      sudo /etc/init.d/mediaproxy-dispatcher restart
      sudo /etc/init.d/mediaproxy-relay restart

Add a registering endpoint record to test the new setup
=======================================================

* Using `Futon`, open the database `provisioning`, click `New Document`, switch to the `Source` tab and enter:

      {
        "_id": "endpoint:0976543210@a.phone.example.net",
        "type": "endpoint",
        "endpoint": "0976543210@a.phone.example.net",
        "password": "72hbh8fjwjhb",
        "ha1": "ae4fe3b1f2ca4b7a33a2f77fc5b15d11",
        "ha1b": "eabda99f11ae85b840597275b1cc962d",
        "account": "test"
      }

* Test registration.

Finishing configuring the hosts
===============================

*FIXME* These might be outdated. Refer to [the specifications](specs) for current data.

* Here are example records for the "client-sbc" host and the "carrier-side sbc" host.

  This host is a "client sbc" in cluster "a.phone.example.net".
  `ingress_acl` should contain the IP addresses of the carrier-side SBCs.

      {
        "_id":"host:vm2.phone.example.net",
        "type":"host",
        "host":"vm2.phone.example.net",
        "provisioning": ....,
        "password":"XXXX",
        "interfaces": ....,
        "account":"",
        "mailer":{},
        "applications":["applications/host","applications/freeswitch","applications/opensips","applications/traces"],
        "traces":{"interfaces":["eth0","eth1"]},

        "sip_domain_name":"a.phone.example.net",
        "opensips":{"model":"complete"},
        "sip_profiles":{
          "test":{
            "template":"sbc-nomedia",
            "ingress_sip_ip":"198.51.100.52",
            "ingress_sip_port":5200,
            "ingress_acl":["198.51.100.53/32"],
            "egress_acl":[198.51.100.52/32"],
            "handler":"client-sbc",
            "type":"france",
            "send_call_to":"bridge",
            "ingress_target":"a.phone.example.net",
            "egress_target":"trunk.phone.example.net",
            "egress_gwid":1
          }
        }

      }

  This host is a "carrier-side sbc" in cluster "trunk.phone.example.net".

      {
        "_id":"host:vm3.phone.example.net",
        "type":"host",
        "host":"vm3.phone.example.net",
        "provisioning": ...,
        "password":"XXXX",
        "interfaces": ...,
        "account":"",
        "mailer":{},
        "applications":["applications/host","applications/dns","applications/freeswitch","applications/opensips","applications/traces"],

        "sip_domain_name":"trunk.phone.example.net",
        "opensips":{"model":"outbound-proxy"},
        "sip_profiles":{
          "sotel":{
            "template":"sbc-nomedia",
            "ingress_sip_ip":"198.51.100.53",
            "ingress_sip_port":5200,
            "ingress_acl":["4.53.160.135/32","4.53.160.136/32"],
            "egress_acl":["198.51.100.52/32"],
            "handler":"sotel",
            "send_call_to":"bridge",
            "egress_target":"termination2.sotelips.net",
            "enum_root":"enum.phone.example.net",
            "egress_gwid":100
          }
        }

      }


* To apply the changes: run the `reload sofia` FreeSwitch command.

* You'll also need an endpoint to identify the client-sbc with the
  carrier-side proxy.

      {
        "_id":"endpoint:198.51.100.52",
        "type":"endpoint",
        "endpoint":"198.51.100.52",
        "sbc":2,
        "outbound_route":1
      }


* Configure OpenSIPS routing:

  The groupid should match the `outbound_route` for the endpoints.
  The ruleid is a random/incremental field used to manage the records.

  * Add rule records

    Routes from the client-side OpenSIPS to the client-side FreeSwitch.
    Mostly used to allow/deny destinations.

       {
        "_id":"rule:vm2.phone.example.net:1:",
        "type":"rule",
        "rule":"vm2.phone.example.net:1:",
        "host":"vm2.phone.example.net",

        "groupid":1,
        "prefix":"",
        "timerec":"",
        "priority":1,
        "gwlist":"1",
        "routeid":0,
        "attrs":""
      }

    Routes from the carrier-side OpenSIPS to the carrier-side FreeSwitch.
    Used for LCR routing.

      {
        "_id":"rule:vm3.phone.example.net:1:",
        "type":"rule",
        "rule":"vm3.phone.example.net:1:",
        "host":"vm3.phone.example.net",

        "groupid":1,
        "prefix":"",
        "timerec":"",
        "priority":1,
        "gwlist":"100",
        "routeid":0,
        "attrs":""
      }


  * Send `reload routes` command (in the portal)


End-user data
=============

Here are some provisioning records as examples.

Endpoint
--------

See above for a complete example.

Number
------

There are two types of "number" records. Both types must be provisioned for
a number to be fully provisioned.

Unqualified (global) number records are used by the carrier-side SBCs to know which cluster will handle an incoming number.
These "number" records populate Carrier ENUM for inbound routing and CDR generation.
The number is expressed in E.164 format without a "+" sign.

    {
      "_id":"number:33976543210",
      "number":"33976543210",
      "type":"number",

      "account":"stephane",
      "inbound_uri":"sip:33976543210@ingress-test.a.phone.example.net"
    }

Qualified (local) number records are used by a client-side SBC to know which endpoint will handle an incoming number.
They may also contain additional information such as the location of that specific number (for the purpose of emergency call routing).
Since the default value for OpenSIPS' `number_domain` is `local`, the name after the @ sign will generally be `local`.

    {
      "_id":"number:0976543210@local",
      "type":"number",
      "number":"0976543210@local",

      "endpoint":"0976543210@a.phone.example.net",
      "location":"maison"
    }


Location
--------

Used for emergency call routing.

    {
        "_id":"location:maison",
        "type":"location",
        "location":"maison",

        "account":"",
        "routing_data":"29789"
    }

Further Reading
===============

This document is meant to help you bootstrap your provisioning.

The complete provisioning documentation is available in [the specifications](specs).
