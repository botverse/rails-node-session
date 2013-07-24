Sharing session across different platforms
================

This experiment is intended to demonstrate the ease to share sessions between different technologies under the same umbrella (single login).

There are 2 different approaches: Using encripted cookies with the session information and using redis servers to store the sessions.

The load is balanced. The load banlancer decides if the request looks like a webpage and sends to a Ruby on Rails server or if the request looks like a WebSocket and sends it to a Node.js server.

TODO: Send the WebSocket request to the most available server instead of to the next in the round robin. Store the location of each connected user in a key/value storage to be able to push back to the particular server instead of broadcasting to all of them.

Setup
-------

You can set up this environment using cookies or a session storage db (Redis).

You need node-rails-cookies package:
```bash
npm install node-rails-cookies
```

###Cookies###

railscookies/config/initializers/session_store.rb
```ruby
Railscookies::Application.config.session_store :cookie_store, key: '_response_session'
```

websockets/index.js line 16
```javascript
var session_store = 'cookies';
```

###Redis###

railscookies/config/initializers/session_store.rb
```ruby
Railscookies::Application.config.session_store :redis_store_json,
   key: "_response_session",
   strategy: :json_session,
   domain: :all,
   servers: {
       host: :localhost,
       port: 6379
   }
```

websockets/index.js line 16
```javascript
var session_store = 'redis';
```

Running
-------

```sh
cd railscookies
rails server

cd websockets
node index.js

haproxy -f haproxy.conf
```
