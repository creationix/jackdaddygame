local Tcp = require('tcp')
local Table = require('table')
local Http = require('http')
local Stack = require('stack')
local Emitter = require('emitter')
local JsonStream = require('./jsonstream')
local Json = require('json')
local Path = require('path')
local Url = require('url')
local QueryString = require('querystring')

local history = {}
local pending = {}

local function flush_pending()
  local callbacks = pending
  pending = {}
  for i, callback in ipairs(callbacks) do
    callback()
  end
end

-- An HTTP server for browsers to watch
Http.create_server("0.0.0.0", 8080, Stack.stack(
  -- Long Poll connection
  function (req, res, next)
    if not (req.method == "GET") then return next() end
    req.uri = req.uri or Url.parse(req.url)
    if not (req.uri.pathname == "/listen") then return next() end
    local since = 0;
    if req.headers.cookie then
      since = tonumber(QueryString.parse(req.headers.cookie).since)
    end
    if (not since) and #history > 0 then
      since = history[#history].time
    end
    local function filter()
      local new = {}
      for i, v in ipairs(history) do
        if v.time > since then
          Table.insert(new, v.message)
        end
      end
      return new
    end
    local function respond()
      local json = Json.stringify(filter()) .."\n"
      res:write_head(200, {
        ["Set-Cookie"] = "since="..history[#history].time,
        ["Content-Type"] = "application/json",
        ["Content-Length"] = #json
      })
      res:finish(json)
    end
    Table.insert(pending, respond)
  end,

  -- Serve static resources
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
  client:on('message', function (message)
    local time = message.time
    message.time = nil
    message.id = id
    Table.insert(history, {time=time,message=message})
    p(message)
    flush_pending()
  end)
end
