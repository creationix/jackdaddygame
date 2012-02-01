local Tcp = require('tcp')
local Http = require('http')
local Stack = require('stack')
local Emitter = require('emitter')
local JsonStream = require('./jsonstream')
local Json = require('json')
local Path = require('path')

-- An HTTP server for browsers to watch
Http.create_server("0.0.0.0", 8080, Stack.stack(
  require('./static')(Path.join(__dirname, "ui"), "index.html")
))
print("Http server listening at http://localhost:8080/")

-- A server for joystick clients to connect to
Tcp:create_server("0.0.0.0", 5000, function (socket)
  local client = Emitter:new()
  function client.send(message)
    socket:write(Json.stringify(message))
  end
  local parser = JsonStream(function (message)
    client:emit('message', message)
  end)
  socket:on('data', function (chunk)
    parser:parse(chunk)
  end)
  new_player(client)
end)

local clients = {}

function new_player(client)
  local id = #clients + 1
  clients[id] = client
  client.send({welcome=id})
  client:on('message', debug)
end
