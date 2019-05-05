local _M = {}
local limit_req = require "resty.limit.req"
local limit_count = require "resty.limit.count"
local request = require "resty.jxwaf.request"
local exit_code = require "resty.jxwaf.exit_code"

_M.version = "2.0"

function _M.limit_req_rate(rule,process_key)
	local limit_store = "limit_req"
	local rate = tonumber(rule.rule_rate_count)
  local burst = tonumber(rule.rule_burst_time)
	local key = process_key 
	local lim, err = limit_req.new(limit_store, rate, burst)
	if not lim then
    local error_info = request.request['HTTP_FULL_INFO']()
    error_info['log_type'] = "error_log"
    error_info['error_type'] = "limit_req"
    error_info['error_info'] = "limit_req_rate,failed to instantiate a resty.limit.req object: "..err.." limit_store is: "..limit_store
    ngx.ctx.error_log = error_info
		ngx.log(ngx.ERR,"limit_req_rate,failed to instantiate a resty.limit.req object: ", err," limit_store is: ",limit_store)
		exit_code.return_error()
	end
	local delay, err_incoming = lim:incoming(key, true)
	if not delay then
		if err_incoming == "rejected" then
      local limit_req_rate_log_info = request.request['HTTP_FULL_INFO']()
      limit_req_rate_log_info['log_type'] = "protection_log"
      limit_req_rate_log_info['protection_type'] = "limit_req"
      limit_req_rate_log_info['protection_info'] = "limit_req_rate"
      ngx.ctx.rule_log = limit_req_rate_log_info
			exit_code.return_limit()
		else
      local error_info = request.request['HTTP_FULL_INFO']()
      error_info['log_type'] = "error_log"
      error_info['error_type'] = "limit_req"
      error_info['error_info'] = "limit_req_rate,failed to limit req: "..err_incoming
      ngx.ctx.error_log = error_info
      ngx.log(ngx.ERR, "limit_req_rate,failed to limit req: ", err_incoming)
      exit_code.return_error()
    end
	end
  if delay >= 0.01 then
    ngx.sleep(delay)
  end
end 

function _M.limit_req_count(rule,process_key)
	local limit_store = "limit_req_count"
	local count = tonumber(rule.rule_rate_count)
	local time = tonumber(rule.rule_burst_time)
	local key = process_key 
	local lim, err = limit_count.new(limit_store, count, time)
	if not lim then
    local error_info = request.request['HTTP_FULL_INFO']()
    error_info['log_type'] = "error_log"
    error_info['error_type'] = "limit_req"
    error_info['error_info'] = "limit_req_count,failed to instantiate a resty.limit.count object: "..err.." limit_store is: "..limit_store
    ngx.ctx.error_log = error_info
		ngx.log(ngx.ERR,"limit_req_count,failed to instantiate a resty.limit.count object: ", err," limit_store is: ",limit_store)
		exit_code.return_error()
	end
	local delay, err_incoming = lim:incoming(key, true)
	if not delay then
		if err_incoming == "rejected" then
      local limit_req_count_log_info = request.request['HTTP_FULL_INFO']()
      limit_req_count_log_info['log_type'] = "protection_log"
      limit_req_count_log_info['protection_type'] = "limit_req"
      limit_req_count_log_info['protection_info'] = "limit_req_count"
      ngx.ctx.rule_log = limit_req_count_log_info
			exit_code.return_limit()
		else
      local error_info = request.request['HTTP_FULL_INFO']()
      error_info['log_type'] = "error_log"
      error_info['error_type'] = "limit_req"
      error_info['error_info'] = "limit_req_count,failed to limit count: "..err_incoming
      ngx.ctx.error_log = error_info
      ngx.log(ngx.ERR, "limit_req_count,failed to limit count: ", err_incoming)
      exit_code.return_error()
    end
	end
end

function _M.limit_req_domain_rate(rule,process_key)
  local limit_store = "limit_req"
  local rate = tonumber(rule.domain_qps)
  local burst = tonumber(rule.domain_qps) * 0.1
  local key = process_key 
  local lim, err = limit_req.new(limit_store, rate, burst)
  if not lim then
    local error_info = request.request['HTTP_FULL_INFO']()
    error_info['log_type'] = "error_log"
    error_info['error_type'] = "limit_req"
    error_info['error_info'] = "limit_req_domain,failed to instantiate a resty.limit.req object: "..err.." limit_store is: "..limit_store
    ngx.ctx.error_log = error_info
    ngx.log(ngx.ERR,"limit_req_domain,failed to instantiate a resty.limit.req object: ", err," limit_store is: ",limit_store)
    exit_code.return_error()
  end
  local delay, err_incoming = lim:incoming(key, true)
  if not delay then
    if err_incoming == "rejected" then
--count
      local limit_count_store = "limit_req_count"
      local count = tonumber(rule.attack_count)
      local time = tonumber(rule.attack_black_ip_time)
      local lim_count, err_count = limit_count.new(limit_store, count, time)
      if not lim_count then
        local error_info = request.request['HTTP_FULL_INFO']()
        error_info['log_type'] = "error_log"
        error_info['error_type'] = "limit_req"
        error_info['error_info'] = "limit_req_domain_count,failed to instantiate a resty.limit.count object: "..err_count.." limit_store is: "..limit_count_store
        ngx.ctx.error_log = error_info
        ngx.log(ngx.ERR,"limit_req_domain_count,failed to instantiate a resty.limit.count object: ", err_count," limit_store is: ",limit_count_store)
        exit_code.return_error()
      end
      local delay_count, err_count_incoming = lim_count:incoming(ngx.md5(ngx.var.remote_addr), true)
      if not delay_count then
        if err_count_incoming == "rejected" then
          local limit_domain_count_log_info = request.request['HTTP_FULL_INFO']()
          limit_domain_count_log_info['log_type'] = "limit_req"
          limit_domain_count_log_info['protection_type'] = "limit_req"
          limit_domain_count_log_info['protection_info'] = "limit_req_domain_count"
          ngx.ctx.rule_log = limit_domain_count_log_info
          exit_code.return_limit()
        end
        local error_info = request.request['HTTP_FULL_INFO']()
        error_info['log_type'] = "error_log"
        error_info['error_type'] = "limit_req"
        error_info['error_info'] = "limit_req_domain_count,failed to limit count: "..err
        ngx.ctx.error_log = error_info
        ngx.log(ngx.ERR, "limit_req_domain_count,failed to limit count: ", err)
        exit_code.return_error()
      end
--count
--rate
      local lim_rate, err_rate = limit_req.new(limit_store, tonumber(rule.attack_ip_qps), tonumber(rule.attack_ip_expire_qps))
        if not lim_rate then
          local error_info = request.request['HTTP_FULL_INFO']()
          error_info['log_type'] = "error_log"
          error_info['error_type'] = "limit_req"
          error_info['error_info'] = "limit_req_domain_rate,failed to instantiate a resty.limit.count object: "..err_rate.." limit_store is: "..limit_store
          ngx.ctx.error_log = error_info
          ngx.log(ngx.ERR,"limit_req_domain_rate,failed to instantiate a resty.limit.req object: ", err_rate," limit_store is: ",limit_store)
          exit_code.return_error()
        end
        local delay_rate, err_rate_incoming = lim_rate:incoming(ngx.md5(ngx.var.remote_addr), true)
        if not delay_rate then
          if err_rate_incoming == "rejected" then
            local limit_domain_rate_log_info = request.request['HTTP_FULL_INFO']()
            limit_domain_rate_log_info['log_type'] = "limit_req"
            limit_domain_rate_log_info['protection_type'] = "limit_req"
            limit_domain_rate_log_info['protection_info'] = "domain_req_rate"
            ngx.ctx.rule_log = limit_domain_rate_log_info
            exit_code.return_limit()
          end
          local error_info = request.request['HTTP_FULL_INFO']()
          error_info['log_type'] = "error_log"
          error_info['error_type'] = "limit_req"
          error_info['error_info'] = "limit_req_domain_rate,failed to limit rate: "..err_incoming
          ngx.ctx.error_log = error_info
          ngx.log(ngx.ERR, "limit_req_domain_rate,failed to limit req: ", err_incoming)
          exit_code.return_error()
        end
--rate
    else
      local error_info = request.request['HTTP_FULL_INFO']()
      error_info['log_type'] = "error_log"
      error_info['error_type'] = "limit_req"
      error_info['error_info'] = "limit_req_domain,failed to limit rate: "..err_incoming
      ngx.ctx.error_log = error_info
      ngx.log(ngx.ERR, "limit_req_domain,failed to limit req: ", err_incoming)
      exit_code.return_error()
    end
  end
end




function _M.limit_attack_ip(rule,process_key,istrue)
	local limit_store = "limit_attack_ip"
	local count = tonumber(rule.rule_rate_count)
	local time = tonumber(rule.rule_burst_time)
	local key = process_key 
	local lim, err = limit_count.new(limit_store, count, time)
	if not lim then
    local error_info = request.request['HTTP_FULL_INFO']()
    error_info['log_type'] = "error_log"
    error_info['error_type'] = "attack_ip_protection"
    error_info['error_info'] = "failed to instantiate a resty.attack.ip object: "..err.." limit_store is: "..limit_store
    ngx.ctx.error_log = error_info
		ngx.log(ngx.ERR,"failed to instantiate a resty.attack.ip object: ", err," limit_store is: ",limit_store)
		exit_code.return_error()
	end
	local delay, err_incoming = lim:incoming(key, istrue)
	if not delay then
		if err_incoming == "rejected" then
      local limit_attack_ip_log_info = request.request['HTTP_FULL_INFO']()
      limit_attack_ip_log_info['log_type'] = "protection_log"
      limit_attack_ip_log_info['protection_type'] = "attack_ip_protection"
      limit_attack_ip_log_info['protection_info'] = "attack_ip_protection"
      ngx.ctx.rule_log = limit_attack_ip_log_info
			exit_code.return_attack_ip()
		else
      local error_info = request.request['HTTP_FULL_INFO']()
      error_info['log_type'] = "error_log"
      error_info['error_type'] = "attack_ip_protection"
      error_info['error_info'] = "limit_attack_ip,failed to limit count: "..err_incoming
      ngx.ctx.error_log = error_info
      ngx.log(ngx.ERR, "limit_attack_ip,failed to limit count: ", err_incoming)
      exit_code.return_error()
    end
	end
end

return _M

