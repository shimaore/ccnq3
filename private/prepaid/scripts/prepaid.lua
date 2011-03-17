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

-- Utility functions

function get_account()
  if not session:ready() then return nil end

  session:execute("curl", prepaid_uri .. '/' .. urlencoded_account )

  if not session:ready() then return nil end

  local curl_response_code = session:getVariable("curl_response_code")
  local curl_response_data = session:getVariable("curl_response_data")

  freeswitch.consoleLog("DEBUG", "response: "..curl_response_code.." "..curl_response_data)

  if curl_response_code == "200" then
    return json.decode(curl_response_data)  -- use pcall() if this ends up crashing
  end
  return nil
end

function get_current()
  if not session:ready() then return nil end

  session:execute("curl", prepaid_uri .. '/_design/prepaid/_view/current?reduce=true&group=true&key=%22' .. urlencoded_account .. '%22')

  if not session:ready() then return nil end

  local curl_response_code = session:getVariable("curl_response_code")
  local curl_response_data = session:getVariable("curl_response_data")

  freeswitch.consoleLog("DEBUG", "response: "..curl_response_code.." "..curl_response_data)

  if curl_response_code == "200" then
    local doc = json.decode(curl_response_data)  -- use pcall() if this ends up crashing
    return doc.rows[1]
  end
  return nil
end

function check_time()
  if not session:ready() then return nil end

  local row = get_current()
  if row == nil or row.value < 2 then
    session:hangup()
  end
end

-- /Utility functions

-- Gather account-level information

interval_duration = 0         -- seconds

if session:ready() then

  local account = get_account()
  if account == nil then
    freeswitch.consoleLog("NOTICE", "Account does not exist.\n")
    session:hangup()
    return
  end

  interval_duration = account.interval_duration -- seconds

end

-- Utility to record a new interval

recorded_duration = 0         -- seconds

function record_interval()
  session:execute("curl", prepaid_uri .. '/' .. urlencoded_account .. ' post intervals=-1' )
  local curl_response_code = session:getVariable("curl_response_code")

  freeswitch.consoleLog("DEBUG", "response: "..curl_response_code)

  if curl_response_code == "200" then
    recorded_duration = recorded_duration + interval_duration -- seconds
  else
    freeswitch.consoleLog("ERROR", "No access to timer, stopping the call.\n")
    session:hangup()
    return
  end
end

-- Make sure enough time is available before starting the call

check_time()

-- Set up the second leg of the call

if session:ready() then
  new_session = freeswitch.Session(prepaid_destination)
  freeswitch.bridge(session,new_session)
end

if session:ready() and new_session:ready() then
  session:waitForAnswer(new_session)
end

start_time        = os.time()  -- seconds

while session:ready() do

  -- Record the interval at the beginning of each period.
  record_interval()

  if session:ready() then
    actual_duration = os.time()-start_time -- seconds
    -- Offset the next check time to try to keep things in sync, since the
    -- curl code might take a little while to complete.
    wait_for = interval_duration + (recorded_duration - actual_duration) -- seconds

    freeswitch.consoleLog("NOTICE", string.format("Waiting for %d seconds\n",wait_for))
    sleep(wait_for*1000-10)
  end

  check_time()

end

