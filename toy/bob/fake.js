
var http = require('http');
http.createServer(function (req, res) {
  var util = require('util');
  util.debug("req: "+util.inspect(req));
  res.writeHead(200, {'Content-Type': 'text/plain'});
  res.end('Hello World\n');
}).listen(5678, "127.0.0.1");
console.log('Server running at http://127.0.0.1:5678/');

