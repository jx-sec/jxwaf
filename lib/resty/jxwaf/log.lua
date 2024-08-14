local logger_socket = require "resty.jxwaf.socket"
local cjson = require "cjson.safe"
local waf = require "resty.jxwaf.waf"
local string_sub = string.sub
local config_info = waf.get_config_info()
local table_concat = table.concat
local table_insert = table.insert
local request = require "resty.jxwaf.request"

local sys_conf_data  = waf.get_sys_conf_data()
local ctx_waf_log = ngx.ctx.waf_log

if sys_conf_data["log_conf_remote"] == "true" and (ctx_waf_log or sys_conf_data["log_all"] == "true" ) then
  local waf_log = {}
  waf_log['host'] = ngx.var.http_host or ""
  waf_log['request_uuid'] = ngx.ctx.request_uuid
  waf_log['waf_node_uuid'] = config_info['waf_node_uuid']
  waf_log['upstream_addr'] = ngx.var.upstream_addr  or ""
  waf_log['upstream_response_time'] = ngx.var.upstream_response_time  or ""
  waf_log['upstream_status'] = ngx.var.upstream_status  or ""
  waf_log['status'] = ngx.var.status
  waf_log['process_time'] = ngx.var.request_time
  waf_log['request_time'] = ngx.localtime()
  waf_log['ssl_protocol'] = ngx.var.ssl_protocol or ""
  waf_log['ssl_cipher'] = ngx.var.ssl_cipher or ""
  waf_log['jxwaf_devid'] = request.get_args("cookie_args","jxwaf_devid") or ""
  local raw_headers = request.get_args("http_args","raw_header")
  if #raw_headers > 4096 then
    waf_log['raw_headers'] = string_sub(raw_headers,1,4096)
  else
    waf_log['raw_headers'] = raw_headers
  end
  waf_log['scheme'] = ngx.var.scheme
  waf_log['version'] = tostring(ngx.req.http_version())
  waf_log['uri'] = ngx.var.uri
  waf_log['request_uri'] = ngx.var.request_uri
  waf_log['method'] = ngx.req.get_method()
  waf_log['query_string'] = ngx.var.query_string or ""
  local raw_body = request.get_args("http_args","raw_body") or ""
  if #raw_body > 4096 then
    waf_log['raw_body'] = string_sub(raw_body,1,4096)
  else
    waf_log['raw_body'] = raw_body
  end
  waf_log['src_ip'] = ngx.ctx.src_ip or ngx.var.remote_addr
  waf_log['user_agent'] = ngx.var.http_user_agent or ""
  waf_log['cookie'] = ngx.var.cookie or ""
  local raw_resp_headers = ngx.resp.get_headers() 
  local raw_resp_headers_table = {} 
  for k,v in pairs(raw_resp_headers) do
    if type(v) == 'string' then
        table_insert(raw_resp_headers_table,k..": "..v)
    elseif  type(v) == 'table' then
      for _, _v in ipairs(v) do
        table.insert(raw_resp_headers_table, k .. ": " .. _v)
      end
    end
  end
  local raw_resp_header_data = table_concat(raw_resp_headers_table,"\r\n")
  if #raw_resp_header_data > 4096 then
    waf_log['raw_resp_headers'] = string_sub(raw_resp_header_data,1,4096)
  else
    waf_log['raw_resp_headers'] = raw_resp_header_data
  end

   if sys_conf_data["log_response"] == "true" then
     waf_log['raw_resp_body'] = ngx.ctx.resp_body or ""
   else
     waf_log['raw_resp_body'] = ""
   end

   waf_log['iso_code'] = ngx.ctx.iso_code  or ""
   waf_log['city'] = ngx.ctx.city  or ""
   waf_log['latitude'] = ngx.ctx.latitude  or ""
   waf_log['longitude'] = ngx.ctx.longitude  or ""

  if ctx_waf_log then
    waf_log['waf_module']  = ctx_waf_log['waf_module']
    waf_log['waf_policy']  = ctx_waf_log['waf_policy']
    waf_log['waf_action']  = ctx_waf_log['waf_action']
    waf_log['waf_extra']  = ctx_waf_log['waf_extra'] or ""
  else
    waf_log['waf_module']  = ""
    waf_log['waf_policy'] = ""
    waf_log['waf_action'] = ""
    waf_log['waf_extra'] = ""
  end
    local logger = logger_socket:new()
    if not logger:initted() then
      local ok,err = logger:init{
        host = sys_conf_data['log_ip'],
        port = tonumber(sys_conf_data['log_port']),
        sock_type = "tcp",
        flush_limit = 1,
        timeout = 3000,
        max_retry_times = 3
      }
      if not ok then
        ngx.log(ngx.ERR,"failed to initialize the logger: ",err)
        return 
      end
    end
    local _, send_err = logger:log(cjson.encode(waf_log).."\n")
    if send_err then
      ngx.log(ngx.ERR, "failed to log message: ", send_err)
    end
end

if sys_conf_data["log_conf_local_debug"] == "true" and (ctx_waf_log or sys_conf_data["log_all"] == "true" )  then
  local waf_log = {}
  waf_log['host'] = ngx.var.http_host or ""
  waf_log['status'] = ngx.var.status
  waf_log['uri'] = ngx.var.uri
  waf_log['src_ip'] = ngx.ctx.src_ip or ngx.var.remote_addr
  waf_log['user_agent'] = ngx.var.http_user_agent or ""
  waf_log['request_uuid'] = ngx.ctx.request_uuid
  if ctx_waf_log then
    waf_log['waf_module']  = ctx_waf_log['waf_module']
    waf_log['waf_policy']  = ctx_waf_log['waf_policy']
    waf_log['waf_action']  = ctx_waf_log['waf_action']
    waf_log['waf_extra']  = ctx_waf_log['waf_extra']  or ""
  else
    waf_log['waf_module']  = ""
    waf_log['waf_policy'] = ""
    waf_log['waf_action'] = ""
    waf_log['waf_extra'] = ""
  end
  ngx.log(ngx.ERR,cjson.encode(waf_log))
end
