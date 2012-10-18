Upgrade
=======

Operational note: In most cases, upgrades to the `ccnq3` packages will cause service disruption. In-progress calls might be disconnected. Always proceed with upgrades during off-peak periods, and only upgrade one server in a `sip_domain_name` (for example) at a time.

To upgrade:

    aptitude update
    aptitude dist-upgrade

If asked to replace a configuration file in one of the `ccnq3`, `opensips`, or `freeswitch` packages, please do so. The `ccnq3` installers expect the files to be overwritten and will correct them as needed.

In most cases we recommend you also restart OpenSIPS and FreeSwitch since upgrades to the `ccnq3` packages might contains configuration changes that require a restart. Before restarting FreeSwitch you can `pause` it if you need to first let calls die out on that instance.

    /etc/init.d/opensips restart
    /etc/init.d/freeswitch restart
