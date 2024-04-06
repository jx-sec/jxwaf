local _M = {}
local lrucache = require "resty.lrucache"

local c, err = lrucache.new(10000)
if not c then
   ngx.log(ngx.ERR, "failed to create the cache: " .. (err or "unknown"))
end

function _M.get_cache()
    return c
end

return _M