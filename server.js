process.on('uncaughtException', function (err) { console.err(err ? err.stack || err : err) })
require('coffee-script')
var http = require('http');
require('./bot');
http.createServer(function (req, res) {
  res.writeHead(200, {'Content-Type': 'text/plain'});
  res.end('This is jhbot. I only talk in IRC, not here.');
}).listen(80);
