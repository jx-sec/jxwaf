local waf = require "resty.jxwaf.waf"
local host = ngx.var.host
local string_find = string.find
local string_sub = string.sub
local waf_domain_data = waf.get_waf_domain_data()
local waf_group_domain_data = waf.get_waf_group_domain_data()
local waf_group_id_data = waf.get_waf_group_id_data()

local req_host = nil
local dot_pos = string_find(host,".",1,true)
local wildcard_host = "*"..string_sub(host,dot_pos)
local proxy_pass_https = nil 

if waf_domain_data[host] then
  req_host = waf_domain_data[host]
  proxy_pass_https = waf_domain_data[host]['domain_data']['proxy_pass_https']
else
  if waf_domain_data[wildcard_host] then
    req_host = waf_domain_data[wildcard_host]
    proxy_pass_https = waf_domain_data[wildcard_host]['domain_data']['proxy_pass_https']
  end
end  

if not req_host then
  if waf_group_domain_data[host] then
    local domain_data = waf_group_domain_data[host]
    local group_id =  waf_group_domain_data[host]['group_id']
    local group_id_data = waf_group_id_data[group_id]
    group_id_data['domain_data'] = domain_data
    req_host = group_id_data
    proxy_pass_https = waf_group_domain_data[host]['proxy_pass_https']
  else
    if waf_group_domain_data[wildcard_host] then
      local domain_data = waf_group_domain_data[wildcard_host]
      local group_id =  waf_group_domain_data[wildcard_host]['group_id']
      local group_id_data = waf_group_id_data[group_id]
      group_id_data['domain_data'] = domain_data
      req_host = group_id_data
      proxy_pass_https = waf_group_domain_data[wildcard_host]['proxy_pass_https']
    end
  end
end 

if proxy_pass_https == "true" then
  ngx.var.proxy_pass_https_flag = "true"
end

ngx.ctx.req_host = req_host

