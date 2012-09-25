Local host management

This is ran relatively late in the installation process; on most hosts, only the agent will be installed, and the local provisioning database will be created.

The `couchapps/` and `node/` code only affect the manager host; especially the `node/` code is used to create a bootstrap user account for the local (manager) server, an operation which is done for any other host via the couchapps/usercode/host.coffee application.
