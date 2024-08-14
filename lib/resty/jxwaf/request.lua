local ck = require "resty.jxwaf.cookie"
local table_insert = table.insert
local cjson = require "cjson.safe"
local table_concat = table.concat
local _M = {}
_M.version = "jxwaf_base_v4"



local function _get_cookies()
	local cookie,err = ck:new()
	if not cookie then
		return nil
	end
	local request_cookie, cookie_err = cookie:get_all()
	if not request_cookie then 
		return nil
	end
	return request_cookie
end


local function _get_raw_body()
	if  ngx.req.get_body_file() then
		ngx.log(ngx.ERR,"request body size larger than client_body_buffer_size")
	end
	local result 
	local data = ngx.req.get_body_data()
	if data then
      result = data
	end
	return result
end

local function _get_raw_header()
  local raw_header_data
  local headers,err = ngx.req.get_headers(200)
  if err == "truncated" then
    ngx.log(ngx.ERR,"header count error,is attack!")
  end
  local header_table = {} 
  for k,v in pairs(headers) do
    if type(v) == 'string' then
        table_insert(header_table,k..": "..v)
    elseif  type(v) == 'table' then
        for _, _v in ipairs(v) do
          table.insert(header_table, k .. ": " .. _v)
        end
    end
  end
  raw_header_data = table_concat(header_table,"\r\n")
  ngx.ctx.raw_header_data = raw_header_data
  return raw_header_data
end

local function _get_raw_header_no_referer()
  local raw_header_no_referer_data
  local headers,err = ngx.req.get_headers(200)
  if err == "truncated" then
    ngx.log(ngx.ERR,"header count error,is attack!")
  end
  headers['referer'] = nil
  local header_table = {} 
  for k,v in pairs(headers) do
    if type(v) == 'string' then
      table_insert(header_table,k..": "..v)
    elseif  type(v) == 'table' then
      table_insert(header_table,k..": "..v[1])
    end
  end
  raw_header_no_referer_data = table_concat(header_table,"\r\n")
  ngx.ctx.raw_header_no_referer_data = raw_header_no_referer_data
  return raw_header_no_referer_data
end

local function get_http_args(key)
  local return_value 
  if key == "path" then
    return_value = ngx.var.uri
  elseif key == "query_string" then
    return_value = ngx.var.query_string
  elseif key == "method" then
    return_value = ngx.req.get_method()
  elseif key == "src_ip" then
    return_value = ngx.ctx.src_ip or ngx.var.remote_addr
  elseif key == "raw_body" then
    return_value = _get_raw_body()
  elseif key == "version" then
    return_value = tostring(ngx.req.http_version())
  elseif key == "scheme" then
    return_value = ngx.var.scheme
  elseif key == "raw_header" then
    return_value = ngx.ctx.raw_header_data or _get_raw_header()
  elseif key == "raw_header_no_referer" then
    return_value = ngx.ctx.raw_header_no_referer_data or _get_raw_header_no_referer()
  elseif key == "referer" then
    return_value = ngx.var.http_referer
  elseif key == "user_agent" then
    return_value = ngx.var.http_user_agent
  elseif key == "host" then
    return_value = ngx.var.http_host or ngx.var.host
  elseif key == "cookie" then
    return_value = ngx.var.http_cookie
  end
  return return_value
end

local function get_header_args(key)
  local t,err = ngx.req.get_headers(200)
  if err == "truncated" then
		ngx.log(ngx.ERR,"header count error,is attack!")
  end
  local value = ngx.req.get_headers()[key]
  if type(value) == "string" then
    return value
  elseif type(value) == "table" then
    return value[1]
  else 
    return nil
  end
end

local function get_uri_args(key)
  local t,err = ngx.req.get_uri_args(200)
  if err == "truncated" then
		ngx.log(ngx.ERR,"uri_args count error,is attack!")
  end
  local value = ngx.req.get_uri_args()[key]
  if type(value) == "string" then
    return value
  elseif type(value) == "table" then
    return value[1]
  else 
    return nil
  end
end

local function get_post_args(key)
  local t,err = ngx.req.get_post_args(200)
  if err == "truncated" then
		ngx.log(ngx.ERR,"post_args count error,is attack!")
  end
  local value = ngx.req.get_post_args()[key]
  if type(value) == "string" then
    return value
  elseif type(value) == "table" then
    return value[1]
  else 
    return nil
  end
end


local function get_json_post_args(key)
  local raw_body = _get_raw_body()
  local json_body = cjson.decode(raw_body)
  if json_body then
    if json_body[key] then
      if type(json_body[key]) == 'string' then
        return json_body[key]
      else
        return cjson.encode(json_body[key])
      end
    end
  end
  return nil
end

local function get_cookie_args(key)
  local cookies = _get_cookies()
  if cookies then
    if type(cookies[key]) == "string" then
      return cookies[key]
    elseif type(cookies[key]) == "table" then
      return cookies[key][1]
    else
      return nil
    end
  else
    return nil
  end
end

local function get_web_rule_protection_result(key)
  return ngx.ctx.web_rule_protection_result[key]
end

local function get_web_engine_protection_result(key)
  return ngx.ctx.web_engine_protection_result[key]
end

function _M.get_args(k,v,extra)
  if k == "http_args" then
    return get_http_args(v)
  elseif k == "header_args" then
    return get_header_args(v)
  elseif k == "cookie_args" then
    return get_cookie_args(v)
  elseif k == "post_args" then
    return get_post_args(v)
  elseif k == "json_post_args" then
    return get_json_post_args(v)
  elseif k == "uri_args" then
    return get_uri_args(v)
  elseif k == "string" then
    return tostring(v)
  elseif k == "web_rule_protection_result" then
    return get_web_rule_protection_result(v)
  elseif k == "web_engine_protection_result" then
    return get_web_engine_protection_result(v)
  else
    return nil 
  end
end

return _M
