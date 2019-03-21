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
local rule_observ_log = ngx.ctx.rule_observ_log
if config_info.observ_mode == "true" then
if rule_observ_log and #rule_observ_log ~= 0 then
	for  _,v in ipairs(rule_observ_log) do
			v['http_request_time'] = ngx.localtime()
			v['http_request_host'] = ngx.req.get_headers()["Host"]
			local match_captures = v['rule_match_captures']
			if match_captures then
				v['rule_match_captures'] = ngx.re.gsub(match_captures, [=[\\x]=], [=[\\x]=], "oij")
				v['rule_match_captures'] = ngx.re.gsub(match_captures, [=[\\u]=], [=[\\u]=], "oij")
			end
       		local bytes, err = logger.log(cjson.encode(v))
		if err then
			ngx.log(ngx.ERR, "failed to log message: ", err)	
		end
	end
end
else
if rule_log then
	rule_log['http_request_time'] = ngx.localtime()
	rule_log['http_request_host'] = ngx.req.get_headers()["Host"]
	local match_captures = rule_log['rule_match_captures']
	if match_captures then
		rule_log['rule_match_captures'] = ngx.re.gsub(match_captures, [=[\\x]=], [=[\\x]=], "oij")
		rule_log['rule_match_captures'] = ngx.re.gsub(match_captures, [=[\\u]=], [=[\\u]=], "oij")
	end
	local bytes, err = logger.log(cjson.encode(rule_log))
	if err then
		ngx.log(ngx.ERR, "failed to log message: ", err)
	end
end
end

end

if config_info.log_local == "true" then
	if config_info.observ_mode == "true" then
		local rule_observ_log = ngx.ctx.rule_observ_log
		if type(rule_observ_log) ~= "table" then
			ngx.log(ngx.ERR,"BUG find!!!")
			ngx.log(ngx.ERR,ngx.req.raw_header())
			ngx.log(ngx.ERR,ngx.req.get_body_data())
		end
		if rule_observ_log and #rule_observ_log ~= 0 then
			for  _,v in ipairs(rule_observ_log) do
				v['http_request_time'] = ngx.localtime()
				v['http_request_host'] = ngx.req.get_headers()["Host"]
				local match_captures = v['rule_match_captures']
				if match_captures then
					v['rule_match_captures'] = ngx.re.gsub(match_captures, [=[\\x]=], [=[\\x]=], "oij")
					v['rule_match_captures'] = ngx.re.gsub(match_captures, [=[\\u]=], [=[\\u]=], "oij")
				end
				ngx.log(ngx.ERR,cjson.encode(v))
			end
		end
		
	else
		local rule_log = ngx.ctx.rule_log
		local rule_limit_reject_log = ngx.ctx.rule_limit_reject_log
		if rule_log then
			rule_log['http_request_time'] = ngx.localtime()
			rule_log['http_request_host'] = ngx.req.get_headers()["Host"]
			local match_captures = rule_log['rule_match_captures']
			if match_captures then
				rule_log['rule_match_captures'] = ngx.re.gsub(match_captures, [=[\\x]=], [=[\\x]=], "oij")
				rule_log['rule_match_captures'] = ngx.re.gsub(match_captures, [=[\\u]=], [=[\\u]=], "oij")
			end
			ngx.log(ngx.ERR,cjson.encode(rule_log))
		end
		if rule_limit_reject_log then
			rule_limit_reject_log['http_request_time'] = ngx.localtime()
			rule_limit_reject_log['http_request_host'] = ngx.req.get_headers()["Host"]
			ngx.log(ngx.ERR,cjson.encode(rule_limit_reject_log))
		end
	end
end



