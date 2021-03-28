local waf = require "resty.jxwaf.waf"
local update_waf_rule = waf.get_update_waf_rule()
local jxwaf_website_default = waf.get_jxwaf_website_default()
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
    end
  end
end

if not req_host then
  if jxwaf_website_default['type'] and jxwaf_website_default['type'] == "true" then
    if update_waf_rule['JXWAF_WEBSITE_DEFAULT'] then
      req_host = update_waf_rule['JXWAF_WEBSITE_DEFAULT']
    else
      return exit_code.return_no_exist()
    end
  elseif jxwaf_website_default['type'] and jxwaf_website_default['type'] == "false" then
    if jxwaf_website_default['owasp_html'] and #jxwaf_website_default['owasp_html'] == 0 and jxwaf_website_default['owasp_code'] and jxwaf_website_default['owasp_code'] == "404" then
      return exit_code.return_no_exist()
    elseif jxwaf_website_default['owasp_html'] and jxwaf_website_default['owasp_code'] then
      return exit_code.return_no_exist(jxwaf_website_default['owasp_code'],jxwaf_website_default['owasp_html'])
    else
      return exit_code.return_no_exist()
    end
  else
    return exit_code.return_no_exist()
  end
end

if req_host['domain_set']['proxy_pass_https'] == "true" then
  ngx.var.proxy_pass_https_flag = "true"
end

ngx.ctx.req_host = req_host
