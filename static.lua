local Url = require('url')
local FS = require('fs')
local Path = require('path')
local MIME = require('mime')

return function (root, index)
  return function (req, res, next)
    if not req.method == "GET" then return next() end
    req.uri = req.uri or Url.parse(req.url)
    local path = Path.join(root, req.uri.pathname)
    FS.stat(path, function (err, stat)
      if err then
        if err.code == "ENOENT" then
          return next()
        end
        return next(err)
      end
      if index and stat.is_directory then
        res:write_head(301, {
          Location=Path.join(req.uri.pathname, index)
        })
        res:finish()
        return
      end
      local stream = FS.create_read_stream(path);
      stream:on('error', next)
      stream:once('data', function ()
        res:write_head(200, {
          ["Content-Type"] = MIME.get_type(path),
          ["Content-Length"] = stat.size
        })
      end)
      stream:pipe(res)
    end)
  end
end
