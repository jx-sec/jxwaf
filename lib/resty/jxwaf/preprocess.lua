local _M = {}
_M.version = "jxwaf_base_v4"
local ngx_decode_base64 = ngx.decode_base64
local ngx_re_gsub = ngx.re.gsub
local ngx_md5 = ngx.md5
local string_byte = string.byte
local string_upper = string.upper
local string_sub = string.sub
local table_concat = table.concat
local table_insert = table.insert
local tostring = tostring
local string_char = string.char
local string_lower = string.lower
local bit = require("bit")
local cjson = require "cjson.safe"
local ngx_re_find = ngx.re.find
local ngx_unescape_uri = ngx.unescape_uri

local function _base64_decode(value)
  if not value then
    return value
  end
	local val = ngx_decode_base64(tostring(value))
	if (val) then
		return val
	else 
		return value
	end
end



local function _length(value)
  if not value then
    return value
  end
  return tostring(#tostring(value))
end


local function _lowercase(value)
  if not value then
    return value
  end
  return string.lower(tostring(value))
end


local function _uri_decode(value)
  if not value then
    return value
  end
	return ngx_unescape_uri(tostring(value))
end 


local function unicode_decode(unicode_str)
    if not unicode_str:find("\\u00%x%x") then
        return unicode_str  
    end
    local result = unicode_str:gsub("\\u00(%x%x)", function(hex)
        local byte = tonumber(hex, 16)
        return string.char(byte)
    end)
    return result
end

local function _uni_decode(value)
  if not value then
    return value
  end
  if type(value)~="string" then
    return value
  end
  if string.find(value,"\\u", 1,true) then
    return unicode_decode(value)
  else
    return value
  end
end

local function hex_to_utf8(convertStr)
    local resultStrTable = {}  
    local i = 1
    while i <= #convertStr do
        local num = string_byte(convertStr, i)
        local unicode
        if num and convertStr:sub(i, i+1) == "\\x" then
            unicode = tonumber(convertStr:sub(i+2, i+3), 16)
            if unicode then
                i = i + 4
            else
                unicode = num
                i = i + 1
            end
        else
            unicode = num
            i = i + 1
        end
        
        if unicode <= 0x7f then
            table_insert(resultStrTable, string_char(unicode))
        elseif unicode <= 0x7ff then
            table_insert(resultStrTable, string_char(bit_bor(0xc0, bit_band(bit_rshift(unicode, 6), 0x1f))))
            table_insert(resultStrTable, string_char(bit_bor(0x80, bit_band(unicode, 0x3f))))
        elseif unicode <= 0xffff then
            table_insert(resultStrTable, string_char(bit_bor(0xe0, bit_band(bit_rshift(unicode, 12), 0x0f))))
            table_insert(resultStrTable, string_char(bit_bor(0x80, bit_band(bit_rshift(unicode, 6), 0x3f))))
            table_insert(resultStrTable, string_char(bit_bor(0x80, bit_band(unicode, 0x3f))))
        end
    end
    return table.concat(resultStrTable)
end

local function _hex_decode(value)
  if type(value)~="string" then
    return value
  end
  if string.find(value,"\\x", 1,true) then
    return hex_to_utf8(value)
  else
    return value
  end
end


function _M.process_args(k,v)
  if k == "none" then
    return v
  elseif k == "base64Decode" then
    return _base64_decode(v)
  elseif k == "length" then
    return _length(v)
  elseif k == "lowerCase" then
    return _lowercase(v)
  elseif k == "uriDecode" then
    return _uri_decode(v)
  elseif k == "hexDecode" then
    return _hex_decode(v)
  elseif k == "uniDecode" then
    return _uni_decode(v)
  elseif k == "type" then
    if tonumber(v) then
      return "number"
    else
      return type(v)
    end
  else
    return nil 
  end
end


return _M 
