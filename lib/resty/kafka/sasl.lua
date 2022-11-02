local _M = {}

local MECHANISM_PLAINTEXT = "PLAIN"
local MECHANISM_SCRAMSHA256 = "SCRAM-SHA-256" -- to do
local SEP = string.char(0)


local function _encode_plaintext(authz_id, user, pwd)
    local msg = ""
    if authz_id then
        msg = msg ..authz_id
    end

    return (authz_id or "") .. SEP .. user .. SEP .. pwd
end


_M.encode = function(mechanism, authz_id, user, pwd)
    if mechanism == MECHANISM_PLAINTEXT then
        return _encode_plaintext(authz_id, user, pwd)
    end

    return ""
end


return _M
