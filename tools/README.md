CCNQ3 Tools
===========

Some tools to simplify management of a ccnq3 system.

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
