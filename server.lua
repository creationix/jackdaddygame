local Tcp = require('tcp')
local JsonStream = require('./jsonstream')

-- A server for joystick clients to connect to
Tcp:create_server("0.0.0.0", 5000, function (client)
  debug("client", client)
  local parser = JsonStream(function (message)
    debug("message from client", message)
  end)
  client:on('data', function (chunk)
    parser:parse(chunk)
  end)
end)
