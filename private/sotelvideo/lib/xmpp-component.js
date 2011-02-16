var jid = "nodechat.shimaore.net", password = "hellohello";

var xmpp = require('node-xmpp');

module.exports = function(){

  var cl = new xmpp.Component({
    jid: jid,
    password: password,
    host: jid,
    port: 5347
  });

  cl.on('online', function() {
    cl.send(
      new xmpp.Element('presence',{type: 'chat'}).
      c('show').t('chat').up().
      c('status').t('The nodechat server')
    );
  });

  cl.on('error', function(e) {
    sys.puts(e);
  });

  var callbacks = {};

  cl.on('stanza', function(stanza) {
    if (stanza.is('message') &&
    // Important: never reply to errors!
    stanza.attrs.type !== 'error') {
      var id = stanza.attrs.to.split('@',1)[0];
      if(callbacks[id])
        var text = stanza.getChild('body');
        callbacks[id].receiver(text.toString());
      }
    });

  return {
    add: function(id,receiver_callback,to) {
      callbacks[id] = {
        receiver: receiver_callback,
        sender: function (text) {
          var from = id+'@'+jid;
          cl.send(new xmpp.Element('message',{
            to: to,
            from: from,
            type: 'chat'}).
            c('body').
            t(text)
          );
        }
      };
    },

    remove: function(id) {
      delete callbacks[id]
    },

    send: function(id,text) {
      if(callbacks[id]) {
        callbacks[id].sender(text);
      }
    }
  };

}();

