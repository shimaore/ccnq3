* License

    CCNQ3 -- carrierclass.net v3
    Copyright (C) 2011  Stéphane Alnet

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU Affero General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU Affero General Public License for more details.

    You should have received a copy of the GNU Affero General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

* Applications code layout

  agents/     -- Any background agents; most of them monitor CouchDB _changes and
              -- act upon insertion / modification ..
  couchapps/  -- CouchApps (in CoffeeScript)
              -- Normally called "_design/${application}" with ${application} the name
              -- of the application (to avoid conflicts).
  node/       -- Zappa REST APIs, or other generic Node.js code.

* Unified web access

The web access is unified as follows:

  - A unified website, such as https://example.net/ , is used for all applications.
    The main page should include /public/js/default.js , /public/css/default.css , and
    contain a "content" ID where the CCNQ3 applications will load.

  - The content in the subdirectories of "public" is available under the root:
      https://example.net/public/js
      https://example.net/public/css
      https://example.net/public/images

  - The "portal" application must be accessible under /ccnq3/portal/

  - The global couchdb databases (_users,provisioning,..) and all the u${UUID} databases are mapped at the root.

  - CouchDB's _session is mapped at the root.
    [FIXME This assumes we can use a distributed session scheme in CouchDB which doesn't exist yet.]
    [For now this doesn't cause any issue as long as the website uses a single CouchDB host for sessions.]
