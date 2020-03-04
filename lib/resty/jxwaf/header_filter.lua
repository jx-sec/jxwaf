local waf = require "resty.jxwaf.waf"
local table_concat = table.concat
local uuid = require "resty.jxwaf.uuid"
local config_info = waf.get_config_info()
local update_waf_rule = waf.get_update_waf_rule()
local host = ngx.var.host
local req_host = update_waf_rule[host] or ngx.ctx.wildcard_host
local request = require "resty.jxwaf.request"


if req_host and req_host['protection_set']['owasp_protection'] == "true" and req_host['owasp_check_set']['file_traversal_check'] == "true" then
  local check_time = tonumber(req_host['owasp_check_set']['file_traversal_check_time'])
  local check_count = tonumber(req_host['owasp_check_set']['file_traversal_check_count'])
  local check_ratio = tonumber(req_host['owasp_check_set']['file_traversal_check_ratio'])
  local black_time = tonumber(req_host['owasp_check_set']['file_traversal_black_time'])
  local repeat_record = req_host['owasp_check_set']['file_traversal_repeat_record']
  local ip_addr = request.request['REMOTE_ADDR']()
  local status = ngx.status
  local limit_bot = ngx.shared.limit_bot
  local check_file_traversal = {}
  check_file_traversal[1] = "check_file_traversal"
  check_file_traversal[2] =  ip_addr
  local key_check_file_traversal = table_concat(check_file_traversal)
  local check_file_traversal_count = limit_bot:incr(key_check_file_traversal, 1, 0, check_time)
  if status == 404 then
    if repeat_record then
      local uri = request.request['HTTP_URI']()
      local ip_uri = {}
      ip_uri[1] = uri
      ip_uri[2] = ip_addr
      local key_check_ip_uri = table_concat(check_not_find)
      local ip_uri_is_exist = limit_bot:get(key_check_ip_uri)
      if not ip_uri_is_exist then 
        local result = limit_bot:set(key_check_ip_uri,true,check_time)
        local check_not_find = {}
        check_not_find[1] = "check_not_find"
        check_not_find[2] =  ip_addr
        local key_check_not_find = table_concat(check_not_find)
        local check_not_find_count = limit_bot:incr(key_check_not_find, 1, 0, check_time) 
      end
    else
        local check_not_find = {}
        check_not_find[1] = "check_not_find"
        check_not_find[2] =  ip_addr
        local key_check_not_find = table_concat(check_not_find)
        local check_not_find_count = limit_bot:incr(key_check_not_find, 1, 0, check_time) 
    end
  end
  if check_file_traversal_count > check_count then
      local check_not_find = {}
      check_not_find[1] = "check_not_find"
      check_not_find[2] =  ip_addr
      local key_check_not_find = table_concat(check_not_find)
      local check_not_find_count = limit_bot:get(key_check_not_find) 
      if check_not_find_count and ((check_not_find_count/check_file_traversal_count) > check_ratio) then
        local attack_ip_check = ngx.shared.black_attack_ip
        attack_ip_check:set(ip_addr,true,black_time)
      end
  end
end
