local waf = require "resty.jxwaf.waf"
local table_concat = table.concat
local uuid = require "resty.jxwaf.uuid"
local config_info = waf.get_config_info()
local update_waf_rule = waf.get_update_waf_rule()
local host = ngx.var.host
local req_host = update_waf_rule[host] or ngx.ctx.wildcard_host


if req_host and req_host['protection_set']['owasp_protection'] == "true" and req_host['owasp_check_set']['file_traversal'] == "true" then
  local check_time = req_host['owasp_check_set']['check_time']
  local check_count = req_host['owasp_check_set']['check_count']
  local check_ratio = req_host['owasp_check_set']['check_ratio']
  local black_time = req_host['owasp_check_set']['black_time']
  
end
