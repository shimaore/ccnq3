# Core changes
- Replace most of XMPP exchanges with CouchDB replication
  - Note: needs either CouchDB to support automatic replication startup, or do our own
  - RabbitMQ could also be a solution
  + also need to differentiate between:
  [DONE]    * OS-level issues (apt-get) -- should be seldom necessary
  [DONE]    * component configuration (generate FS config, configure routes) -- should always be feasible from API/GUI
  [DONE]    * day-to-day config changes (high-volume, realtime)
  + compare with what http://www.2600hz.org/ is doing
- [DONE] Replace API server with direct access to a CouchDB instance
  -> This means the manager will drop.
- [DONE] Replace AnyEvent with Node.js
- [DONE] Upgrade to recent OpenSIPS
  -> issues with drouting (dr_reload, semi-colon in routes)

# Portal
- View layout handled by CouchDB
- [DONE] Portal needs to do authorization (intermediate admin level -- FDN federation; Sotel "sales" profile)




# SIP features
* T.38 supported, tested (including turning off T.38)
* More options for codec choices
* Get rid of FS for regular call scenarios (OpenSIPS B2BUA: http://www.opensips.org/Resources/B2buaTutorial)
* REFER support (see OpenSIPS B2BUA)
* Support mix of TCP and UDP (esp. on both sides of the same proxy)
  + what does it mean performance-wise (for OpenSIPS? for FreeSwitch?)

# Call Handling features
* Prepaid
  - simplify the options: cost per duration unit is computed at start, etc.
  - use sharding for updating (one operation: incr) -- add record in CouchDB, update view, propagate

# Core
* [DONE] OpenSIPS 1.6.3+
  - [DONE] Use memcache? http://www.opensips.org/Resources/DocsTutMemcache
  - [DONE] Use 302 (instead of new INVITE) for CFA, CFB, etc ?

* [DONE] FreeSwitch latest
  [BIGCOUCH] + CouchDB 1.0.1+ with sharding and replication for multi-master
    + automate the allocation of shards
    + need sharding client

* Client access CouchDB remotely with SSL and username/password, subscribe to _changes streams
  - There could be more than one of such clients
  - They wouldn't have to be async
  - How well does CouchDB handle, say, 100's of _changes clients?
* Node.js for async event handling

* [DONE] System configuration (currently in DNS) must be explicited
  [DONE] - can change it from within (with proper reconfig & restarts)
    + investigate proper multi-machine management systems

* System monitoring

* [DONE] Get rid of the "request" system -- each module gets _changes and implements accordingly (this can be implemented with "filter" in nginx)
* [DONE] New routing system -- use JS code snippets where RequestManager db was used ? Or can these be abstracted and put in a UI ?
    -> why? the servers will monitor _changes, so it's up to them to implement these. Therefor need a generic way of defining these.

# Portal
  Portal = CouchDB + Node.js for authorization
  (use Node.js for register, login, and redirect)



# Rating

* Postpaid:
    FS mod_json_cdr -> CDR-CouchDB --(rate)--> RatedCDR-CouchDB



# Marketing
  "Shared-Nothing" is how voice-system.ro calls it. :)


# Other things to test, validate, implement
* IPv6
* bill based on route actually taken by call
* Virtual Domain Hosting

* new features:
  *  use limit to restrict number of concurrent calls on a DID
  [DONE] *  add code to enable "soft shutdown" (refuse new calls when a flag is set in the db) + add API
  *  RPID testing

* test environment
  * need better understanding of what freeswitch does for example with different error codes, refer, re-invites no SDP..
  * .. test various configurations.. all of this automated (e.g. to re-profile after an upgrade)
  * T.38: proper orig/term testing (be able to teach it), FS behavior with different configs, etc.
  * build distribution
    * Debian hosting
  * IPv6

* [DONE] multi-level account management (some/path/to/account:sub:account:info)
