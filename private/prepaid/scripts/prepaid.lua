-- See http://wiki.freeswitch.org/wiki/Lua
-- See http://wiki.freeswitch.org/wiki/Mod_curl#Lua_Usage

-- Prerequisites:
-- sudo aptitude install lua5.1 liblua5.1-json liblua5.1-cgi0

-- A simple single-bucket duration-based prepaid application.

-- This script expects the following parameters:
--   prepaid_account       -- account to be decremented
--   prepaid_destination   -- where to bridge the call

-- This script expects the following variables:
--   prepaid_uri           -- URI for the prepaid API

prepaid_account     = argv[1]
prepaid_destination = argv[2]

-- The JSON structure returned by the API contains:
--   interval  -- interval duration in seconds
--   value     -- number of intervals remaining ("credit") for the account
--

require("json")
require("cgilua.urlcode")
require("os")

prepaid_uri          = session:getVariable("prepaid_uri")

urlencoded_account   = cgilua.urlcode.escape(prepaid_account)

function get_account()
  session:execute("curl", prepaid_uri .. "/" .. urlencoded_account )
  curl_response_code = session:getVariable("curl_response_code")
  curl_response_data = session:getVariable("curl_response_data")

  freeswitch.consoleLog("DEBUG", "response: "..curl_response_code.." "..curl_response_data)

  if curl_response_code == "200" then
    return json.decode(curl_response_data)  -- use pcall() if this ends up crashing
  end
  return nil
end

function get_current()
  session:execute("curl", prepaid_uri .. "/_design/prepaid/_view/current?reduce=true&group=true&key=" .. urlencoded_account )
  curl_response_code = session:getVariable("curl_response_code")
  curl_response_data = session:getVariable("curl_response_data")

  freeswitch.consoleLog("DEBUG", "response: "..curl_response_code.." "..curl_response_data)

  if curl_response_code == "200" then
    doc = json.decode(curl_response_data)  -- use pcall() if this ends up crashing
    return doc.rows[0]
  end
  return nil
end

if session:ready() then

  account = get_account()
  if account == nil then
    freeswitch.consoleLog("NOTICE", "Account does not exist.\n")
    session:hangup()
  end

  row = get_current()
  if row == nil or row.value < 2 then
    freeswitch.consoleLog("NOTICE", "No time on account.\n")
    session:hangup()
  else
    session:originate(sofia_dest)
    session:waitForAnswer()
    session:setHangupHook("session_hangup_hook")
  end
end

start_time        = os.time()  -- seconds
recorded_duration = 0          -- seconds

interval_duration = account.interval

function record_interval()
  session:execute("curl", prepaid_uri .. "/" .. urlencoded_account .. " post intervals=1" )
  curl_response_code = session:getVariable("curl_response_code")

  freeswitch.consoleLog("DEBUG", "response: "..curl_response_code)

  if curl_response_code == "200" then
    recorded_duration = recorded_duration + interval_duration -- seconds
  else
    freeswitch.consoleLog("ERROR", "No access to timer, stopping the call.\n")
    session:hangup()
  end
end

function session_hangup_hook(status)
  -- note: status is userdata and cannot be concatenated
  record_interval()
end

while session:ready() do

  actual_duration = os.time()-start_time -- seconds
  -- Offset the next check time to try to keep things in sync, since the
  -- curl code might take a little while to complete.
  wait_for = interval_duration + (recorded_duration - actual_duration) -- seconds

  freeswitch.consoleLog("NOTICE", string.format("Waiting for %d seconds\n",wait_for))
  sleep(wait_for*1000-10)

  if session:ready() then
    row = get_current()
    if row == nil or row.value < 2 then
      -- Hangup Hook will do record_interval()
      session:hangup()
    else
      record_interval()
    end
  end
end
