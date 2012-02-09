local NET = require('net')
local TABLE = require('table')
local HTTP = require('http')
local STACK = require('stack')
local Emitter = require('core').Emitter
local JSON = require('json')
local PATH = require('path')
local URL = require('url')
local QUERY_STRING = require('querystring')

local history = {}
local pending = {}

local function flushPending()
  local callbacks = pending
  pending = {}
  for i, callback in ipairs(callbacks) do
    callback()
  end
end

-- An HTTP server for browsers to watch
HTTP.createServer("0.0.0.0", 8080, STACK.stack(
  -- Long Poll connection
  function (req, res, next)
    if not (req.method == "GET") then return next() end
    req.uri = req.uri or URL.parse(req.url)
    if not (req.uri.pathname == "/listen") then return next() end
    local since = 0;
    if req.headers.cookie then
      since = tonumber(QUERY_STRING.parse(req.headers.cookie).since)
    end
    if (not since) and #history > 0 then
      since = history[#history].time
    end
    local function filter()
      local new = {}
      for i, v in ipairs(history) do
        if v.time > since then
          TABLE.insert(new, v.message)
        end
      end
      return new
    end
    local function respond()
      local json = JSON.stringify(filter()) .."\n"
      res:writeHead(200, {
        ["Set-Cookie"] = "since="..history[#history].time,
        ["Content-Type"] = "application/json",
        ["Content-Length"] = #json
      })
      res:finish(json)
    end
    TABLE.insert(pending, respond)
  end,

  -- Serve static resources
  require('./static')(PATH.join(__dirname, "ui"), "index.html")
))
print("Http server listening at http://localhost:8080/")

-- A server for joystick clients to connect to
NET.createServer(function (socket)
  local client = Emitter:new()
  function client.send(message)
    socket:write(JSON.stringify(message))
  end
  local parser = JSON.streamingParser(function (message)
    client:emit('message', message)
  end, {allow_multiple_values=true})
  socket:on('data', function (chunk)
    parser:parse(chunk)
  end)
  newPlayer(client)
end):listen(5000, "0.0.0.0")

local clients = {}

function newPlayer(client)
  local id = #clients + 1
  clients[id] = client
  client.send({welcome=id})
  client:on('message', function (message)
    local time = message.time
    message.time = nil
    message.id = id
    TABLE.insert(history, {time=time,message=message})
    p(message)
    flushPending()
  end)
end
