local waf = require "resty.jxwaf.waf"
local config_info = waf.get_config_info()

if (config_info.resp_engine == "true") and (#ngx.arg[1] ~= 0) and (ngx.arg[2] ~= true) then
	local rules = waf.get_resp_rule()
	if #rules == 0 then
		ngx.log(ngx.CRIT,"can not find resp rules")
		return
	end

	local result,rule = waf.rule_match(rules)
	
	if result and rule.rule_action == "deny" then
		ngx.log(ngx.ERR,"success")
		ngx.arg[1] = nil
	end
--	ngx.update_time()
--	ngx.log(ngx.ERR,ngx.now() - ngx.req.start_time())
end

