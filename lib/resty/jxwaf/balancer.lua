local balancer = require "ngx.balancer"
local waf = require "resty.jxwaf.waf"
local request = require "resty.jxwaf.request"
local waf_rule = waf.get_waf_rule()
local host = ngx.var.host
local balance_host = waf_rule[host]
local scheme = ngx.var.scheme
local exit_code = require "resty.jxwaf.exit_code"

if balance_host and balance_host['domain_set'][scheme] == "true" then
	local ip_lists = balance_host["domain_set"]["source_ip"]
	local port = balance_host["domain_set"]["source_http_port"]
	if not ngx.ctx.tries then
		ngx.ctx.tries = 0	
	end
	ngx.ctx.tries = ngx.ctx.tries + 1
	if not ngx.ctx.ip_lists then
		ngx.ctx.ip_lists = ip_lists
	end
	local ip_count = (string.sub(ngx.var.remote_addr,-1) % #ngx.ctx.ip_lists) + 1
	local _host = ngx.ctx.ip_lists[ip_count]
	local state_name,state_code = balancer.get_last_failure()
	if state_name == "failed" then
		for k,v in ipairs(ngx.ctx.ip_lists) do
        		if v == _host then
                		if not (#ngx.ctx.ip_lists == 1) then
                		table.remove(ngx.ctx.ip_lists,k)
                		ip_count = (string.sub(ngx.var.remote_addr,-1) % #ngx.ctx.ip_lists) + 1
                		_host = ngx.ctx.ip_lists[ip_count]
                		end
        		end
		end
	end
	local ok,err = balancer.set_current_peer(_host,port)
	if not ok then
    local error_info = request.request['HTTP_FULL_INFO']()
    error_info['log_type'] = "error_log"
    error_info['error_type'] = "balancer"
    error_info['error_info'] = "failed to set the current peer: "..err
    ngx.ctx.error_log = error_info
    ngx.log(ngx.ERR,"failed to set the current peer: ",err)
    exit_code.return_error()
	end
else
	exit_code.return_no_exist()
end

