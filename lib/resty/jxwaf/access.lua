local waf = require "resty.jxwaf.waf"

local access_init_result,access_init_error = pcall(waf.access_init)
if not access_init_result then
  ngx.log(ngx.ERR,access_init_error)
end

ngx.req.read_body()

local global_component_protection_result,global_component_protection_error = pcall(waf.global_component_protection)
if not global_component_protection_result then
  ngx.log(ngx.ERR,global_component_protection_error)
end

local global_name_list_result,global_name_list_error = pcall(waf.global_name_list)
if not global_name_list_result then
  ngx.log(ngx.ERR,global_name_list_error)
end


local domain_check_result,domain_check_error = pcall(waf.domain_check)
if not domain_check_result then
  ngx.log(ngx.ERR,domain_check_error)
end

local base_component_protection_result,base_component_protection_error = pcall(waf.base_component_protection)
if not base_component_protection_result then
  ngx.log(ngx.ERR,base_component_protection_error)
end

local name_list_result,name_list_error = pcall(waf.name_list)
if not name_list_result then
  ngx.log(ngx.ERR,name_list_error)
end

local flow_white_rule_result,flow_white_rule_error = pcall(waf.flow_white_rule)
if not flow_white_rule_result then
  ngx.log(ngx.ERR,flow_white_rule_error)
end

local flow_rule_protection_result,flow_rule_protection_error = pcall(waf.flow_rule_protection)
if not flow_rule_protection_result then
  ngx.log(ngx.ERR,flow_rule_protection_error)
end

local flow_engine_protection_result,flow_engine_protection_error = pcall(waf.flow_engine_protection)
if not flow_engine_protection_result then
  ngx.log(ngx.ERR,flow_engine_protection_error)
end

local web_white_rule_result,web_white_rule_error = pcall(waf.web_white_rule)
if not web_white_rule_result then
  ngx.log(ngx.ERR,web_white_rule_error)
end

local web_rule_protection_result,web_rule_protection_error = pcall(waf.web_rule_protection)
if not web_rule_protection_result then
  ngx.log(ngx.ERR,web_rule_protection_error)
end

local web_engine_protection_result,web_engine_protection_error = pcall(waf.web_engine_protection)
if not web_engine_protection_result then
  ngx.log(ngx.ERR,web_engine_protection_error)
end

local analysis_component_protection_result,analysis_component_protection_error = pcall(waf.analysis_component_protection)
if not analysis_component_protection_result then
  ngx.log(ngx.ERR,analysis_component_protection_error)
end

local abnormal_handle_result,abnormal_handle_error = pcall(waf.abnormal_handle)
if not abnormal_handle_result then
  ngx.log(ngx.ERR,abnormal_handle_error)
end





