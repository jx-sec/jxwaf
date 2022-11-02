-- Copyright (C) Dejiang Zhu(doujiang24)


local bit = require("bit")
local request = require("resty.kafka.request")


local setmetatable = setmetatable
local byte = string.byte
local sub = string.sub
local band = bit.band
local lshift = bit.lshift
local arshift = bit.arshift
local bor = bit.bor
local bxor = bit.bxor
local strbyte = string.byte
local floor = math.floor


local _M = {}
local mt = { __index = _M }


function _M.new(self, str, api_version)
    local resp = setmetatable({
        str = str,
        offset = 1,
        correlation_id = 0,
        api_version = api_version,
    }, mt)

    resp.correlation_id = resp:int32()

    return resp
end


local function _int8(str, offset)
    return byte(str, offset)
end


function _M.int8(self)
    local str = self.str
    local offset = self.offset
    self.offset = offset + 1
    return _int8(str, offset)
end


local function _int16(str, offset)
    local high = byte(str, offset)
    -- high padded
    return bor((high >= 128) and 0xffff0000 or 0,
            lshift(high, 8),
            byte(str, offset + 1))
end


function _M.int16(self)
    local str = self.str
    local offset = self.offset
    self.offset = offset + 2

    return _int16(str, offset)
end


local function _int32(str, offset)
    local offset = offset or 1
    local a, b, c, d = strbyte(str, offset, offset + 3)
    return bor(lshift(a, 24), lshift(b, 16), lshift(c, 8), d)
end
_M.to_int32 = _int32


function _M.int32(self)
    local str = self.str
    local offset = self.offset
    self.offset = offset + 4

    return _int32(str, offset)
end


local function _int64(str, offset)
    local a, b, c, d, e, f, g, h = strbyte(str, offset, offset + 7)

    --[[
    -- only 52 bit accuracy
    local hi = bor(lshift(a, 24), lshift(b, 16), lshift(c, 8), d)
    local lo = bor(lshift(f, 16), lshift(g, 8), h)
    return hi * 4294967296 + 16777216 * e + lo
    --]]

    return 4294967296LL * bor(lshift(a, 56), lshift(b, 48), lshift(c, 40), lshift(d, 32))
            + 16777216LL * e
            + bor(lshift(f, 16), lshift(g, 8), h)
end


-- XX return cdata: LL
function _M.int64(self)
    local str = self.str
    local offset = self.offset
    self.offset = offset + 8

    return _int64(str, offset)
end


-- Get a fixed-length integer from an offset position without
-- modifying the global offset of the response
-- The lengths of offset and length are in byte
function _M.peek_int(self, peek_offset, length)
    local str = self.str
    local offset = self.offset + peek_offset

    if length == 8 then
        return _int64(str, offset)
    elseif length == 4 then
        return _int32(str, offset)
    elseif length == 2 then
        return _int16(str. offset)
    else
        return _int8(str, offset)
    end
end


function _M.string(self)
    local len = self:int16()
    -- len = -1 means null
    if len < 0 then
        return nil
    end

    local offset = self.offset
    self.offset = offset + len

    return sub(self.str, offset, offset + len - 1)
end


function _M.bytes(self)
    local len = self:int32()
    if len < 0 then
        return nil
    end

    local offset = self.offset
    self.offset = offset + len

    return sub(self.str, offset, offset + len - 1)
end


function _M.correlation_id(self)
    return self.correlation_id
end


-- The following code is referenced in this section.
-- https://github.com/Neopallium/lua-pb/blob/master/pb/standard/unpack.lua#L64-L133
local function _uvar64(self, num)
    -- encode first 48bits
	local b1 = band(num, 0xFF)
	num = floor(num / 256)
	local b2 = band(num, 0xFF)
	num = floor(num / 256)
	local b3 = band(num, 0xFF)
	num = floor(num / 256)
    local b4 = band(num, 0xFF)
	num = floor(num / 256)
    local b5 = band(num, 0xFF)
	num = floor(num / 256)
	local b6 = band(num, 0xFF)
	num = floor(num / 256)

	local seg = self:int8()
	local base_factor = 2 -- still one bit in 'num'
	num = num + (band(seg, 0x7F) * base_factor)
	while seg >= 128 do
		base_factor = base_factor * 128
		seg = self:int8()
		num = num + (band(seg, 0x7F) * base_factor)
	end
	-- encode last 16bits
	local b7 = band(num, 0xFF)
	num = floor(num / 256)
	local b8 = band(num, 0xFF)

    return 4294967296LL * bor(lshift(b8, 56), lshift(b7, 48), lshift(b6, 40), lshift(b5, 32))
            + 16777216LL * b4
            + bor(lshift(b3, 16), lshift(b2, 8), b1)
end


-- Decode bytes as Zig-Zag encoded unsigned integer (32-bit or 64-bit)
local function _uvar(self)
    local seg = self:int8()
    local num = band(seg, 0x7F)

    -- In every 1byte (i.e., in every 8 bit), the first bit is used to
    -- identify whether there is data to follow, and the remaining 7 bits
    -- indicate the actual data.
    -- So the maximum value that can be expressed per byte is 128, and when
    -- the next byte is fetched, factor will be squared to calculate the
    -- correct value.
    local base_factor = 128

    -- The value of the first bit of the per byte (8 bit) is 1, marking the
    -- next byte as still a segment of this varint. Keep taking values until
    -- there are no remaining segments.
    while seg >= 128 do
        seg = self:int8()

        -- When out of range, change to 64-bit parsing mode.
        if base_factor > 128 ^ 6 and seg > 0x1F then
            return _uvar64(self, num)
        end

        num = num + (band(seg, 0x7F) * base_factor)
        base_factor = base_factor * 128
    end

    return num
end


-- Decode Zig-Zag encoded unsigned 32-bit integer as 32-bit integer
function _M.varint(self)
    local num = _uvar(self)

    -- decode 32-bit integer Zig-Zag
    return bxor(arshift(num, 1), -band(num, 1))
end


-- Decode Zig-Zag encoded unsigned 64-bit integer as 64-bit integer
function _M.varlong(self)
    local num = _uvar(self)

    -- decode 64-bit integer Zig-Zag
    local high_bit = false
	-- we need to work with a positive number
	if num < 0 then
		high_bit = true
		num = 0x8000000000000000 + num
	end
	if num % 2 == 1 then
		num = -(num + 1)
	end
	if high_bit then
		return (num / 2) + 0x4000000000000000
	end
	return num / 2
end


function _M.peek_bytes(self, offset, len)
    offset = offset or self.offset
    return sub(self.str, offset, offset + len - 1)
end


-- Decode the fixed-length bytes used in Record indicate the length by varint.
function _M.varint_bytes(self)
    local len = self:varint()

    if len < 0 then
        return nil
    end

    local offset = self.offset
    self.offset = offset + len

    return self:peek_bytes(offset, len)
end


-- Get the number of data in the response that has not yet been parsed
function _M.remain(self)
    return #self.str - self.offset
end


-- Forcibly close the response and set the offset to the end so that
-- it can no longer read more data.
function _M.close(self)
    self.offset = #self.str
end


return _M
