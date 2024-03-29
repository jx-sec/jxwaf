local logger_socket = require "resty.jxwaf.socket"
local cjson = require "cjson.safe"
local waf = require "resty.jxwaf.waf"
local string_sub = string.sub
local config_info = waf.get_config_info()
local table_concat = table.concat
local table_insert = table.insert
local request = require "resty.jxwaf.request"
local producer = require "resty.kafka.producer"

local sys_log_conf_data  = waf.get_sys_log_conf_data()
local ctx_waf_log = ngx.ctx.waf_log


if sys_log_conf_data["log_remote"] == "true" and (ctx_waf_log or sys_log_conf_data["log_all"] == "true" ) then
  local waf_log = {}
  waf_log['host'] = ngx.var.host
  waf_log['request_id'] = ngx.ctx.request_uuid
  waf_log['waf_node_uuid'] = config_info['waf_node_uuid']
  waf_log['bytes_sent'] = ngx.var.bytes_sent or ""
  waf_log['bytes_received'] = ngx.var.request_length or ""  
  waf_log['upstream_addr'] = ngx.var.upstream_addr  or ""
  waf_log['upstream_bytes_received'] = ngx.var.upstream_bytes_received or ""
  waf_log['upstream_response_time'] = ngx.var.upstream_response_time  or ""
  waf_log['upstream_bytes_sent'] = ngx.var.upstream_bytes_sent or ""
  waf_log['upstream_status'] = ngx.var.upstream_status  or ""
  waf_log['x_forwarded_for'] = ngx.var.x_forwarded_for  or ""
  waf_log['status'] = ngx.var.status
  waf_log['process_time'] = ngx.var.request_time
  waf_log['request_time'] = ngx.localtime()
  local raw_headers = request.get_args("http_args","raw_header")
  if #raw_headers > 4096 then
    waf_log['raw_headers'] = string_sub(raw_headers,1,4096)
  else
    waf_log['raw_headers'] = raw_headers
  end
  waf_log['scheme'] = ngx.var.scheme
  waf_log['version'] = tostring(ngx.req.http_version())
  waf_log['uri'] = ngx.var.uri
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
  waf_log['connections_active'] = ngx.var.connections_active or ""
  waf_log['connections_waiting'] = ngx.var.connections_waiting or ""
  waf_log['content_length'] = ngx.var.content_length or ""
  waf_log['cookie'] = ngx.var.cookie or ""
  waf_log['referer'] = ngx.var.referer or ""
  waf_log['content_type'] = ngx.var.content_type or ""
  waf_log['ssl_ciphers'] = ngx.var.ssl_ciphers or ""
  waf_log['ssl_protocol'] = ngx.var.ssl_protocol or ""
  local raw_resp_headers = ngx.resp.get_headers() 
  local raw_resp_headers_table = {} 
  for k,v in pairs(raw_resp_headers) do
    if type(v) == 'string' then
        table_insert(raw_resp_headers_table,k..": "..v)
    elseif  type(v) == 'table' then
        table_insert(raw_resp_headers_table,k..": "..v[1])
    end
  end
  local raw_resp_header_data = table_concat(raw_resp_headers_table,"\r\n")
  if #raw_resp_header_data > 4096 then
    waf_log['raw_resp_headers'] = string_sub(raw_resp_header_data,1,4096)
  else
    waf_log['raw_resp_headers'] = raw_resp_header_data
  end
  if ctx_waf_log then
    waf_log['waf_module']  = ctx_waf_log['waf_module']
    waf_log['waf_policy']  = ctx_waf_log['waf_policy']
    waf_log['waf_action']  = ctx_waf_log['waf_action']
    waf_log['waf_extra']  = ctx_waf_log['waf_extra'] or ""
  else
    waf_log['waf_module'] = ""
    waf_log['waf_policy'] = ""
    waf_log['waf_action'] = ""
    waf_log['waf_extra'] = ""
  end

  if sys_log_conf_data['log_remote_type'] == "kafka" then
    local kafka_broker_list = sys_log_conf_data['kafka_bootstrap_servers']
    local kafka_topic = sys_log_conf_data['kafka_topic']
    local bp = producer:new(kafka_broker_list, { producer_type = "async"  })
    local ok, err = bp:send(kafka_topic, waf_log['request_id'], cjson.encode(waf_log))
    if not ok then
      ngx.log(ngx.ERR, "failed to send kafka message: ", err)
    end
  else
    local logger = logger_socket:new()
    if not logger:initted() then
      local ok,err = logger:init{
        host = sys_log_conf_data['log_ip'],
        port = tonumber(sys_log_conf_data['log_port']),
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
end

if sys_log_conf_data["log_local_debug"] == "true" and (ctx_waf_log or sys_log_conf_data["log_all"] == "true" ) then
  local waf_log = {}
  waf_log['host'] = ngx.var.host
  waf_log['status'] = ngx.var.status
  waf_log['uri'] = ngx.var.uri
  waf_log['src_ip'] = ngx.ctx.src_ip or ngx.var.remote_addr
  waf_log['user_agent'] = ngx.var.http_user_agent or ""
  waf_log['request_id'] = ngx.ctx.request_uuid
  waf_log['process_time'] = ngx.var.request_time
  if ctx_waf_log then
    waf_log['waf_module']  = ctx_waf_log['waf_module']
    waf_log['waf_policy']  = ctx_waf_log['waf_policy']
    waf_log['waf_action']  = ctx_waf_log['waf_action']
    waf_log['waf_extra']  = ctx_waf_log['waf_extra']  or ""
  else
    waf_log['waf_module'] = ""
    waf_log['waf_policy'] = ""
    waf_log['waf_action'] = ""
    waf_log['waf_extra'] = ""
  end
  ngx.log(ngx.ERR,cjson.encode(waf_log))
end
