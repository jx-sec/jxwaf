local ffi = require("ffi")
local cast = ffi.cast
local bxor = bit.bxor
local bnot = bit.bnot
local band = bit.band
local rshift = bit.rshift


local _M = {}


-- API versions
_M.API_VERSION_V0  = 0
_M.API_VERSION_V1  = 1
_M.API_VERSION_V2  = 2
_M.API_VERSION_V3  = 3
_M.API_VERSION_V4  = 4
_M.API_VERSION_V5  = 5
_M.API_VERSION_V6  = 6
_M.API_VERSION_V7  = 7
_M.API_VERSION_V8  = 8
_M.API_VERSION_V9  = 9
_M.API_VERSION_V10 = 10
_M.API_VERSION_V11 = 11
_M.API_VERSION_V12 = 12
_M.API_VERSION_V13 = 13


-- API keys
_M.ProduceRequest = 0
_M.FetchRequest = 1
_M.OffsetRequest = 2
_M.MetadataRequest = 3
_M.OffsetCommitRequest = 8
_M.OffsetFetchRequest = 9
_M.ConsumerMetadataRequest = 10
_M.SaslHandshakeRequest = 17
_M.ApiVersionsRequest = 18
_M.SaslAuthenticateRequest = 36


local crc32_t = ffi.new('const uint32_t[256]', (function()
    local function init_lookup_table(crc)
            local iteration = crc

            for _=1,8 do
                    crc = band(crc, 1) == 1
                            and bxor(rshift(crc, 1), 0x82f63b78)
                             or rshift(crc, 1)
            end

            if iteration < 256 then
                    return crc, init_lookup_table(iteration + 1)
            end
    end

    return init_lookup_table(0)
end)())


-- Generate and self-increment correlation IDs
-- The correlated is a table containing the correlation_id attribute
function _M.correlation_id(correlated)
    local id = (correlated.correlation_id + 1) % 1073741824 -- 2^30
    correlated.correlation_id = id

    return id
end


-- The crc32c algorithm is implemented from the following url.
-- https://gist.github.com/bjne/ab9efaab585563418cb7462bb1254b6e
function _M.crc32c(buf, len, crc)
    len = len or #buf
    buf, crc = cast('const uint8_t*', buf), crc or 0

    for i=0, len-1 do
            crc = bnot(crc)
            crc = bnot(bxor(rshift(crc, 8), crc32_t[bxor(crc % 256, buf[i])]))
    end

    return crc
end


return _M
