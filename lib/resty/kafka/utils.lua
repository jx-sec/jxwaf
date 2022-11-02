local _M = { _VERSION = "0.20" }


function _M.correlation_id(index)
    return (index + 1) % 1073741824 -- 2^30
end


return _M
