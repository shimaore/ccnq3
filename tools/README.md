CCNQ3 Tools
===========

Some tools to simplify management of a ccnq3 system.

Unless otherwise noted these tools are to be used on a management server, under the `ccnq3` user. (Either use `su -s /bin/bash ccnq3`, or preceed each command with `sudo -u ccnq3`.)

rules.coffee
------------

Import / update a ruleset. Only support prefix-based rulesets, not timerec-based rulesets.

Usage:

    npm install
    ./rules.coffee sip_domain_name groupid < ruleset.csv

Replace `sip_domain_name` with a proper value, and `groupid` with the proper value for the ruleset.
The file `ruleset.csv` must contain one rule per line, with the following format:

    prefix;gwlist;attrs

If no `attrs` are needed leave the field empty (the line terminates with a semicolon in that case).
