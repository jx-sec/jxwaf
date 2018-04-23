local cookiejar = require "resty.jxwaf.cookie"
local upload = require "resty.upload"
local cjson = require "cjson.safe"
local zlib = require "zlib"
local _M = {}
_M.version = "1.0"

local function _table_keys(tb)
	if type(tb) ~= "table" then
		return tb
	end
	local t = {}
	for key,_ in pairs(tb) do
		table.insert(t,key)
	end 
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
		ngx.log(ngx.ERR,"Request contained multiple content-type headers")
		ngx.exit(403)
	end
	if ngx.req.get_method() == "POST" and not content_type then
--		ngx.log(ngx.ERR,"Request not contained  content-type headers :",ngx.req.raw_header())

	end

	if  ngx.req.get_body_file() then
		ngx.log(ngx.ERR,"request body size larger than client_body_buffer_size, refuse request ")
		ngx.exit(503)
	end

	if content_type and  ngx.re.find(content_type, [=[^application/json;]=],"oij") and tonumber(ngx.req.get_headers()["Content-Length"]) ~= 0 then
	
--		local body_data = ngx.req.get_post_args() 
		local json_args_raw = ngx.req.get_body_data()
		if not json_args_raw then
			ngx.log(ngx.ERR,"get_body_data ERR!")
			ngx.exit(500)
		end 
--		for k,_ in pairs(body_data)do
--			json_args_raw = k
--		end
		local json_args,err = cjson.decode(json_args_raw)
		if json_args == nil then
			ngx.log(ngx.ERR,"failed to decode json args :",err)
			ngx.exit(503)
		end
		local t = {}
		t = _process_json_args(json_args)

		return t 
	end
	local post_args,err = ngx.req.get_post_args()
	if not post_args then
		ngx.log(ngx.ERR,"failed to get post args: ", err)
		ngx.exit(500)
	end
	local json_check = cjson.decode(ngx.req.get_body_data())
	if json_check then
		ngx.log(ngx.ERR,"get post args ERR, json data")
	else
		ngx.req.set_body_data(ngx.encode_args(post_args))
	end
	ngx.ctx.parse_request_body = post_args
	return post_args
end

local function _args()
        local request_args_post = ngx.ctx.parse_request_body or _parse_request_body()
        local t = request_args_post
	
	local request_args_get = ngx.ctx.parse_request_uri or _parse_request_uri()

        for k,v in pairs(request_args_get) do
		
                if(t[k]) then
                        local _t = {}
                        if(type(t[k])== 'table') then
                                for  _ ,_v in ipairs(t[k]) do
                                table.insert(_t,_v)
                                end
                        else
                                table.insert(_t,t[k])

                        end
                        if(type(v) == 'table') then
                                for _,_d in ipairs(v) do
                                table.insert(_t,_d)
                                end
                        else
                                table.insert(_t,v)
                        end
                        t[k] =_t
                else
                        t[k] = v
                end
	end
	ngx.ctx.request_args = t
        return t
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
function _M.table_keys(t)


	return _table_keys(t)
end

function _M.table_values(t)


        return _table_values(t)
end

local function _resp_body()
	local data = ""
	local args = ngx.arg[1]
	if args ~= nil then
		local content_type = ngx.req.get_headers()["Accept-Encoding"]
		if content_type and ngx.re.find(content_type, [=[gzip]=],"oij") then
			local inflate = zlib.inflate()
			local is_success,tmp_data = pcall(inflate,args)
			if is_success then
				data = tmp_data	
			else
				data = args
			end

		else
			data = args
		end
	end
	ngx.ctx.response_get_data = data
	return data

end

--[[
local function _resp_cookies()
	local set_cookies = ngx.resp.get_headers()['Set-Cookie']
	local return_cookies = cookiejar.get_response_cookie_table(set_cookies)
	return return_cookies

end
--]]

local function _get_headers()
	local t = ngx.req.get_headers()
--	local count = #_table_keys(t)
--	if count > 80 then
--		ngx.log(ngx.ERR,"ERR get_headers")
--		ngx.exit(503)
--	end
	for k,v in pairs(ngx.req.get_headers()) do
		ngx.req.set_header(k, v)
	end
	ngx.ctx.request_get_headers = t
        return t
end


local function _get_headers_names()
	local t = _table_keys(ngx.req.get_headers())
--	local count = #t
--	if count > 80 then
--		ngx.log(ngx.ERR,"ERR get_headers_names")
--		ngx.exit(503)
--	end
	for k,v in pairs(ngx.req.get_headers()) do
		ngx.req.set_header(k, v)
	end
	ngx.ctx.request_get_headers_names = t
        return t
end

local function _resp_get_headers()
	local t = ngx.resp.get_headers()
	local count = #_table_keys(t)
	if count > 50 then
		ngx.log(ngx.ERR,"ERR resp_get_headers")
		ngx.exit(503)
	end
	ngx.ctx.response_get_headers = t
        return t
end


local function _resp_get_headers()
	local t = _table_keys(ngx.resp.get_headers())
	local count = #tab
	if count > 50 then
		ngx.log(ngx.ERR,"ERR get_headers_names")
		ngx.exit(503)
	end
	ngx.ctx.response_get_headers_names = t
        return t
end

_M.request = {
	ARGS = function() return ngx.ctx.request_args or _args() end,
	ARGS_NAMES = function() return ngx.ctx.request_args_names or _args_names() end,
	ARGS_GET = function() return ngx.ctx.request_args_get or _args_get() end,
	ARGS_GET_NAMES = function() return ngx.ctx.request_args_get_names or _args_get_names() end,
	ARGS_POST = function() return ngx.ctx.request_args_post or _args_post() end,
	ARGS_POST_NAMES = function() return ngx.ctx.request_args_post_names or _args_post_names() end,
	REMOTE_ADDR = function() return  ngx.var.remote_addr end,
	BIN_REMOTE_ADDR = function() return ngx.var.binary_remote_addr end,
	SCHEME = function() return ngx.var.scheme end,
	REMOTE_HOST = function() return  ngx.var.host end,
	SERVER_ADDR = function() return tostring(ngx.var.server_addr) end,
	REMOTE_USER = function() return ngx.var.remote_user end,
	SERVER_NAME = function() return ngx.var.server_name end,
	SERVER_PORT = function() return ngx.var.server_port end,
	HTTP_VERSION = function() return tostring(ngx.req.http_version()) end,
	REQUEST_METHOD = function() return ngx.req.get_method() end,
	URI = function() return ngx.var.uri end,
	URI_ARGS = function() return ngx.req.get_uri_args() end,
	METHOD = function() return ngx.req.get_method() end,
	QUERY_STRING = function() return ngx.var.query_string or "" end,
	REQUEST_URI = function() return ngx.var.request_uri end,
	REQUEST_BASENAME = function() return ngx.var.uri end,
	REQUEST_LINE = function() return ngx.var.request end,
	REQUEST_PROTOCOL = function() return ngx.var.server_protocol end,
	REQUEST_COOKIES = function() return  take_cookies() or {} end,
	REQUEST_COOKIES_NAMES = function() return _table_keys(take_cookies()) or {} end,
	HTTP_USER_AGENT = function() return ngx.var.http_user_agent or "-" end,
	RAW_HEADER = function() return ngx.req.raw_header() end,
	HTTP_REFERER = function() return ngx.var.http_referer or "-"  end,
	REQUEST_HEADERS = function() return ngx.ctx.request_get_headers or _get_headers() end,
	REQUEST_HEADERS_NAMES = function() return ngx.ctx.request_get_headers_names or _get_headers_names() end,
	TIME = function() return ngx.localtime() end,
	TIME_EPOCH = function() return ngx.time() end,
	FILE_NAMES = function() return ngx.ctx.form_file_name or {} end,
	FILE_TYPES = function() return ngx.ctx.form_file_type or {} end ,
	RESP_BODY = function() return ngx.ctx.response_get_data or _resp_body() end ,
	--RESP_COOKIES = function() return "" end,
	RESP_HEADERS = function() return ngx.ctx.response_get_headers or  _resp_get_headers() end,
	RESP_HEADERS_NAMES = function() return ngx.ctx.response_get_headers_names or _resp_get_headers() end,
	--RX_CAPTURE = function() return ngx.ctx.rx_capture or "" end,
	--RX_CAPTURE = function() return _resp_body()  end,
}


return _M
