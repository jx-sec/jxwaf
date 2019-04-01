local libinject = require "resty.jxwaf.libinjection"
local ac = require "resty.jxwaf.load_ac"
local _M = {}
_M.version = "1.0"

local function _equals(a,b)
	local equals, value


	equals = tonumber(a) == tonumber(b)

	if (equals) then
		value = a
	end
	

	return equals, value
end

local function _greater(a,b)
	local greater, value
	

	greater = tonumber(a) > tonumber(b)

	if (greater) then
		value = a
	end


	return greater, value
end


local function _less(a,b)
	local less, value


	less = tonumber(a) < tonumber(b)

	if (less) then
		value = a
	end


	return less, value
end

local function _greater_equals(a,b)
	local greater_equals, value

	
	greater_equals = tonumber(a) >= tonumber(b)

	if (greater_equals) then
		value = a
	end


	return greater_equals, value
end


local function _less_equals(a, b)
	local less_equals, value


	less_equals = tonumber(a) <= tonumber(b)

	if (less_equals) then
		value = a
	end


	return less_equals, value
end


local function _regex( subject, pattern)
	local opts = 'oij'
	local captures, err, match
	captures, err = ngx.re.match(subject, pattern, opts)
		
	if err then
		ngx.log(ngx.ERR,"regex error",captures,err)
		ngx.exit(500)
	end

	if captures then

		match = true			
		--ngx.ctx.rx_capture = captures[0]
		return match, subject ,captures[0]
	end

	return match, subject
end

local function _detect_sqli(input)
		local result,fingerprint = libinject.sqli(input)
		if (result) then
			--ngx.log(ngx.ERR,fingerprint)
                        return true, input
                else
                        return false, nil
                end
				
end

local function _detect_xss(input)

	if (libinject.xss(input)) then
		return true, input
	else
		return false, nil
	end
	
end


		
local function _ac_match(var,rule_pattern)
	local pattern = {}
	local value
	pattern[1] = rule_pattern
	local _ac = ac.create_ac(pattern)
	local match = ac.match(_ac,var)
	if match then
		match = true 
		value = var
	end
	return match, value

end

_M.request = {

ac = function(var,rule_pattern)
	return _ac_match(var,rule_pattern)
end,


eq = function(var,rule_pattern)
	return _equals(var,rule_pattern)
end
,
gt = function(var,rule_pattern)
	return _greater(var,rule_pattern)
end
,
le = function(var,rule_pattern)
	return _less(var,rule_pattern)
end 
,
ge = function(var,rule_pattern)
	return _greater_equals(var,rule_pattern)
end 
,
le = function(var,rule_pattern)
	return _less_equals(var,rule_pattern)
end 
,

rx = function(var,rule_pattern)
	return _regex(var,rule_pattern)
end
,
detectSQLi = function(var)
	return _detect_sqli(var)
end
,
detectXSS = function(var)
	return _detect_xss(var)
end 
,
--limitreq = function(var)
--	return true
--end

}

return _M
