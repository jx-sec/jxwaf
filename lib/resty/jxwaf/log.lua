local logger = require "resty.jxwaf.socket"
local cjson = require "cjson.safe"
local waf = require "resty.jxwaf.waf"
local uuid = require "resty.jxwaf.uuid"
local aliyun_log = require "resty.jxwaf.aliyun_log"
local waf_rule = waf.get_waf_rule()
local host = ngx.var.host
local string_sub = string.sub
local log_host = waf_rule[host] or ngx.ctx.wildcard_host
local ngx_req_get_headers = ngx.req.get_headers
local config_info = waf.get_config_info()

if log_host then
  -- remote log
  if log_host['log_set']['log_remote'] == "true" then
    --if not logger.initted() then
      local ok,err = logger.init{
        host = log_host['log_set']['log_ip'],
        port = tonumber(log_host['log_set']['log_port']),
        sock_type = log_host['log_set']['log_sock_type'],
        flush_limit = 1,
        }
      if not ok then
        ngx.log(ngx.ERR,"failed to initialize the logger: ",err)
        return 
      end
    --end
    local rule_log = ngx.ctx.rule_log

    if rule_log then
      if log_host['log_set']['log_sock_type'] == "udp" then
        if #rule_log['body'] > 60000 then
          local sub_body = string_sub(1,60000) 
          rule_log['body'] = sub_body
        end
      end
      rule_log['request_time'] = ngx.localtime()
      rule_log['uuid'] = uuid.generate_random()
      rule_log['upstream_status'] = ngx.var.upstream_status
      rule_log['upstream_connect_time'] = ngx.var.upstream_connect_time
      local bytes, err = logger.log(cjson.encode(rule_log))
      if err then
        ngx.log(ngx.ERR, "failed to log message: ", err)
      end
    end
    local error_log = ngx.ctx.error_log
    if error_log then
      if log_host['log_set']['log_sock_type'] == "udp" then
        if #rule_log['body'] > 60000 then
          local sub_body = string_sub(1,60000) 
          rule_log['body'] = sub_body
        end
      end
      error_log['request_time'] = ngx.localtime()
      error_log['uuid'] = uuid.generate_random()
      local bytes, err = logger.log(cjson.encode(error_log))
      if err then
        ngx.log(ngx.ERR, "failed to log message: ", err)
      end
    end
  end
  -- remote log
  -- local log
  if log_host['log_set']['log_local'] == "true" then
    local rule_log = ngx.ctx.rule_log
    if rule_log then
      rule_log['request_time'] = ngx.localtime()
      rule_log['uuid'] = uuid.generate_random()
      rule_log['upstream_status'] = ngx.var.upstream_status
      rule_log['upstream_connect_time'] = ngx.var.upstream_connect_time
      ngx.log(ngx.ERR,cjson.encode(rule_log))
    end
    local error_log = ngx.ctx.error_log
    if error_log then
      error_log['request_time'] = ngx.localtime()
      error_log['uuid'] = uuid.generate_random()
      ngx.log(ngx.ERR,cjson.encode(error_log))
    end
  end
  --local log
  --aliyun log
  if log_host['log_set']['aliyun_log'] == "true" then
    local endpoint = log_host['log_set']['endpoint'] or "http://cn-beijing.log.aliyuncs.com"
    local project = log_host['log_set']['project'] or "jxwaf-log"
    local logstore = log_host['log_set']['logstore'] or config_info.waf_api_key
    local source = ngx.var.hostname
    local access_id = log_host['log_set']['access_id'] or ""
    local access_key = log_host['log_set']['access_key'] or ""
    local topic = log_host['log_set']['topic'] or host
    local rule_log = ngx.ctx.rule_log
    if rule_log then
      rule_log['request_time'] = ngx.localtime()
      rule_log['uuid'] = uuid.generate_random()
      rule_log['upstream_status'] = ngx.var.upstream_status
      rule_log['upstream_connect_time'] = ngx.var.upstream_connect_time
      local headers = rule_log['headers']
      rule_log['headers'] = nil 
      local attack_client,attack_config = aliyun_log.init_config(endpoint,project,logstore,source,access_id,access_key,topic.."_attack_log")
      if not attack_client then
        ngx.log(ngx.ERR,"aliyun log init client error!")
        return 
      end
      local aliyun_send_attack_log_result = aliyun_log.send_log(attack_client,attack_config,cjson.encode(rule_log),cjson.encode(headers))
      if not aliyun_send_attack_log_result then
        ngx.log(ngx.ERR,"aliyun log send attack_log error!")
        return 
      end
      
      local error_log = ngx.ctx.error_log
      if error_log then
        error_log['request_time'] = ngx.localtime()
        error_log['uuid'] = uuid.generate_random()
        local error_client,error_config = aliyun_log.init_config(endpoint,project,logstore,source,access_id,access_key,topic.."_error_log")
        if not error_client then
          ngx.log(ngx.ERR,"aliyun log init client error!")
          return 
        end
        local aliyun_send_error_log_result = aliyun_log.send_log(error_client,error_config,cjson.encode(error_log),cjson.encode(headers))
        if not aliyun_send_error_log_result then
          ngx.log(ngx.ERR,"aliyun log send error_log error!")
        return 
      end
      end
    end
  end  
  --aliyun log

  
end
