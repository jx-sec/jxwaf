local logger = require "resty.jxwaf.socket"
local cjson = require "cjson.safe"
local waf = require "resty.jxwaf.waf"
local random_uuid = require "resty.jxwaf.uuid"
local waf_rule = waf.get_waf_rule()
local host = ngx.var.host
local string_sub = string.sub
local log_host = waf_rule[host] or ngx.ctx.req_host
local ngx_req_get_headers = ngx.req.get_headers
local config_info = waf.get_config_info()
local table_concat = table.concat
local log_config = waf.get_log_config()
local request = require "resty.jxwaf.request"


if log_host then
  local localtime = ngx.localtime()
  local uuid = random_uuid.generate_random()
  local bytes_sent = ngx.var.bytes_sent or "-"
  local bytes_received = ngx.var.request_length or "-"  
  local upstream_addr = ngx.var.upstream_addr  or "-"
  local upstream_bytes_received = ngx.var.upstream_bytes_received or "-"
  local upstream_response_time = ngx.var.upstream_response_time  or "-"
  local upstream_bytes_sent = ngx.var.upstream_bytes_sent or "-"
  local upstream_status = ngx.var.upstream_status  or "-"
  local status= ngx.var.status
  local request_process_time = ngx.var.request_time
  local client_ip = request.request['REMOTE_ADDR']()
  local raw_header = cjson.encode(request.request['ARGS_HEADERS']())
  local raw_body = request.request['HTTP_BODY']()
  local raw_get = ngx.var.query_string or ""
  local req_uri = ngx.var.uri
  if log_host['protection_set'] and log_host['protection_set']['data_mask'] == "true"  then
    local data_mask_set = log_host['data_mask_set']
    local data_mask_global_set = log_host['data_mask_global_set']
    if data_mask_set and data_mask_set[req_uri] then
      local data_header = data_mask_set[req_uri]['header']
      local data_post = data_mask_set[req_uri]['post']
      local data_get = data_mask_set[req_uri]['get']
      if data_get  then
        if type(data_get) == 'table' then
          local req_get = request.request['ARGS_GET']()
          for _,v in ipairs(data_get) do
            if req_get[v] then
              req_get[v] = '*'
            end
          end
          raw_get = ngx.encode_args(req_get)
        else
          raw_get = '*'
        end
      end
      if data_post  then
        if type(data_post) == 'table' then
          local req_post = request.request['ARGS_POST']()
          for _,v in ipairs(data_post) do
            if req_post[v] then
              req_post[v] = '*'
            end
          end
          for k,v in ipairs(req_post) do
            req_post[k] = nil
            req_post[tostring(k)] = v
          end
          raw_body = ngx.encode_args(req_post)
        else
          raw_body = '*'
        end
        
      end
      if data_header  then
        if type(data_header) == 'table' then
          local req_header = request.request['ARGS_HEADERS']()
          for _,v in ipairs(data_header) do
            if req_header[v] then
              req_header[v] = '*'
            end
          end
          raw_header = cjson.encode((req_header))
        else
          raw_header = '*'
        end
      end
    elseif data_mask_global_set then
      local global_data_get = data_mask_global_set['get']
      local global_data_post = data_mask_global_set['post']
      local global_data_header = data_mask_global_set['header']
      if global_data_get then
        if type(global_data_get) == 'table' then
          local req_get = request.request['ARGS_GET']()
          for _,v in ipairs(global_data_get) do
            if req_get[v] then
              req_get[v] = '*'
            end
          end
          raw_get = ngx.encode_args(req_get)
        end
      end
      if global_data_post then
        if type(global_data_post) == 'table' then
          local req_post = request.request['ARGS_POST']()
          for _,v in ipairs(global_data_post) do
            if req_post[v] then
              req_post[v] = '*'
            end
          end
          for k,v in ipairs(req_post) do
            req_post[k] = nil
            req_post[tostring(k)] = v
          end
          raw_body = ngx.encode_args(req_post)
        end
      end
      if global_data_header then
        if type(global_data_header) == 'table' then
          local req_header = request.request['ARGS_HEADERS']()
          for _,v in ipairs(global_data_header) do
            if req_header[v] then
              req_header[v] = '*'
            end
          end
          raw_header = cjson.encode((req_header))
        end
      end
    end    
  end
  local waf_log = {}
  waf_log['host'] = host
  waf_log['uuid'] = uuid
  waf_log['server_uuid'] = config_info['waf_node_uuid']
  waf_log['bytes_sent'] =  bytes_sent
  waf_log['bytes_received'] = bytes_received
  waf_log['upstream_bytes_sent'] = upstream_bytes_sent or "-"
  waf_log['upstream_bytes_received'] =  upstream_bytes_received or "-"
  waf_log['upstream_addr'] = upstream_addr or "-"
  waf_log['upstream_response_time'] =  upstream_response_time or "-"
  waf_log['request_process_time'] =  request_process_time or "-"
  waf_log['status'] =  status
  waf_log['upstream_status'] =  upstream_status or "-"
  waf_log['request_time'] = localtime
  waf_log['raw_header'] = raw_header
  waf_log['scheme'] = ngx.var.scheme
  waf_log['version'] = tostring(ngx.req.http_version())
  waf_log['uri'] = req_uri
  waf_log['method'] = ngx.req.get_method()
  waf_log['query_string'] = raw_get
  waf_log['body'] = raw_body
  waf_log['client_ip'] = client_ip
  waf_log['user_agent'] = ngx.var.http_user_agent or ""
  waf_log['connections_active'] = ngx.var.connections_active
  waf_log['connections_waiting'] = ngx.var.connections_waiting
  if ngx.ctx.waf_log  then
    local tmp_waf_log = ngx.ctx.waf_log
    waf_log['log_type'] = tmp_waf_log['log_type']
    waf_log['protection_type'] = tmp_waf_log['protection_type']
    waf_log['protection_info'] =  tmp_waf_log['protection_info']
  else
      waf_log['log_type'] = "access"
      waf_log['protection_type'] = ""
      waf_log['protection_info'] = ""
      if log_config['all_request_log'] == "false" then
        return nil
      end
  end
  
  if log_config['log_local'] == "true" then
    ngx.log(ngx.ERR,cjson.encode(waf_log))
  end
  
  if log_config['log_remote'] == "true" then
    local ok,err = logger.init{
      host = log_config['log_ip'],
      port = tonumber(log_config['log_port']),
      sock_type = "tcp",
      flush_limit = 1,
      pool_size = 100,
    }
    if not ok then
      ngx.log(ngx.ERR,"failed to initialize the logger: ",err)
      return 
    end
    local _, send_err = logger.log(cjson.encode(waf_log).."\n")
    if send_err then
      ngx.log(ngx.ERR, "failed to log message: ", send_err)
    end
  end
end
