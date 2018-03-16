local logger = require "resty.jxwaf.socket"
local cjson = require "cjson.safe"
local waf = require "resty.jxwaf.waf"
local config_info = waf.get_config_info()

if config_info.log_remote == "true" then
if not logger.initted() then
	local ok,err = logger.init{
			host = config_info.log_ip,
			port = tonumber(config_info.log_port),
			sock_type = config_info.log_sock_type,
			flush_limit = tonumber(config_info.log_flush_limit),
			}
	if not ok then
		ngx.log(ngx.ERR,"failed to initialize the logger: ",err)
		return 
	end
end
local rule_log = ngx.ctx.rule_log

if rule_log then
	local bytes, err = logger.log(cjson.encode(rule_log))
	
	if err then
		ngx.log(ngx.ERR, "failed to log message: ", err)
	end
end
end

if config_info.log_local == "true" then
	
	local rule_log = ngx.ctx.rule_log
	if rule_log then
	ngx.log(ngx.ERR,cjson.encode(rule_log))
	end
end



