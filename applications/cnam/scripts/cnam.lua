-- (c) 2010 Stephane Alnet
-- Released under the AGPL3 license
-- This script expects the following parameters:
--   number             -- number to resolve

-- This script expects the following variables:
--   cnam_uri           -- URI for the CNAM API

-- On Debian,
--    aptitude install freeswitch-lua liblua5.1-cgi0
-- with lua.conf.xml
--   <configuration name="lua.conf" description="LUA Configuration">
--     <settings>
--       <param name="script-directory" value="/usr/share/lua/5.1/?.lua"/>
--     </settings>
--   </configuration>
-- and add
--    <load module="mod_lua"/> <!-- For CNAM query -->
--    <load module="mod_curl"/> <!-- For CNAM query -->
-- to autoload/modules.conf.xml

require("cgilua.urlcode")

cnam_uri = session:getVariable("cnam_uri")

if not session:ready() then return end

cid = argv[1]
number = string.match(cid,'^[+]?1?(%d%d%d%d%d%d%d%d%d%d)$')

if not number then return end

urlencoded_number = cgilua.urlcode.escape(number)

session:execute("curl", cnam_uri .. urlencoded_number )

if not session:ready() then return end

curl_response_code = session:getVariable("curl_response_code")
curl_response_data = session:getVariable("curl_response_data")

if curl_response_code == "200" then
  session:setVariable("effective_caller_id_name",curl_response_data)
end
