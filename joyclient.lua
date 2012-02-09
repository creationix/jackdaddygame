local Joystick = require('./joystick').Joystick
local JSON = require('json')
local Emitter = require('core').Emitter
local Tcp = require('tcp').Tcp

if not process.argv[1] then 
  print("Please pass in joystick number as first argument")
  process.exit(1)
end
local host = process.argv[2] or "0.0.0.0"
local port = process.argv[3] or 5000

local function connect(host, port, callback)
  local client = Tcp:new()
  client:connect(host, port)
  client:on("error", callback)
  client:on("connect", function ()
    client:removeListener("error", callback)
    client:readStart()
    local emitter = Emitter:new()
    function emitter.send(message)
      client:write(JSON.stringify(message))
    end
    local parser = JSON.streamingParser(function (value)
      emitter:emit("message", value)
    end)
    client:on('data', function (chunk)
      parser:parse(chunk)
    end)
    client:on('error', function (err)
      emitter:emit("error", err)
    end)
    callback(null, emitter)
  end)
end

local js = Joystick:new(process.argv[1])
js:on('opened', function ()
  debug("Joystick opened")
  connect(host, port, function (err, server)
    if err then error(tostring(err)) end
    js:on('button', server.send)
    js:on('axis', server.send)
    server:on('message', debug)
  end)
end)

