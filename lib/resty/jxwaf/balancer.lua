local balancer = require "ngx.balancer"
local waf = require "resty.jxwaf.waf"
local request = require "resty.jxwaf.request"
local host = ngx.var.host
local balance_host =  ngx.ctx.req_host
local scheme = ngx.var.scheme
local point_cache = require "resty.jxwaf.point_cache"

if balance_host and balance_host['domain_data'][scheme] == "true" then
	local ip_lists = ngx.ctx.component_source_ip or balance_host["domain_data"]["source_ip"]
	local port = ngx.ctx.component_source_http_port or balance_host["domain_data"]["source_http_port"]
    local balance_type =  balance_host["domain_data"]["balance_type"]
	local domain = balance_host["domain_data"]["domain"]
    if #ip_lists == 1 then
	    local ok,err = balancer.set_current_peer(ip_lists[1],port)
	    if not ok then
            ngx.log(ngx.ERR,"failed to set the current peer: ",err)
	    end
	    return
	end

	if balance_type == "round_robin" then
        local cache = point_cache.get_cache()
        local point = cache:get(domain)
        if  not point then
            cache:set(domain,1)
            point = 1
        end
        if #ip_lists == point then
          cache:set(domain,1)
        else
          cache:set(domain,point+1)
        end
        local _host = ip_lists[point]
        local state_name = balancer.get_last_failure()
	    if state_name == "failed" or state_name == "next" then
	        if #ip_lists == point then
	            _host =  ip_lists[1]
	        else
	            _host =  ip_lists[point+1]
	        end
        else
        	local set_more_tries_ok, set_more_tries_err = balancer.set_more_tries(1)
            if not set_more_tries_ok then
                ngx.log(ngx.ERR, "failed to set more tries: ", set_more_tries_err)
            end
	    end

        local ok,err = balancer.set_current_peer(_host,port)
	    if not ok then
            ngx.log(ngx.ERR,"failed to set the current peer: ",err)
	    end

    else
        local ip = ngx.var.remote_addr
        local first_byte = string.byte(ip, 1)
        local last_byte = string.byte(ip, -1)
        local ip_count = (first_byte + last_byte) % #ip_lists + 1
	    local _host = ip_lists[ip_count]
	    local state_name = balancer.get_last_failure()
	    if state_name == "failed" or state_name == "next" then
            if #ip_lists == ip_count then
	            _host =  ip_lists[1]
	        else
	            _host =  ip_lists[ip_count+1]
	        end
        else
        	local set_more_tries_ok, set_more_tries_err = balancer.set_more_tries(1)
            if not set_more_tries_ok then
                ngx.log(ngx.ERR, "failed to set more tries: ", set_more_tries_err)
            end
	    end
	    local ok,err = balancer.set_current_peer(_host,port)
	    if not ok then
            ngx.log(ngx.ERR,"failed to set the current peer: ",err)
	    end
    end
else
	ngx.exit(503)
end


