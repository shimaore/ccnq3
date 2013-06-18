Test OpenSIPS tooling
=====================

    opensips = require './opensips'

    test = ->
      assert = require 'assert'
      assert.equal opensips.command('dr_reload'), ':dr_reload:\n'
      assert.equal opensips.command('foo',1,'hello','dud"e'), ':foo:\n1\nhello\n"dud"e"\n'
      assert.equal opensips.command('bar',hello:true,world:null), ':bar:\nhello::true\nworld::\n'

      p1 = opensips.parse new Buffer '''
        200 OK
        Contact:: foo
        bar

      '''

      assert.equal typeof p1, 'object', 'is an object'
      assert.ok p1.length?, 'is an array'
      assert.equal p1.length, 1
      assert.equal p1[0], 'bar'
      assert.ok p1.Contact?
      assert.ok p1.Contact.length?
      assert.equal p1.Contact.length, 1
      assert.equal p1.Contact[0].value, 'foo'

      p2 = opensips.parse new Buffer '''
        200 OK
        Contact:: foo
        Contact:: bar

      '''

      assert.equal typeof p2, 'object'
      assert.ok p2.length?
      assert.equal p2.length, 0
      assert.ok p2.Contact?
      assert.equal p2.Contact.length, 2
      assert.equal p2.Contact[0].value, 'foo'
      assert.equal p2.Contact[1].value, 'bar'

    test()
