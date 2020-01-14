local cookiejar = require "resty.jxwaf.cookie"
local cjson = require "cjson.safe"
local exit_code = require "resty.jxwaf.exit_code"
local table_insert = table.insert
local _M = {}
_M.version = "2.0"

local function _table_keys(tb)
	if type(tb) ~= "table" then
		return tb
	end
	local t = {}
	for key,_ in pairs(tb) do
		table_insert(t,key)
	end 
	return t
end

local function _get_headers()
	local t = ngx.req.get_headers()
	if #_table_keys(t) > 200 then
    local error_info = {}
    error_info['log_type'] = "error_log"
    error_info['error_type'] = "parse_request_body"
    error_info['error_info'] = "post args count error,is attack!"
    error_info['remote_addr'] = ngx.var.remote_addr
    ngx.ctx.error_log = error_info
		ngx.log(ngx.ERR,"post args count error,is attack!")
		exit_code.return_error()
	end
	ngx.ctx.request_get_headers = t
        return t
end

local function _process_json_args(json_args,t)
        local t = t or {}
        for k,v in pairs(json_args) do
                if type(v) == 'table' then
                        for _k,_v in pairs(v) do
                                if type(_v) == "table" then
                                    t = _process_json_args(_v,t)

                                else
                                        if type(t[k]) == "table" then
                                                table.insert(t[k],_v)

                                        elseif type(t[k]) == "string" then
                                                local tmp = {}
                                                table.insert(tmp,t[k])
                                                table.insert(tmp,_v)
                                                t[k] = tmp
                                        else

                                        t[k] = _v
                                        end
                                end

                        end
                else
                                         if type(t[k]) == "table" then
                                                table.insert(t[k],v)
                                        elseif type(t[k]) == "string" then
                                                local tmp = {}
                                                table.insert(tmp,t[k])
                                                table.insert(tmp,v)
                                                t[k] = tmp
                                        else

                                        t[k] = v
                                        end
                end
        end
        return t
end

local function _parse_request_uri()
	local t = ngx.req.get_uri_args()
	ngx.req.set_uri_args(t)
	ngx.ctx.parse_request_uri = t
	return t
end

local function _parse_request_body()

	local content_type = ngx.req.get_headers()["Content-type"]
	if (type(content_type) == "table") then
    local error_info = {}
    error_info['headers'] = ngx.ctx.request_get_headers or _get_headers()
    error_info['log_type'] = "error_log"
    error_info['error_type'] = "parse_request_body"
    error_info['error_info'] = "Request contained multiple content-type headers"
    error_info['remote_addr'] = ngx.var.remote_addr
    ngx.ctx.error_log = error_info
		ngx.log(ngx.ERR,"Request contained multiple content-type headers")
		exit_code.return_exit()
	end

	if ngx.ctx.upload_request then
      ngx.ctx.parse_request_body = {}
      return {}
  end

  if  ngx.req.get_body_file() then
    local error_info = {}
    error_info['headers'] = ngx.ctx.request_get_headers or _get_headers()
    error_info['log_type'] = "error_log"
    error_info['error_type'] = "parse_request_body"
    error_info['error_info'] = "request body size larger than client_body_buffer_size, refuse request "
    error_info['remote_addr'] = ngx.var.remote_addr
    ngx.ctx.error_log = error_info
		ngx.log(ngx.ERR,"request body size larger than client_body_buffer_size, refuse request ")
		exit_code.return_error()
	end
	
	if content_type and  ngx.re.find(content_type, [=[^application/json;]=],"oij") and ngx.req.get_headers()["Content-Length"] and tonumber(ngx.req.get_headers()["Content-Length"]) ~= 0 then
	
		local json_args_raw = ngx.req.get_body_data()
		if not json_args_raw then
			ngx.ctx.parse_request_body = {}
			return {}
		end 

		local json_args,err = cjson.decode(json_args_raw)
		if json_args == nil then
      local error_info = {}
      error_info['headers'] = ngx.ctx.request_get_headers or _get_headers()
      error_info['log_type'] = "error_log"
      error_info['error_type'] = "parse_request_body"
      error_info['error_info'] = "failed to decode json args :"..err
      error_info['remote_addr'] = ngx.var.remote_addr
      ngx.ctx.error_log = error_info
      ngx.log(ngx.ERR,"failed to decode json args :",err)
      exit_code.return_error()
		end
		local t = {}
		t = _process_json_args(json_args)
		ngx.ctx.parse_request_body = t 
		return t 
	end

	local post_args,err = ngx.req.get_post_args(210)
	if not post_args then
    local error_info = {}
    error_info['headers'] = ngx.ctx.request_get_headers or _get_headers()
    error_info['log_type'] = "error_log"
    error_info['error_type'] = "parse_request_body"
    error_info['error_info'] = "failed to get post args: "..err
    error_info['remote_addr'] = ngx.var.remote_addr
    ngx.ctx.error_log = error_info
		ngx.log(ngx.ERR,"failed to get post args: ", err)
		exit_code.return_error()
	end
	if #_table_keys(post_args) > 200 then
    local error_info = {}
    error_info['headers'] = ngx.ctx.request_get_headers or _get_headers()
    error_info['log_type'] = "error_log"
    error_info['error_type'] = "parse_request_body"
    error_info['error_info'] = "post args count error,is attack!"
    error_info['remote_addr'] = ngx.var.remote_addr
    ngx.ctx.error_log = error_info
		ngx.log(ngx.ERR,"post args count error,is attack!")
		exit_code.return_error()
	end
	local json_check = cjson.decode(ngx.req.get_body_data())
	if json_check then
		local _tmp = {}
		_tmp = _process_json_args(json_check)
		ngx.ctx.parse_request_body = _tmp
		return _tmp
	end
	ngx.ctx.parse_request_body = post_args
	return post_args
end

local function _args_names()
        local t = {}
        local request_args_post = ngx.ctx.parse_request_body or _parse_request_body()
        for k,v in pairs(request_args_post) do
                table.insert(t,k)
        end
	local request_args_get = ngx.ctx.parse_request_uri or _parse_request_uri()
        for k,v in pairs(request_args_get) do
                table.insert(t,k)
	end
	ngx.ctx.request_args_names = t
        return t	
end


local function _args_get()
	local  t = ngx.ctx.parse_request_uri or _parse_request_uri()
	ngx.ctx.request_args_get = t
	return t	
end


local function _args_get_names()
	local t ={}
	local request_args_get = ngx.ctx.parse_request_uri or _parse_request_uri()
        for k,v in pairs(request_args_get) do
                table.insert(t,k)
	end
	ngx.ctx.request_args_get_names = t
        return t

end


local  function _args_post()
	local t = {}

	local request_args_post = ngx.ctx.parse_request_body or _parse_request_body()
	ngx.ctx.request_args_post = request_args_post
        return request_args_post

end


local function _args_post_names()
	local t = {}
        local request_args_post = ngx.ctx.parse_request_body or _parse_request_body()
        for k,v in pairs(request_args_post) do
                table.insert(t,k)
	end
	ngx.ctx.request_args_post_names = t
        return t
end


local function take_cookies()
	local cookies,err = cookiejar:new()
	if not cookies then
		ngx.log(ngx.ERR,err)
		return nil
	end
	local request_cookies, cookie_err = cookies:get_all()
	if not request_cookies then 
	--	ngx.log(ngx.ERR,cookie_err)
		return nil
	end
	return request_cookies
end

local function _table_values(tb)
    if type(tb) ~= "table" then
        return tb
    end
    
    local t = {}
    
    for _, value in pairs(tb) do
        if type(value) == "table" then
            local tab = _table_values(value)
            for _, v in pairs(tab) do
                table.insert(t, v)
            end
        else
            table.insert(t, value)
        end
    end
    
    return t
end

local function _get_headers_names()
	local t = _table_keys(ngx.req.get_headers())
	if #_table_keys(t) > 200 then
    local error_info = {}
    error_info['log_type'] = "error_log"
    error_info['error_type'] = "parse_request_body"
    error_info['error_info'] = "post args count error,is attack!"
    error_info['remote_addr'] = ngx.var.remote_addr
    ngx.ctx.error_log = error_info
		ngx.log(ngx.ERR,"post args count error,is attack!")
		exit_code.return_error()
	end
	ngx.ctx.request_get_headers_names = t
        return t
end

local function _http_body()
	if  ngx.req.get_body_file() then
    local error_info = {}
    error_info['headers'] = ngx.ctx.request_get_headers or _get_headers()
    error_info['log_type'] = "error_log"
    error_info['error_type'] = "http_body"
    error_info['error_info'] = "request body size larger than client_body_buffer_size, refuse request "
    error_info['remote_addr'] = ngx.var.remote_addr
    ngx.ctx.error_log = error_info
		ngx.log(ngx.ERR,"request body size larger than client_body_buffer_size, refuse request ")
		exit_code.return_error()
	end
	local result = ""
	local data = ngx.req.get_body_data()
	if data then
		result = data
	end
	ngx.ctx.http_body = result
	return result
end

local function _remote_addr()
	local result
  result = ngx.var.remote_addr
	ngx.ctx.remote_addr = result
	return result
end

local function _http_full_info()
  local full_info = {}
  full_info['host'] = ngx.var.host
  full_info['headers'] = ngx.ctx.request_get_headers or _get_headers()
  full_info['scheme'] = ngx.var.scheme
  full_info['version'] = tostring(ngx.req.http_version())
  full_info['uri'] = ngx.var.uri
  full_info['method'] = ngx.req.get_method()
  full_info['query_string'] = ngx.var.query_string or ""
  full_info['body'] = ngx.ctx.http_body or  _http_body()
  full_info['remote_addr'] = ngx.var.remote_addr
  full_info['xxf_addr'] = ngx.ctx.remote_addr or _remote_addr()
  --ngx.ctx.http_full_info = full_info
  return full_info
end

local function _http_upload_info()
  local full_info = {}
  full_info['host'] = ngx.var.host
  full_info['headers'] = ngx.ctx.request_get_headers or _get_headers()
  full_info['scheme'] = ngx.var.scheme
  full_info['version'] = tostring(ngx.req.http_version())
  full_info['uri'] = ngx.var.uri
  full_info['method'] = ngx.req.get_method()
  full_info['query_string'] = ngx.var.query_string or ""
  full_info['remote_addr'] = ngx.var.remote_addr
  full_info['xxf_addr'] = ngx.ctx.remote_addr or _remote_addr()
  return full_info
end

_M.request = {
	ARGS_GET = function() return ngx.ctx.request_args_get or _args_get() end,
	ARGS_GET_NAMES = function() return ngx.ctx.request_args_get_names or _args_get_names() end,
	ARGS_POST = function() return ngx.ctx.request_args_post or _args_post() end,
  ARGS_POST_NAMES = function() return ngx.ctx.request_args_post_names or _args_post_names() end,
	ARGS_HEADERS = function() return ngx.ctx.request_get_headers or _get_headers() end,
  ARGS_HEADERS_NAMES = function() return ngx.ctx.request_get_headers_names or _get_headers_names() end,
	ARGS_COOKIES = function() return  take_cookies() or {} end,
  ARGS_COOKIES_NAMES = function() return _table_keys(take_cookies()) or {} end,
	HTTP_COOKIE = function() return ngx.var.http_cookie or "" end, 
	HTTP_SCHEME = function() return ngx.var.scheme end, -- http
	HTTP_HOST = function() return  ngx.var.host end, -- 52.xxx.xxx.xxx  www.xxx.xxx
	HTTP_PORT = function() return ngx.var.server_port end,
	HTTP_VERSION = function() return tostring(ngx.req.http_version()) end,-- 1.1 1.0 2.0
	HTTP_METHOD = function() return ngx.req.get_method() end, -- GET POST PUT 
	HTTP_URI = function() return ngx.var.uri end, -- /aaa/index.php
	HTTP_BODY = function() return ngx.ctx.http_body or  _http_body() end,
	HTTP_QUERY_STRING = function() return ngx.var.query_string or "" end, -- a=1113123&s=122222
	HTTP_USER_AGENT = function() return ngx.var.http_user_agent or "" end,
	HTTP_REFERER = function() return ngx.var.http_referer or ""  end,
	FILE_NAMES = function() return ngx.ctx.form_file_name or {} end,
	FILE_TYPES = function() return ngx.ctx.form_file_type or {} end ,
	REMOTE_ADDR = function() return ngx.ctx.remote_addr or _remote_addr() end, --ip xff
	REAL_REMOTE_ADDR = function() return ngx.var.remote_addr end,
	TIME_STAMP = function() return tonumber(ngx.time()) end,
  --HTTP_FULL_INFO = function() return ngx.ctx.http_full_info or _http_full_info() end,
  HTTP_FULL_INFO = function() return _http_full_info() end,
  HTTP_UPLOAD_INFO = function() return  _http_upload_info() end,
}


return _M
