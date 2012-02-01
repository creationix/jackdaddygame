local Yajl = require('yajl')
local Table = require('table')
return function (callback, options)
  local current
  local key
  local stack = {}
  local options = options or {}
  options.allow_multiple_values = true
  local null = options.use_null and Yajl.null
  local function emit(value)
    if not current then
      callback(value)
    else
      current[key or #current + 1] = value
    end
  end
  local parser = Yajl.new_parser({
    on_null = function ()
      emit(null)
    end,
    on_boolean = function (value)
      emit(value)
    end,
    on_number = function (value)
      emit(value)
    end,
    on_string = function (value)
      emit(value)
    end,
    on_start_map = function ()
      local new = {}
      Table.insert(stack, current)
      key = nil
      current = new
    end,
    on_map_key = function (value)
      key = value
    end,
    on_end_map = function ()
      key = nil
      local map = current
      current = Table.remove(stack)
      emit(map)
    end,
    on_start_array = function ()
      local new = {}
      key = nil
      current = new
    end,
    on_end_array = function ()
      local array = current
      current = Table.remove(stack)
      emit(array)
    end
  })
  if options then
    options.use_null = nil
    if options then
      for k,v in pairs(options) do
        parser:config(k, v)
      end
    end
  end
  return parser
end

