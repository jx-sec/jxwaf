local _M = {}
_M.version = "1.0"

local function _base64_decode(value)
	local val = ngx.decode_base64(tostring(value))
	if (val) then
		return val
	else 
		return value
	end
end

local function _base64_encode(value)
	local val = ngx.encode_base64(value)
	return val
end

local function _cmd_line(value)
	local val = tostring(value)
	val = ngx.re.gsub(val,[=[[\\'"^]]=], '',"oij")
	val = ngx.re.gsub(val,[=[\s+/]=],'/',"oij")
	val = ngx.re.gsub(val, [=[\s+[(]]=],'(', "oij")
	val = ngx.re.gsub(val, [=[[,;]]=],' ', "oij")
	val = ngx.re.gsub(val, [=[\s+]=],' ', "oij")
	return string.lower(val)
end

local function _compress_whitespace(value)
	return ngx.re.gsub(value, [=[\s+]=], ' ', "oij")
end 

local function _hex_decode(value)
	if type(value) ~= "string" then return value end
            
            local str

            if (pcall(function()
                str = value:gsub('..', function (cc)
                    return string.char(tonumber(cc, 16))
                end)
            end)) then
                return str
            else
                return value
            end
end

local function _hex_encode(value)
	            if type(value) ~= "string" then return value end
            
            return (value:gsub('.', function (c)
                return string.format('%02x', string.byte(c))
            end))
 end

local function _html_decode(value)
            if type(value) ~= "string" then return value end
            
            local str = ngx.re.gsub(value, [=[&lt;]=], '<', "oij")
            str = ngx.re.gsub(str, [=[&gt;]=], '>', "oij")
            str = ngx.re.gsub(str, [=[&quot;]=], '"', "oij")
            str = ngx.re.gsub(str, [=[&apos;]=], "'", "oij")
            str = ngx.re.gsub(str, [=[&#(\d+);]=], function(n) return string.char(n[1]) end, "oij")
            str = ngx.re.gsub(str, [=[&#x(\d+);]=], function(n) return string.char(tonumber(n[1],16)) end, "oij")
            str = ngx.re.gsub(str, [=[&amp;]=], '&', "oij")
            return str
 end

local function _length(value)
          return tostring(#tostring(value))
end
local function _lowercase(value)
   
            
            return string.lower(tostring(value)
        end
local function _md5(value)
            if not value then return nil end
            
            return ngx.md5_bin(value)
        end

local function _normalise_path(value)
	            while (ngx.re.match(value, [=[[^/][^/]*/\.\./|/\./|/{2,}]=], "oij")) do
                value = ngx.re.gsub(value, [=[[^/][^/]*/\.\./|/\./|/{2,}]=], '/', "oij")
            end
            return value
	end


local function _remove_comments(value)
	           if type(value) ~= "string" then return value end
            
            return ngx.re.gsub(value, [=[\/\*(\*(?!\/)|[^\*])*\*\/]=], '', "oij")
        end

local function _remove_comments_char(value)
	            if type(value) ~= "string" then return value end
            
            return ngx.re.gsub(value, [=[\/\*|\*\/|--|#]=], '', "oij")
        end

local function _remove_whitespace(value)
            if type(value) ~= "string" then return value end

            return ngx.re.gsub(value, [=[\s+]=], '', "oij")
        end


local function _replace_comments(value)
	            if type(value) ~= "string" then return value end
            
            return ngx.re.gsub(value, [=[\/\*(\*(?!\/)|[^\*])*\*\/]=], ' ', "oij")
        end

local function _sha1(value)
	          if not value then return nil end
            
            return ngx.sha1_bin(value)
        end

local function _sql_hex_decode(value)
	            if type(value) ~= "string" then return value end
            
            if (string.find(value, '0x', 1, true)) then
                value = string.sub(value, 3)
                local str
                if (pcall(function()
                    str = value:gsub('..', function (cc)
                        return string.char(tonumber(cc, 16))
                    end)
                end)) then
                    return str
                else
                    return value
                end
            else
                return value
            end
        end

local function _trim(value)
            if type(value) ~= "string" then return value end
            
            return ngx.re.gsub(value, [=[^\s*|\s+$]=], '')
        end

local function _trim_left(value)
            if type(value) ~= "string" then return value end
            
            return ngx.re.sub(value, [=[^\s+]=], '')
        end

local function _trim_right(value)
            if type(value) ~= "string" then return value end
            
            return ngx.re.sub(value, [=[\s+$]=], '')
        end


local function _uri_decode(value)
	local value = tostring(value)
	return ngx.unescape_uri(value)

end 

local function _uri_encode(value)
	local value = tostring(value)
	return ngx.escape_uri(value)
end


_M.request = {
	 none = function(value)
		return value
	end,	
	 base64Decode = function(value)
		return _base64_decode(value)
	end,
	 base64Encode = function(value)
		return _base64_encode(value)
	end,
	 cmdLine = function(value)
		return _cmd_line(value)
	end,
	 compressWhitespace = function(value)
		return _compress_whitespace(value)
	end,
	 hexDecode = function(value)
		return _hex_decode(value)
	end,
	 hexEncode = function(value)
		return _hex_encode(value)
	end,
	 htmlDecode = function(value)
		return _html_decode(value)
	end,
	 length = function(value)
		return _length(value)
	end,
	 lowercase = function(value)
		return _lowercase(value)
	end,
	 md5 = function(value)
		return _md5(value)
	end,
	 normalisePath = function(value)
		return _normalise_path(value)
	end,
	 removeComments = function(value)
		return _remove_comments(value)
	end,
	removeCommentsChar = function(value)
		return _remove_comments_char(value)
	end,
	 removeWhitespace = function(value)
		return _remove_whitespace(value)
	end,
	 replace_comments = function(value)
		return _replace_comments(value)
	end,
	 sha1 = function(value)
		return _sha1(value)
	end,
	 sqlHexDecode = function(value)
		return _sql_hex_decode(value)
	end,
	 trim = function(value)
		return _trim(value)
	end,
	 trimLeft = function(value)
		return _trim_left(value)
	end,
	 trimRight = function(value)
		return _trim_right(value)
	end,
	 uriDecode = function(value)
		return _uri_decode(value)
	end,
	         uriEncode = function(value)
                return _uri_encode(value)
        end,
	
}

return _M 
