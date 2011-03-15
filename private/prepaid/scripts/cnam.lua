-- This script expects the following parameters:
--   number             -- number to resolve

-- This script expects the following variables:
--   cnam_uri           -- URI for the CNAM API

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
