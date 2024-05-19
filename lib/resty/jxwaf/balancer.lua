local balancer = require "ngx.balancer"
local waf = require "resty.jxwaf.waf"
local request = require "resty.jxwaf.request"
local balance_host =  ngx.ctx.req_host
local string_sub = string.sub
local table_insert = table.insert
local table_concat = table.concat
local table_remove = table.remove
local point_cache = require "resty.jxwaf.point_cache"
local scheme = ngx.var.scheme
local host = ngx.var.host

if balance_host and balance_host[scheme] == "true" then
	local ip_lists = ngx.ctx.component_source_ip or balance_host["source_ip"]
	local port = ngx.ctx.component_source_http_port or balance_host["source_http_port"]
	local balance_type =  balance_host["balance_type"]
	local domain = balance_host["domain"]
	if #ip_lists == 1 then
	    local ok,err = balancer.set_current_peer(ip_lists[1],port)
	    if not ok then
            ngx.log(ngx.ERR,"failed to set the current peer: ",err)
	    end
	    return
	end
  

    -- round_robin
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
    -- ip_hash
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


