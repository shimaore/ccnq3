random = -> Math.random()

shuffle = (a) ->
  i = a.length
  return a if i is 0
  while --i
    j = Math.floor(random() * (i+1))
    [ a[i], a[j] ] = [ a[j], a[i] ]
  return a

module.exports = shuffle

# Test
test = ->
  assert = require 'assert'
  a = [1,10,100]
  sum_0 = sum_1 = sum_2 = 0
  for t in [0..10]
    b = shuffle a
    sum_0 += b[0]
    sum_1 += b[1]
    sum_2 += b[2]
  assert sum_0 > 1, "sum_0 is only #{sum_0}"
  assert sum_1 > 1, "sum_1 is only #{sum_0}"
  assert sum_2 > 1, "sum_2 is only #{sum_0}"

  assert shuffle([]).length is 0, "empty array shuffled wrong"

# do test
