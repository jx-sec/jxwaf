local _M = {}
_M.version = "20220831"
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

local function unicode_to_utf8(convertStr)
    local resultStr=""
    local i=1
    while true do
        local num1=string.byte(convertStr,i)
        local unicode
        if num1~=nil and string.sub(convertStr,i,i+1)=="\\u" then
            local tmp_convertStr = {}
            tmp_convertStr[1] = "0x"
            tmp_convertStr[2] = string.sub(convertStr,i+2,i+5)
            unicode=tonumber(table.concat(tmp_convertStr))
            if unicode then
              i=i+6
            else
              unicode=num1
              i=i+1
            end
        elseif num1~=nil then
            unicode=num1
            i=i+1
        else
            break
        end
        
        if  unicode <= 0x007f then
            local tmp_resultStr = {}
            tmp_resultStr[1] = resultStr
            tmp_resultStr[2] = string.char(bit.band(unicode,0x7f))
            resultStr= table.concat(tmp_resultStr)
        elseif  unicode >= 0x0080 and unicode <= 0x07ff then
            local tmp_resultStr = {}
            tmp_resultStr[1] = resultStr
            tmp_resultStr[2] = string.char(bit.bor(0xc0,bit.band(bit.rshift(unicode,6),0x1f)))
            resultStr= table.concat(tmp_resultStr)
            local tmp_resultStr2 = {}
            tmp_resultStr2[1] = resultStr
            tmp_resultStr2[2] = string.char(bit.bor(0x80,bit.band(unicode,0x3f)))
            resultStr= table.concat(tmp_resultStr2)
        elseif unicode >= 0x0800 and unicode <= 0xffff then
            local tmp_resultStr = {}
            tmp_resultStr[1] = resultStr
            tmp_resultStr[2] = string.char(bit.bor(0xe0,bit.band(bit.rshift(unicode,12),0x0f)))
            resultStr= table.concat(tmp_resultStr)
            local tmp_resultStr2 = {}
            tmp_resultStr2[1] = resultStr
            tmp_resultStr2[2] = string.char(bit.bor(0x80,bit.band(bit.rshift(unicode,6),0x3f)))
            resultStr= table.concat(tmp_resultStr2)
            local tmp_resultStr3 = {}
            tmp_resultStr3[1] = resultStr
            tmp_resultStr3[2] = string.char(bit.bor(0x80,bit.band(unicode,0x3f))) 
            resultStr= table.concat(tmp_resultStr3)
        end
    end
    return resultStr
end

local function _uni_decode(value)
  if not value then
    return value
  end
  if type(value)~="string" then
    return value
  end
  if string.find(value,"\\u", 1,true) then
    return unicode_to_utf8(value)
  else
    return value
  end
end


local function hex_to_utf8(convertStr)
    local resultStr=""
    local i=1
    while true do
        local num1=string.byte(convertStr,i)
        local unicode
        if num1~=nil and string.sub(convertStr,i,i+1)=="\\x" then
            unicode = tonumber(string.sub(convertStr,i+2,i+3), 16)
            if unicode then
              i=i+4
            else
              unicode=num1
              i=i+1
            end
        elseif num1~=nil then
            unicode=num1
            i=i+1
        else
            break
        end
        
        if  unicode <= 0x007f then
            local tmp_resultStr = {}
            tmp_resultStr[1] = resultStr
            tmp_resultStr[2] = string.char(bit.band(unicode,0x7f))
            resultStr= table.concat(tmp_resultStr)
        elseif  unicode >= 0x0080 and unicode <= 0x07ff then
            local tmp_resultStr = {}
            tmp_resultStr[1] = resultStr
            tmp_resultStr[2] = string.char(bit.bor(0xc0,bit.band(bit.rshift(unicode,6),0x1f)))
            resultStr= table.concat(tmp_resultStr)
            local tmp_resultStr2 = {}
            tmp_resultStr2[1] = resultStr
            tmp_resultStr2[2] = string.char(bit.bor(0x80,bit.band(unicode,0x3f)))
            resultStr= table.concat(tmp_resultStr2)
        elseif unicode >= 0x0800 and unicode <= 0xffff then
            local tmp_resultStr = {}
            tmp_resultStr[1] = resultStr
            tmp_resultStr[2] = string.char(bit.bor(0xe0,bit.band(bit.rshift(unicode,12),0x0f)))
            resultStr= table.concat(tmp_resultStr)
            local tmp_resultStr2 = {}
            tmp_resultStr2[1] = resultStr
            tmp_resultStr2[2] = string.char(bit.bor(0x80,bit.band(bit.rshift(unicode,6),0x3f)))
            resultStr= table.concat(tmp_resultStr2)
            local tmp_resultStr3 = {}
            tmp_resultStr3[1] = resultStr
            tmp_resultStr3[2] = string.char(bit.bor(0x80,bit.band(unicode,0x3f))) 
            resultStr= table.concat(tmp_resultStr3)
        end
    end
    return resultStr
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
