local balancer = require "ngx.balancer"
local waf = require "resty.jxwaf.waf"
local request = require "resty.jxwaf.request"
local host = ngx.var.host
local balance_host =  ngx.ctx.req_host
local scheme = ngx.var.scheme
local string_sub = string.sub
local table_insert = table.insert
local table_concat = table.concat
local table_remove = table.remove

local mimetic_defense_conf = ngx.ctx.mimetic_defense_conf

if mimetic_defense_conf then
  local proxy_host =  mimetic_defense_conf['proxy_host']
  local proxy_port =  mimetic_defense_conf['proxy_port']
  local set_more_tries_ok, set_more_tries_err = balancer.set_more_tries(1)
  if not set_more_tries_ok then
    ngx.log(ngx.ERR,"failed to set the current peer: ",set_more_tries_err)
  elseif set_more_tries_err then
    ngx.log(ngx.ALERT, "set more tries: ", set_more_tries_err)
  end
  local ok,err = balancer.set_current_peer(proxy_host,proxy_port)
  if not ok then
    ngx.log(ngx.ERR,"failed to set the current peer: ",err)
  end
  return 
end



if balance_host and balance_host['domain_data'][scheme] == "true" then
	local ip_lists = ngx.ctx.component_source_ip or balance_host["domain_data"]["source_ip"]
	local port = ngx.ctx.component_source_http_port or balance_host["domain_data"]["source_http_port"]
	if not ngx.ctx.tries then
		ngx.ctx.tries = 0	
	end
  if ngx.ctx.tries < #ip_lists then
    local set_more_tries_ok, set_more_tries_err = balancer.set_more_tries(1)
    if not set_more_tries_ok then
        ngx.log(ngx.ERR,"failed to set the current peer: ",set_more_tries_err)
    elseif set_more_tries_err then
        ngx.log(ngx.ALERT, "set more tries: ", set_more_tries_err)
    end
  end
	ngx.ctx.tries = ngx.ctx.tries + 1
	if not ngx.ctx.ip_lists then
		ngx.ctx.ip_lists = ip_lists
	end
  local first_count = {}
  table_insert(first_count,string_sub(ngx.var.remote_addr,1,1))
  table_insert(first_count,string_sub(ngx.var.remote_addr,-1))
	local ip_count = (tonumber(table_concat(first_count)) % #ngx.ctx.ip_lists) + 1
	local _host = ngx.ctx.ip_lists[ip_count]
	local state_name,state_code = balancer.get_last_failure()
	if state_name == "failed" then
		for k,v in ipairs(ngx.ctx.ip_lists) do
        		if v == _host then
                		if not (#ngx.ctx.ip_lists == 1) then
                		table_remove(ngx.ctx.ip_lists,k)
                		ip_count = (tonumber(table_concat(first_count)) % #ngx.ctx.ip_lists) + 1
                		_host = ngx.ctx.ip_lists[ip_count]
                		end
        		end
		end
	end
  
	local ok,err = balancer.set_current_peer(_host,port)
	if not ok then
    ngx.log(ngx.ERR,"failed to set the current peer: ",err)
	end
else
	ngx.exit(503)
end


