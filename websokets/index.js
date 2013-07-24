var parser = require('node-rails-cookies');
var BSON = require('bson');

var params = {
    base: '923760ca7c6c692207d76fb092eac8af1414d54ba89e98ceb38727761b45552db7fd0ec75fddfff13463c786ae24bd7ce02ae5f6e7fb19785f8a7996cf7c2781'
    , salt: 'encrypted cookie'
    , signed_salt: 'signed encrypted cookie'
    , iterations: 1000
    , keylen: 64
  }
  , cipher = 'aes-256-cbc'
  ;

decryptor = parser(params);

var session_store = 'redis';

var io = require('socket.io').listen(8080);
var redis = require('redis');
var cookie = require("cookie"); // cookie parser
var redis_validate = redis.createClient(6379, "127.0.0.1");

var ObjectID = require('mongodb').ObjectID;

var MongoClient = require('mongodb').MongoClient
  , format = require('util').format
  ;

var users = []
  , userscollection
  ;

MongoClient.connect('mongodb://127.0.0.1:27017/railscookies_development', function(err, db) {
  if(err) throw err;

  userscollection = db.collection('users');
});

io.configure(function (){
  io.set('authorization', function (data, callback) {

    if (data.headers.cookie) {

      data.cookie = cookie.parse(data.headers.cookie);
      if (session_store == 'redis') {
        return redisStore(data, callback);
      }

      else {
        return cookieStore(data, callback);
      }

    } else {
      return callback('Unauthorized user', false);
    }
  });
});

function redisStore(data, callback) {
  data.sessionID = data.cookie['_response_session'];
  // retrieve session from redis using the unique key stored in cookies
  redis_validate.get(data.sessionID, function (err, session) {

    if (err || !session) {
      return callback('Unauthorized user', false);
    } else {
      // store session data in nodejs server for later use
      data.session = JSON.parse(session);
      if ( data.session['warden.user.user.key'] ) {
        var id = JSON.parse(data.session['warden.user.user.key'][0][0]);
        userscollection.findOne({_id: new ObjectID(id['$oid'])}, function(err, result) {
          console.log(result);
          data.user = result;
        });
      }
      return callback(null, true);
    }
  });
}

function cookieStore(data, callback) {
  message = decryptor(data.cookie['_response_session'], cipher);

  data.session = JSON.parse(message);

  if ( data.session['warden.user.user.key'] ) {
    userscollection.findOne({_id: new ObjectID(data.session['warden.user.user.key'][0][0]['$oid'])}, function(err, result) {
      console.log(result);
      data.user = result;
    });
  }
  return callback(null, true);
}

io.sockets.on('connection', function(socket){
  // save a reference to the user for latter.
  if ( socket.handshake.user ) {
    users[socket.handshake.user.email] = socket;
    socket.on('message', function (data) {
      console.log(data);
      data.from = socket.handshake.user.email;
      if( users[data.to] ) users[data.to].emit('message', data);
    });
  }
});
