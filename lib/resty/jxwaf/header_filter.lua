local waf = require "resty.jxwaf.waf"
local table_concat = table.concat
local uuid = require "resty.jxwaf.uuid"
local config_info = waf.get_config_info()
local update_waf_rule = waf.get_update_waf_rule()
local host = ngx.var.host
local req_host = update_waf_rule[host] or ngx.ctx.wildcard_host
local request = require "resty.jxwaf.request"


if req_host and req_host['protection_set']['owasp_protection'] == "true" and req_host['owasp_check_set']['file_traversal'] == "true" then
  local check_time = req_host['owasp_check_set']['check_time']
  local check_count = req_host['owasp_check_set']['check_count']
  local check_ratio = req_host['owasp_check_set']['check_ratio']
  local black_time = req_host['owasp_check_set']['black_time']
  local ip_addr = request.request['REMOTE_ADDR']()
  local status = ngx.status
  local limit_bot = ngx.shared.limit_bot
  local check_file_traversal = {}
  check_black_ip[1] = "check_file_traversal"
  check_black_ip[2] =  ip_addr
  local key_check_file_traversal = table_concat(check_file_traversal)
  local check_file_traversal_count = limit_bot:incr(key_check_file_traversal, 1, 0, check_time) 
  local check_not_find = {}
  check_not_find[1] = "check_not_find"
  check_not_find[2] =  ip_addr
  local key_check_not_find = table_concat(check_not_find)
  if status == 404 then
    
  end
  local not_find_count = 
  if check_file_traversal_count and check_file_traversal_count > check_count then
    if 
    limit_bot:set(ip_addr,true,black_time)
  end
  
end
