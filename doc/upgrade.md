Upgrade
=======

In most cases, upgrades to the `ccnq3` packages and their dependencies _will_ cause service disruption. In-progress calls will most likely be disconnected.

Always proceed with upgrades during off-peak periods, and only upgrade one server in a `sip_domain_name` (for example) at a time.

If FreeSwitch is to be upgraded, you should `pause` it beforehand:

    fs_cli -p CCNQ -x 'fsctl pause'

You should then wait until there are no active calls left; you can monitor this with the command:

    fs_cli -p CCNQ -x 'show calls'

To upgrade run the usual Debian commands:

    aptitude update
    aptitude dist-upgrade

If asked to replace or overwrite a configuration file in one of the `ccnq3`, `opensips`, or `freeswitch` packages, please do so. The `ccnq3` installers expect the files to be overwritten and will correct them as needed.

In most cases we recommend you also restart OpenSIPS and FreeSwitch even if they are not being upgraded, since upgrades to the `ccnq3` packages might contains configuration changes that require a restart. Before restarting FreeSwitch you can `pause` it if you need to first let calls die out on that instance (see above).

To restart OpenSIPS:

    /etc/init.d/opensips restart

To restart FreeSwitch:

    /etc/init.d/freeswitch restart
