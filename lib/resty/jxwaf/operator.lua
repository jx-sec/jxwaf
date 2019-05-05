local string_find = string.find
local _M = {}
_M.version = "2.0"

local function _equals(input,pattern)
	local result, output
  local a = tonumber(input)
  local b = tonumber(pattern)
  if a and b then
    result = a == b
  end
	if (result) then
		output = input
	end
	return result, output
end

local function _nequals(input,pattern)
  local result, output
  local a = tonumber(input)
  local b = tonumber(pattern)
  if a and b then
    result = a ~= b
  end
  if (result) then
    output = input
  end
  return result, output
end


local function _greater(input,pattern)
	local result, output
  local a = tonumber(input)
  local b = tonumber(pattern)
  if a and b then
    result = a > b
  end
	if (result) then
		output = input
	end
	return result, output
end


local function _less(input,pattern)
	local result, output
  local a = tonumber(input)
  local b = tonumber(pattern)
  if a and b then
    result = a < b
  end
	if (result) then
		output = input
	end
	return result, output
end

local function _regex( input, pattern)
	local opts = 'oij'
	local captures, err, result,output
	captures, err = ngx.re.match(input, pattern, opts)
	if err then
		ngx.log(ngx.ERR,"regex error",captures,err)
		ngx.exit(500)
	end
	if captures then
		result = true		
    output = input
		return result, output 
	end
	return result, output
end

local function _str_eq(input,pattern)
  local result,output
  if tostring(input) == tostring(pattern)  then
    result = true
		output = input
  end
  return result,output
end

local function _str_neq(input,pattern)
  local result,output
  if tostring(input) ~= tostring(pattern)  then
    result = true
    output = input
  end
  return result,output
end

local function _str_contain(input,pattern)
  local result,output
  local from,to,err = string_find(input,pattern,1,true)
  if from then
    result = true
    output = input
  end
  return result,output
end

local function _str_ncontain(input,pattern)
  local result,output
  local from,to,err = string_find(input,pattern,1,true)
  if from then
    result = false
  else
    result = true
    output = input
  end
  return result,output
end

local function _str_prefix(input,pattern)
  local result,output
  local from,to = string_find(input,pattern,1,true)
  if from == 1 then
    result = true
    output = input
  end
  return result,output
end

local function _str_suffix(input,pattern)
  local result,output
  local from,to = string_find(input,pattern,-#pattern,true)
  if from then
    result = true
    output = input
  end
  return result,output
end

local function _table_contain(input,pattern)
  local result,output
  if tostring(input) == tostring(pattern)  then
    result = true
    output = input
  end
  return result,output
end


_M.request = {

eq = function(var,rule_pattern)
	return _equals(var,rule_pattern)
end
,
lt = function(var,rule_pattern)
	return _less(var,rule_pattern)
end 
,
gt = function(var,rule_pattern)
	return _greater(var,rule_pattern)
end
,
rx = function(var,rule_pattern)
	return _regex(var,rule_pattern)
end
,
 
neq = function(var,rule_pattern)
        return _nequals(var,rule_pattern)
end,

str_eq = function(var,rule_pattern)
        return _str_eq(var,rule_pattern)
end,

str_neq =  function(var,rule_pattern)
        return _str_neq(var,rule_pattern)
end,

str_contain =  function(var,rule_pattern)
        return _str_contain(var,rule_pattern)
end,

str_ncontain =  function(var,rule_pattern)
        return _str_ncontain(var,rule_pattern)
end,

str_prefix =  function(var,rule_pattern)
        return _str_prefix(var,rule_pattern)
end,

str_suffix =  function(var,rule_pattern)
        return _str_suffix(var,rule_pattern)
end,

table_contain = function(var,rule_pattern)
        return _table_contain(var,rule_pattern)
end,

}

return _M
