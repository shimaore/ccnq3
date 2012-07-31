# Convert a Javascript Date object into a string suitable to feeding
# for wireshark.

wireshark_months = [
  'Jan','Feb','Mar','Apr','May','Jun',
  'Jul','Aug','Sep','Oct','Nov','Dec'
]

wireshark_date = (date) ->
  pad = (n) -> if n < 10 then "0#{n}" else ''+n
  [
    wireshark_months[date.getMonth()]
    ' '
    date.getDate()
    ', '
    date.getFullYear()
    ' '
    pad date.getHours()
    ':'
    pad date.getMinutes()
    ':'
    pad date.getSeconds()
  ].join ''

# Self-test
do ->
  assert = require 'assert'
  assert.equal wireshark_date( new Date '2012-05-07 15:06:56' ), 'May 7, 2012 15:06:56'
  assert.equal wireshark_date( new Date '2040-12-27 07:16:08' ), 'Dec 27, 2040 07:16:08'

module.exports = wireshark_date
