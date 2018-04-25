local waf = require "resty.jxwaf.waf"
local config_info = waf.get_config_info()

if ngx.ctx.resp_js_insert == "true" and ngx.ctx.is_inject ~= "true" then
	local payload = [=[<script>alert(/test/)</script>]=]
	ngx.arg[1] = ngx.arg[1]..payload
	ngx.ctx.is_inject = "true"
end

if (config_info.resp_engine == "true" and ngx.ctx.is_inject ~= "true" )  then
	local rules = waf.get_resp_rule()
	if #rules == 0 then
		ngx.log(ngx.CRIT,"can not find resp rules")
		return
	end
	local sign = nil
	for _,rule in ipairs(rules) do
			for _,match in ipairs(rule.rule_matchs) do
					for _,var in ipairs(match.rule_vars) do
							if var.rule_var == "RESP_HEADERS" then
									sign = true
							end

					end
			end

	end

	if sign  or ((#ngx.arg[1] ~= 0) and (ngx.arg[2] ~= true)) then		
	local result,rule = waf.rule_match(rules)
	
	if result and rule.rule_action == "deny" then
		ngx.log(ngx.ERR,"success")
		ngx.arg[1] = nil
	end
	
	if result and (rule.rule_action == "redirect" or ngx.ctx.resp_js_insert == "true") then
			local payload = [=[<script>alert(/test/)</script>]=]
			ngx.arg[1] = ngx.arg[1]..payload
			ngx.ctx.is_inject = "true"
	
	end

	end
--	ngx.update_time()
--	ngx.log(ngx.ERR,ngx.now() - ngx.req.start_time())
end

