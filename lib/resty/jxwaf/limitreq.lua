
local _M = {}
local limit_req = require "resty.limit.req"
local limit_count = require "resty.limit.count"
_M.version = "1.0"

function _M.limit_req_rate(rule,process_key)
	local limit_store = "limit_req"
	local rate = tonumber(rule.rule_rate_or_count)
	local burst = tonumber(rule.rule_burst_or_time)
	local key = process_key 
	local nodelay = rule.rule_nodelay
	local rule_id = rule.rule_id
	local rule_detail = rule.rule_detail
	local rule_limit_log = rule.rule_log
	

	local lim, err = limit_req.new(limit_store, rate, burst)
	if not lim then
		ngx.log(ngx.ERR,"failed to instantiate a resty.limit.req object: ", err," limit_store is: ",limit_store)
		return	ngx.exit(500)
	end
	local delay, err = lim:incoming(key, true)
	if not delay then
		if err == "rejected" then
			if rule_limit_log == "true" then
				local ctx_rule_limit_reject_log = {}
				ctx_rule_limit_reject_log.rule_id = rule_id
				ctx_rule_limit_reject_log.rule_detail = rule_detail
				ctx_rule_limit_reject_log.rule_err = err
				ctx_rule_limit_reject_log.uri = ngx.var.uri
				ngx.ctx.rule_limit_reject_log = ctx_rule_limit_reject_log
			end
			return ngx.exit(501)
		
			
		end
		ngx.log(ngx.ERR, "failed to limit req: ", err)
		return ngx.exit(503)
	end
	
	if nodelay == "true" then


	else
		local excess = err
		if rule_limit_log == "true" and delay >= 0.001 then
			local ctx_rule_limit_delay_log = {}
			ctx_rule_limit_delay_log.rule_id = rule_id
                        ctx_rule_limit_delay_log.rule_detail = rule_detail
                        ctx_rule_limit_delay_log.rule_excess = excess
			ctx_rule_limit_delay_log.uri = ngx.var.uri
                        ngx.ctx.rule_limit_delay_log = ctx_rule_limit_delay_log
		end
		if delay >= 0.001 then
			ngx.sleep(delay)
		end
	end



end

function _M.limit_req_count(rule,process_key)
	local limit_store = "limit_req_count"
	local count = tonumber(rule.rule_rate_or_count)
	local time = tonumber(rule.rule_burst_or_time)
	local key = process_key 
	local rule_id = rule.rule_id
	local rule_detail = rule.rule_detail
	local rule_limit_log = rule.rule_log

	local lim, err = limit_count.new(limit_store, count, time)
	if not lim then
		ngx.log(ngx.ERR,"failed to instantiate a resty.limit.count object: ", err," limit_store is: ",limit_store)
		return	ngx.exit(500)
	end
	local delay, err = lim:incoming(key, true)
	if not delay then
		if err == "rejected" then
			if rule_limit_log == "true" then
				local ctx_rule_limit_reject_log = {}
				ctx_rule_limit_reject_log.rule_id = rule_id
				ctx_rule_limit_reject_log.rule_detail = rule_detail
				ctx_rule_limit_reject_log.rule_err = err
				ctx_rule_limit_reject_log.uri = ngx.var.uri
				ngx.ctx.rule_limit_reject_log = ctx_rule_limit_reject_log
			end
			return ngx.exit(501)
		
			
		end
		ngx.log(ngx.ERR, "failed to limit count: ", err)
		return ngx.exit(503)
	end
	
end

return _M

