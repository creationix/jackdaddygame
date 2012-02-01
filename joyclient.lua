local Joystick = require('./joystick')

if not process.argv[1] then 
  print("Please pass in joystick number as first argument")
  process.exit(1)
end
local js = Joystick:new(process.argv[1])
js:on('button', p);
js:on('axis', p);
js:on('error', function (err)
  debug("Error", err)
end)


