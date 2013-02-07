OpenSIPS server providing batch registration to an upstream server.
This is a registrant and inbound call forwarder for carrier-side SBCs.

A separate opensips process is spawned which will register ourselves with a third-party provider, while inbound INVITE messages are routed to one (or more) carrier-sbcs.

Install on: a server running OpenSIPS; will start a separate OpenSIPS instance for client registration.
