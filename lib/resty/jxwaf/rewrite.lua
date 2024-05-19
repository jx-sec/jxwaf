local waf = require "resty.jxwaf.waf"
local host = ngx.var.host
local server_port = ngx.var.server_port
local string_find = string.find
local string_sub = string.sub
local waf_domain_data = waf.get_waf_domain_data()
local req_host = nil
local dot_pos = string_find(host,".",1,true)
local wildcard_host = nil 


local proxy_pass_https = nil 

if waf_domain_data[host] then
    req_host = waf_domain_data[host]
    proxy_pass_https = req_host['proxy_pass_https']
  else
    local dot_pos = string_find(host,".",1,true)
    if dot_pos then
      wildcard_host = "*"..string_sub(host,dot_pos)
    end
    if wildcard_host and waf_domain_data[wildcard_host] then
      req_host = waf_domain_data[wildcard_host]
      proxy_pass_https = waf_domain_data[host]['proxy_pass_https']
    end
end
 
if server_port ~= "80" and server_port ~= "443" then
    local custom_host = host..":"..server_port
    if waf_domain_data[custom_host] then
      req_host = waf_domain_data[custom_host]
      proxy_pass_https = req_host['proxy_pass_https']
    else
      local dot_pos = string_find(host,".",1,true)
      if dot_pos then
          wildcard_host = "*"..string_sub(host,dot_pos)
      end
      if wildcard_host then
        local custom_wildcard_host = wildcard_host..":"..server_port
        if waf_domain_data[custom_wildcard_host] then
          req_host = waf_domain_data[custom_wildcard_host]
          proxy_pass_https = req_host['proxy_pass_https']
        end
      end
    end
end

if proxy_pass_https == "true" or (proxy_pass_https == "follow" and ngx.var.scheme == "https") then
  ngx.var.proxy_pass_https_flag = "true"
end

ngx.ctx.req_host = req_host