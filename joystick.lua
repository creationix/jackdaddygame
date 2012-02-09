local Bit = require('bit')
local FS = require('fs')
local Emitter = require('core').Emitter
local Buffer = require('buffer').Buffer

local JOYSTICK = {}

-- http://www.mjmwired.net/kernel/Documentation/input/joystick-api.txt
function parse(buffer)
  local event = {
    time   = buffer:readUInt32LE(1),
    value  = buffer:readInt16LE(5),
    number = buffer[8],
  }
  local type = buffer[7]
  if Bit.band(type, 0x80) > 0 then event.init = true end
  if Bit.band(type, 0x01) > 0 then event.type = "button" end
  if Bit.band(type, 0x02) > 0 then event.type = "axis" end
  return event
end

-- Expose as a nice Lua API
local Joystick = Emitter:extend()
JOYSTICK.Joystick = Joystick

function Joystick:initialize(id)
  self:wrap("onOpen")
  self:wrap("onRead")
  self.id = id
  FS.open("/dev/input/js" .. id, "r", "0644", self.onOpen)
end

function Joystick:onOpen(fd)
  self.fd = fd
  self:emit("opened")
  self:startRead()
end

function Joystick:startRead()
  FS.read(self.fd, nil, 8, self.onRead)
end

function Joystick:onRead(chunk)
  local event = parse(Buffer:new(chunk))
  self:emit(event.type, event)
  if self.fd then self:startRead() end
end

function Joystick:close(callback)
  local fd = self.fd
  self.fd = nil
  FS.close(fd, callback)
end

return JOYSTICK

