local waf = require "resty.jxwaf.waf"
local update_waf_rule = waf.get_update_waf_rule()
local host = ngx.var.host
local string_find = string.find
local string_sub = string.sub
local exit_code = require "resty.jxwaf.exit_code"
local req_host = nil

if update_waf_rule[host] then
  req_host = update_waf_rule[host]
else 
  local dot_pos = string_find(host,".",1,true)
  if dot_pos then
    local wildcard_host = "*"..string_sub(host,dot_pos)
    if update_waf_rule[wildcard_host] then
        req_host = update_waf_rule[wildcard_host]
        ngx.ctx.wildcard_host = req_host
    end
  end
end

if not req_host then
  return exit_code.return_no_exist()
end

if req_host['domain_set']['proxy_pass_https'] == "true" then
  ngx.var.proxy_pass_https_flag = "true"
end

ngx.ctx.req_host = req_host
