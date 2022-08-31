local _M = {}
_M.version = "20220831"
local ngx_unescape_uri = ngx.unescape_uri
local ngx_decode_base64 = ngx.decode_base64
local ngx_re_gsub = ngx.re.gsub
local ngx_md5 = ngx.md5

local function _base64_decode(value)
	local val = ngx_decode_base64(tostring(value))
	if (val) then
		return val
	else 
		return value
	end
end

local function _compress_whitespace(value)
	return ngx_re_gsub(value, [=[\s+]=], ' ', "oij")
end 


local function _length(value)
  return tostring(#tostring(value))
end

local function _lowercase(value)
  return string.lower(tostring(value))
end


local function _replace_comments(value)
  if type(value) ~= "string" then return value end
  return ngx_re_gsub(value, [=[\/\*(\*(?!\/)|[^\*])*\*\/]=], ' ', "oij")
end

local function _uri_decode(value)
	return ngx_unescape_uri(tostring(value))
end 


_M.request = {
	 none = function(value)
		return value
	end,	
	 base64Decode = function(value)
		return _base64_decode(value)
	end,
	 compressWhitespace = function(value)
		return _compress_whitespace(value)
	end,
	 length = function(value)
		return _length(value)
	end,
	 lowercase = function(value)
		return _lowercase(value)
	end,
	 md5 = function(value)
		return ngx_md5(value)
	end,
	 replace_comments = function(value)
		return _replace_comments(value)
	end,
	 uriDecode = function(value)
		return _uri_decode(value)
	end
	
}

return _M 
