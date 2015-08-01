// Generated by LiveScript 1.3.1
(function(){
  var map, hapi, server, io;
  map = require('prelude-ls').map;
  hapi = require("hapi");
  server = new hapi.Server();
  server.connection({
    port: 4000
  });
  io = require('socket.io')(server.listener);
  io.on('connection', function(socket){
    return socket.on("tweet", function(tweet){
      console.log("tweet from browser", tweet, 'broadcasting all others');
      socket.broadcast.emit('tweet', tweet);
      return socket.emit('tweet', tweet);
    });
  });
  server.route({
    method: 'GET',
    path: '/',
    handler: {
      file: './public/index.html'
    }
  });
  server.route({
    method: 'GET',
    path: '/{filename*}',
    handler: {
      file: function(request){
        return './public/' + request.params.filename;
      }
    }
  });
  server.route({
    method: 'GET',
    path: '/static/{filename*}',
    handler: {
      file: function(request){
        return './public/' + request.params.filename;
      }
    }
  });
  server.start(function(){
    console.log("Server running at:", server.info.uri);
  });
}).call(this);
