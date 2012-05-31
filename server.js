process.on('uncaughtException', function (err) {
  err = err ? err.stack || err : err
  shownStuff = err+''
  console.err(err)
})
require('coffee-script')
var http = require('http');
var shownStuff = 'This is jhbot. I only talk in IRC, not here.';
http.createServer(function (req, res) {
  res.writeHead(200, {'Content-Type': 'text/plain'});
  res.end(shownStuff);
}).listen(process.env['app_port'] || 8000);
require('./bot');
