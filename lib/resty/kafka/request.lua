-- Copyright (C) Dejiang Zhu(doujiang24)
local ffi = require "ffi"


local bit = require "bit"


local setmetatable = setmetatable
local concat = table.concat
local rshift = bit.rshift
local band = bit.band
local char = string.char
local crc32 = ngx.crc32_long
local ngx_now = ngx.now
local tonumber = tonumber


local _M = {}
local mt = { __index = _M }

local MESSAGE_VERSION_0 = 0
local MESSAGE_VERSION_1 = 1


local API_VERSION_V0 = 0
local API_VERSION_V1 = 1
local API_VERSION_V2 = 2
local API_VERSION_V3 = 3


_M.API_VERSION_V0 = 0
_M.API_VERSION_V1 = 1
_M.API_VERSION_V2 = 2
_M.API_VERSION_V3 = 3

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


local function str_int8(int)
    return char(band(int, 0xff))
end


local function str_int16(int)
    return char(band(rshift(int, 8), 0xff),
                band(int, 0xff))
end


local function str_int32(int)
    -- ngx.say(debug.traceback())
    return char(band(rshift(int, 24), 0xff),
                band(rshift(int, 16), 0xff),
                band(rshift(int, 8), 0xff),
                band(int, 0xff))
end


-- XX int can be cdata: LL or lua number
local function str_int64(int)
    int = int * 1LL

    return char(tonumber(band(rshift(int, 56), 0xff)),
                tonumber(band(rshift(int, 48), 0xff)),
                tonumber(band(rshift(int, 40), 0xff)),
                tonumber(band(rshift(int, 32), 0xff)),
                tonumber(band(rshift(int, 24), 0xff)),
                tonumber(band(rshift(int, 16), 0xff)),
                tonumber(band(rshift(int, 8), 0xff)),
                tonumber(band(int, 0xff)))
end


function _M.new(self, apikey, correlation_id, client_id, api_version)
    api_version = api_version or API_VERSION_V0
    local len = 8
    local offset = 5
    local req = {
        0,   -- request size: int32
        str_int16(apikey),
        str_int16(api_version),
        str_int32(correlation_id),
    }

    if api_version > API_VERSION_V0  then
        local cid, clen
        if not client_id or #client_id == 0 then
            cid, clen = str_int16(-1), 2
        else
            cid, clen = client_id, #client_id
        end

        req[5] = str_int16(clen)
        req[6] = cid
        len = len + 2 + clen
        offset = offset + 2
    end

    return setmetatable({
        _req = req,
        api_key = apikey,
        api_version = api_version,
        offset = offset,
        len = len,
    }, mt)
end


function _M.int8(self, int)
    local req = self._req
    local offset = self.offset

    req[offset] = str_int8(int)

    self.offset = offset + 1
    self.len = self.len + 1
end


function _M.int16(self, int)
    local req = self._req
    local offset = self.offset

    req[offset] = str_int16(int)

    self.offset = offset + 1
    self.len = self.len + 2
end


function _M.int32(self, int)
    local req = self._req
    local offset = self.offset

    req[offset] = str_int32(int)

    self.offset = offset + 1
    self.len = self.len + 4
end


function _M.int64(self, int)
    local req = self._req
    local offset = self.offset

    req[offset] = str_int64(int)

    self.offset = offset + 1
    self.len = self.len + 8
end


function _M.string(self, str)
    if not str then
        -- -1 mean null
        return self:int16(-1)
    end

    local req = self._req
    local offset = self.offset
    local str_len = #str

    req[offset] = str_int16(str_len)
    req[offset + 1] = str

    self.offset = offset + 2
    self.len = self.len + 2 + str_len
end


function _M.bytes(self, str)
    local req = self._req
    local offset = self.offset
    local str_len = #str

    req[offset] = str_int32(str_len)
    req[offset + 1] = str

    self.offset = offset + 2
    self.len = self.len + 4 + str_len
end


local function message_package(key, msg, message_version)
    local key = key or ""
    local key_len = #key
    local len = #msg

    local req
    local head_len
    if message_version == MESSAGE_VERSION_1 then
        req = {
            -- MagicByte
            str_int8(1),
            -- XX hard code no Compression
            str_int8(0),
            str_int64(ffi.new("int64_t", (ngx_now() * 1000))), -- timestamp
            str_int32(key_len),
            key,
            str_int32(len),
            msg,
        }
        head_len = 22

    else
        req = {
            -- MagicByte
            str_int8(0),
            -- XX hard code no Compression
            str_int8(0),
            str_int32(key_len),
            key,
            str_int32(len),
            msg,
        }
        head_len = 14
    end

    local str = concat(req)
    return crc32(str), str, key_len + len + head_len
end


function _M.message_set(self, messages, index)
    local req = self._req
    local off = self.offset
    local msg_set_size = 0
    local index = index or #messages

    local message_version = MESSAGE_VERSION_0
    if self.api_key == _M.ProduceRequest and self.api_version == API_VERSION_V2 then
        message_version = MESSAGE_VERSION_1
    end

    for i = 1, index, 2 do
        local crc32, str, msg_len = message_package(messages[i], messages[i + 1], message_version)

        req[off + 1] = str_int64(0) -- offset
        req[off + 2] = str_int32(msg_len) -- include the crc32 length

        req[off + 3] = str_int32(crc32)
        req[off + 4] = str

        off = off + 4
        msg_set_size = msg_set_size + msg_len + 12
    end

    req[self.offset] = str_int32(msg_set_size) -- MessageSetSize

    self.offset = off + 1
    self.len = self.len + 4 + msg_set_size
end


function _M.package(self)
    local req = self._req
    req[1] = str_int32(self.len)

    return req
end


return _M
