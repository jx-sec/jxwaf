local waf = require "resty.jxwaf.waf"

local access_init_result,access_init_error = pcall(waf.access_init)
if not access_init_result then
  local waf_log = {}
  waf_log['log_type'] = "error"
  waf_log['protection_type'] = "access_init"
  waf_log['protection_info'] = access_init_error
  ngx.ctx.waf_log = waf_log
  ngx.log(ngx.ERR,access_init_error)
end

local ip_config_result,ip_config_error = pcall(waf.ip_config_check)
if not ip_config_result then
  local waf_log = {}
  waf_log['log_type'] = "error"
  waf_log['protection_type'] = "ip_config_check"
  waf_log['protection_info'] = ip_config_error
  ngx.ctx.waf_log = waf_log
  ngx.log(ngx.ERR,ip_config_error)
end

local cc_black_ip_result,cc_black_ip_error = pcall(waf.cc_black_ip_check)
if not cc_black_ip_result then
  local waf_log = {}
  waf_log['log_type'] = "error"
  waf_log['protection_type'] = "cc_black_ip_check"
  waf_log['protection_info'] = cc_black_ip_error
  ngx.ctx.waf_log = waf_log
  ngx.log(ngx.ERR,cc_black_ip_error)
end

local bot_auth_result,bot_auth_error = pcall(waf.bot_auth_check)
if not bot_auth_result then
  local waf_log = {}
  waf_log['log_type'] = "error"
  waf_log['protection_type'] = "bot_auth_check"
  waf_log['protection_info'] = bot_auth_error
  ngx.ctx.waf_log = waf_log
  ngx.log(ngx.ERR,bot_auth_error)
end

local limitreq_result,limitreq_error =  pcall(waf.limitreq_check)
if not limitreq_result then
  local waf_log = {}
  waf_log['log_type'] = "error"
  waf_log['protection_type'] = "limitreq_check"
  waf_log['protection_info'] = limitreq_error
  ngx.ctx.waf_log = waf_log
  ngx.log(ngx.ERR,limitreq_error)
end

local owasp_black_ip_result,owasp_black_ip_error  =  pcall(waf.owasp_black_ip_check)
if not owasp_black_ip_result then
  local waf_log = {}
  waf_log['log_type'] = "error"
  waf_log['protection_type'] = "owasp_black_ip_check"
  waf_log['protection_info'] = owasp_black_ip_error
  ngx.ctx.waf_log = waf_log
  ngx.log(ngx.ERR,owasp_black_ip_error)
end

local file_upload_result,file_upload_error = pcall(waf.file_upload_check)
if not file_upload_result then
  local waf_log = {}
  waf_log['log_type'] = "error"
  waf_log['protection_type'] = "file_upload_check"
  waf_log['protection_info'] = file_upload_error
  ngx.ctx.waf_log = waf_log
  ngx.log(ngx.ERR,file_upload_error)
end

local custom_rule_result,custom_rule_error = pcall(waf.custom_rule_check)
if not custom_rule_result then
  local waf_log = {}
  waf_log['log_type'] = "error"
  waf_log['protection_type'] = "custom_rule_check"
  waf_log['protection_info'] = custom_rule_error
  ngx.ctx.waf_log = waf_log
  ngx.log(ngx.ERR,custom_rule_error)
end

local jxcheck_protection_result,jxcheck_protection_error = pcall(waf.jxcheck_protection)
if not jxcheck_protection_result then
  local waf_log = {}
  waf_log['log_type'] = "error"
  waf_log['protection_type'] = "jxcheck_protection"
  waf_log['protection_info'] = jxcheck_protection_error
  ngx.ctx.waf_log = waf_log
  ngx.log(ngx.ERR,jxcheck_protection_error)
end

local redirect_https_result,redirect_https_error = pcall(waf.redirect_https)
if not redirect_https_result then
  local waf_log = {}
  waf_log['log_type'] = "error"
  waf_log['protection_type'] = "redirect_https"
  waf_log['protection_info'] = redirect_https_error
  ngx.ctx.waf_log = waf_log
  ngx.log(ngx.ERR,redirect_https_error)
end
