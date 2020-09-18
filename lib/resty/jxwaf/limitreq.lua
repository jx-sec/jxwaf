local _M = {}
local limit_req = require "resty.limit.req"
local limit_count = require "resty.limit.count"
local request = require "resty.jxwaf.request"
local exit_code = require "resty.jxwaf.exit_code"
_M.version = "2.0"

function _M.limit_req_rate(ip_qps,ip_expire_qps,process_key)
	local limit_store = "limit_req"
	local rate = tonumber(ip_qps)
  local burst = tonumber(ip_expire_qps)
	local key = process_key 
	local lim, err = limit_req.new(limit_store, rate, burst)
	if not lim then
    local waf_log = {}
    waf_log['log_type'] = "error"
    waf_log['protecion_type'] = "limit_req_rate"
    waf_log['protecion_info'] = "limit_req_rate,failed to instantiate a resty.limit.req object: "..err.." limit_store is: "..limit_store
    ngx.ctx.waf_log = waf_log
		ngx.log(ngx.ERR,"limit_req_rate,failed to instantiate a resty.limit.req object: ", err," limit_store is: ",limit_store)
		exit_code.return_error()
	end
	local delay, err_incoming = lim:incoming(key, true)
	if not delay then
		if err_incoming == "rejected" then
      return true
		else
      local waf_log = {}
      waf_log['log_type'] = "error"
      waf_log['protecion_type'] = "limit_req_rate"
      waf_log['protecion_info'] =  "limit_req_rate,failed to limit req: "..err_incoming
      ngx.ctx.waf_log = waf_log
      ngx.log(ngx.ERR, "limit_req_rate,failed to limit req: ", err_incoming)
      exit_code.return_error()
    end
	end
  if delay >= 0.001 then
    ngx.sleep(delay)
  end
  return nil
end 

function _M.limit_req_count(count,black_ip_time,process_key)
	local limit_store = "limit_req_count"
	local limit_count = tonumber(count)
	local limit_time = tonumber(black_ip_time)
	local key = process_key 
	local lim, err = limit_count.new(limit_store, limit_count, limit_time)
	if not lim then
    local waf_log = {}
    waf_log['log_type'] = "error"
    waf_log['protecion_type'] = "limit_req_count"
    waf_log['protecion_info'] = "limit_req_count,failed to instantiate a resty.limit.count object: "..err.." limit_store is: "..limit_store
    ngx.ctx.waf_log = waf_log
		ngx.log(ngx.ERR,"limit_req_count,failed to instantiate a resty.limit.count object: ", err," limit_store is: ",limit_store)
		exit_code.return_error()
	end
	local delay, err_incoming = lim:incoming(key, true)
	if not delay then
		if err_incoming == "rejected" then
      return true
		else
      local waf_log = {}
      waf_log['log_type'] = "error"
      waf_log['protecion_type'] = "limit_req_count"
      waf_log['protecion_info'] =  "limit_req_count,failed to limit count: "..err_incoming
      ngx.ctx.waf_log = waf_log
      ngx.log(ngx.ERR, "limit_req_count,failed to limit count: ", err_incoming)
      exit_code.return_error()
    end
	end
  return nil
end

function _M.limit_req_domain_rate(domain_qps,process_key)
  local limit_store = "limit_req"
  local rate = tonumber(domain_qps)
  local burst = 1
  local key = process_key 
  local lim, err = limit_req.new(limit_store, rate, burst)
  if not lim then
    local waf_log = {}
    waf_log['log_type'] = "error"
    waf_log['protecion_type'] = "limitreq_check"
    waf_log['protecion_info'] = "limit_req_domain,failed to instantiate a resty.limit.req object: "..err.." limit_store is: "..limit_store
    ngx.ctx.waf_log = waf_log
    ngx.log(ngx.ERR,"limit_req_domain,failed to instantiate a resty.limit.req object: ", err," limit_store is: ",limit_store)
    exit_code.return_error()
  end
  local delay, err_incoming = lim:incoming(key, true)
  if not delay then
    if err_incoming == "rejected" then
      return true
    else
      local waf_log = {}
      waf_log['log_type'] = "error"
      waf_log['protecion_type'] = "limit_req_rate"
      waf_log['protecion_info'] =  "limit_req_domain,failed to limit rate: "..err_incoming
      ngx.ctx.waf_log = waf_log
      ngx.log(ngx.ERR, "limit_req_domain,failed to limit req: ", err_incoming)
      exit_code.return_error()
    end
  end
  return nil
end

return _M

