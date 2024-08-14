local cjson = require "cjson.safe"
local request = require "resty.jxwaf.request"
local preprocess = require "resty.jxwaf.preprocess"
local operator = require "resty.jxwaf.operator"
local resty_random = require "resty.random"
local pairs = pairs
local ipairs = ipairs
local table_insert = table.insert
local table_sort = table.sort
local table_concat = table.concat
local http = require "resty.jxwaf.http"
local upload = require "resty.upload"
local unify_action = require "resty.jxwaf.unify_action"
local uuid = require "resty.jxwaf.uuid"
local ngx_md5 = ngx.md5
local string_find = string.find
local string_sub = string.sub
local loadstring = loadstring
local tonumber = tonumber
local type = type
local string_lower = string.lower
local process = require "ngx.process"
local ngx_decode_base64 = ngx.decode_base64
local geo = require 'resty.jxwaf.maxminddb'
local iputils = require 'resty.jxwaf.iputils'



local _M = {}
_M.version = "jxwaf_base_v4"
local _config_geo_path = "/opt/jxwaf/nginx/conf/jxwaf/GeoLite2.mmdb"


local _config_info = {}
local _conf_md5 = ""
local _name_list_item_conf_md5 = ""
local _fail_update_period = "60"
local _auto_update_period = "5"
local _waf_node_monitor_period = "60"
local _waf_domain_data = {}
local _waf_protection_data = {}
local _waf_scan_attack_protection_data = {}
local _waf_web_page_tamper_proof_data = {}
local _waf_web_engine_protection_data = {}
local _waf_web_rule_protection_data = {}
local _waf_web_white_rule_data = {}
local _waf_flow_engine_protection_data = {}
local _waf_flow_rule_protection_data = {}
local _waf_flow_white_rule_data = {}
local _waf_flow_ip_region_block_data = {}
local _waf_flow_black_ip_data = {}
local _waf_name_list_data = {}
local _waf_base_component_data = {}
local _waf_base_component_code = {}
local _waf_analysis_component_data = {}
local _waf_analysis_component_code = {}
local _waf_ssl_manage_data = {}
local _sys_conf_data = {}
local _jxcore
local _jxwaf_engine

local _waf_name_list_item_data = {}

function _M.get_config_info()
	return _config_info
end

function _M.get_waf_domain_data()
	return _waf_domain_data
end

function _M.get_waf_ssl_manage_data()
	return _waf_ssl_manage_data
end

function _M.get_sys_conf_data()
	return _sys_conf_data
end

local function _update_at(auto_update_period,global_update_rule)
  local global_ok, global_err = ngx.timer.at(tonumber(auto_update_period),global_update_rule)
  if not global_ok then
    if global_err ~= "process exiting" then
      ngx.log(ngx.ERR, "failed to create the cycle timer: ", global_err)
    end
  end
end

local function _momitor_update()
    local _update_website  =  _config_info.waf_monitor_website
    local httpc = http.new()
    local post_data = {}
    post_data['waf_auth'] = _config_info.waf_auth 
    post_data['waf_node_uuid'] = _config_info.waf_node_uuid  
    post_data['waf_node_hostname'] = _config_info.waf_node_hostname   
    local res, err = httpc:request_uri( _update_website , {
        method = "POST",
        body = cjson.encode(post_data),
        headers = {
        ["Content-Type"] = "application/x-www-form-urlencoded",
        }
    })
    if not res then
      ngx.log(ngx.ERR,"failed to request: ", err)
      return _update_at(tonumber(_auto_update_period),_momitor_update)
    end
		local res_body = cjson.decode(res.body)
		if not res_body then
      ngx.log(ngx.ERR,"init fail,failed to decode resp body " )
      return _update_at(tonumber(_auto_update_period),_momitor_update)
		end
    if  res_body['result'] == false then
      ngx.log(ngx.ERR,"init fail,failed to request, ",res_body['message'])
      return _update_at(tonumber(_auto_update_period),_momitor_update)
    end
    local global_ok, global_err = ngx.timer.at(tonumber(_waf_node_monitor_period),_momitor_update)
    if not global_ok then
      if global_err ~= "process exiting" then
        ngx.log(ngx.ERR, "failed to create the cycle timer: ", global_err)
      end
    end
end


local function _global_update_rule()
    local _update_website  =  _config_info.waf_update_website
    local httpc = http.new()
    httpc:set_timeouts(5000, 5000, 30000)
    local api_key = _config_info.waf_auth or ""
    local post_data = {}
    post_data['waf_auth'] = _config_info.waf_auth
    post_data['conf_md5'] = _conf_md5 
    post_data['waf_node_uuid'] = _config_info.waf_node_uuid
    local res, err = httpc:request_uri( _update_website , {
        method = "POST",
        body = cjson.encode(post_data)
    })
  
    if not res then
      ngx.log(ngx.ERR,"failed to request: ", err)
      ngx.log(ngx.ERR,"60 seconds and try again ")
      return _update_at(tonumber(_fail_update_period),_global_update_rule)
    end
    
		local res_body = cjson.decode(res.body)
		if not res_body then
      ngx.log(ngx.ERR,"init fail,failed to decode resp body " )
      ngx.log(ngx.ERR,"60 seconds and try again ")
      return _update_at(tonumber(_fail_update_period),_global_update_rule)
		end
    
    if  res_body['result'] ~= true  then
      ngx.log(ngx.ERR,"init fail,failed to request, ",res_body['message'])
      ngx.log(ngx.ERR,"60 seconds and try again ")
      return _update_at(tonumber(_fail_update_period),_global_update_rule)
    end
    
    if not res_body['configure_without_change'] then
      
      local waf_conf_data = ngx.shared.waf_conf_data
      
      local waf_domain_data = res_body['waf_domain_data'] 
      if waf_domain_data == nil then
        ngx.log(ngx.ERR,"waf_domain_data update fail")
        ngx.log(ngx.ERR,"60 seconds and try again ")
        return _update_at(tonumber(_fail_update_period),_global_update_rule)
      end
      
      local waf_protection_data = res_body['waf_protection_data'] 
      if waf_protection_data == nil   then
        ngx.log(ngx.ERR,"waf_protection_data update fail")
        ngx.log(ngx.ERR,"60 seconds and try again ")
        return _update_at(tonumber(_fail_update_period),_global_update_rule)
      end

      local waf_scan_attack_protection_data = res_body['waf_scan_attack_protection_data']
      if waf_scan_attack_protection_data == nil then
        ngx.log(ngx.ERR,"waf_scan_attack_protection_data update fail")
        ngx.log(ngx.ERR,"60 seconds and try again ")
        return _update_at(tonumber(_fail_update_period),_global_update_rule)
      end

      local waf_web_page_tamper_proof_data_data = res_body['waf_web_page_tamper_proof_data']
      if waf_web_page_tamper_proof_data_data == nil then
        ngx.log(ngx.ERR,"waf_web_page_tamper_proof_data_data update fail")
        ngx.log(ngx.ERR,"60 seconds and try again ")
        return _update_at(tonumber(_fail_update_period),_global_update_rule)
      end
      
      local waf_web_engine_protection_data = res_body['waf_web_engine_protection_data'] 
      if waf_web_engine_protection_data == nil then
        ngx.log(ngx.ERR,"waf_web_engine_protection_data update fail")
        ngx.log(ngx.ERR,"60 seconds and try again ")
        return _update_at(tonumber(_fail_update_period),_global_update_rule)
      end
      
      
      local waf_web_rule_protection_data = res_body['waf_web_rule_protection_data'] 
      if waf_web_rule_protection_data == nil then
        ngx.log(ngx.ERR,"sys_web_rule_protection_data update fail")
        ngx.log(ngx.ERR,"60 seconds and try again ")
        return _update_at(tonumber(_fail_update_period),_global_update_rule)
      end
      
      local waf_web_white_rule_data = res_body['waf_web_white_rule_data'] 
      if waf_web_white_rule_data == nil then
        ngx.log(ngx.ERR,"waf_web_white_rule_data update fail")
        ngx.log(ngx.ERR,"60 seconds and try again ")
        return _update_at(tonumber(_fail_update_period),_global_update_rule)
      end
      
      local waf_flow_engine_protection_data = res_body['waf_flow_engine_protection_data'] 
      if waf_flow_engine_protection_data == nil then
        ngx.log(ngx.ERR,"waf_flow_engine_protection_data update fail")
        ngx.log(ngx.ERR,"60 seconds and try again ")
        return _update_at(tonumber(_fail_update_period),_global_update_rule)
      end
      
      local waf_flow_rule_protection_data = res_body['waf_flow_rule_protection_data'] 
      if waf_flow_rule_protection_data == nil then
        ngx.log(ngx.ERR,"waf_flow_rule_protection_data update fail")
        ngx.log(ngx.ERR,"60 seconds and try again ")
        return _update_at(tonumber(_fail_update_period),_global_update_rule)
      end
      
      local waf_flow_white_rule_data = res_body['waf_flow_white_rule_data'] 
      if waf_flow_white_rule_data == nil then
        ngx.log(ngx.ERR,"waf_flow_white_rule_data update fail")
        ngx.log(ngx.ERR,"60 seconds and try again ")
        return _update_at(tonumber(_fail_update_period),_global_update_rule)
      end
      
      local waf_flow_ip_region_block_data = res_body['waf_flow_ip_region_block_data'] 
      if waf_flow_ip_region_block_data == nil then
        ngx.log(ngx.ERR,"waf_flow_ip_region_block_data update fail")
        ngx.log(ngx.ERR,"60 seconds and try again ")
        return _update_at(tonumber(_fail_update_period),_global_update_rule)
      end

      local waf_flow_black_ip_data = res_body['waf_flow_black_ip_data']
      if waf_flow_black_ip_data == nil then
        ngx.log(ngx.ERR,"waf_flow_black_ip_data update fail")
        ngx.log(ngx.ERR,"60 seconds and try again ")
        return _update_at(tonumber(_fail_update_period),_global_update_rule)
      end

      local waf_name_list_data = res_body['waf_name_list_data'] 
      if waf_name_list_data == nil then
        ngx.log(ngx.ERR,"waf_name_list_data update fail")
        ngx.log(ngx.ERR,"60 seconds and try again ")
        return _update_at(tonumber(_fail_update_period),_global_update_rule)
      end
      
      local waf_base_component_data = res_body['waf_base_component_data'] 
      if waf_base_component_data == nil then
        ngx.log(ngx.ERR,"waf_base_component_data update fail")
        ngx.log(ngx.ERR,"60 seconds and try again ")
        return _update_at(tonumber(_fail_update_period),_global_update_rule)
      end
      
      for _,v in ipairs(waf_base_component_data) do 
        local name = v['name']
        local code = v['code']
        if ngx.decode_base64(code) and loadstring(ngx.decode_base64(code)) then
          local load_component_data = loadstring(ngx.decode_base64(code))()
          if load_component_data then
            _waf_base_component_code[name] = load_component_data
          else
            ngx.log(ngx.ERR,"init fail,can not decode base_component_data,name is "..name)
          end 
        else
          ngx.log(ngx.ERR,"init fail,can not decode base_component_data,name is "..name)
        end        
      end
      
      local waf_analysis_component_data = res_body['waf_analysis_component_data'] 
      if waf_analysis_component_data == nil then
        ngx.log(ngx.ERR,"waf_analysis_component_data update fail")
        ngx.log(ngx.ERR,"60 seconds and try again ")
        return _update_at(tonumber(_fail_update_period),_global_update_rule)
      end
      
      for _,v in ipairs(waf_analysis_component_data) do 
        local name = v['name']
        local code = v['code']
        if ngx.decode_base64(code) and loadstring(ngx.decode_base64(code)) then
          local load_component_data = loadstring(ngx.decode_base64(code))()
          if load_component_data then
            _waf_analysis_component_code[name] = load_component_data
          else
            ngx.log(ngx.ERR,"init fail,can not decode analysis_component_data,name is "..name)
          end 
        else
          ngx.log(ngx.ERR,"init fail,can not decode analysis_component_data,name is "..name)
        end        
      end
      
      local waf_ssl_manage_data = res_body['waf_ssl_manage_data'] 
      if waf_ssl_manage_data == nil then
        ngx.log(ngx.ERR,"waf_ssl_manage_data update fail")
        ngx.log(ngx.ERR,"60 seconds and try again ")
        return _update_at(tonumber(_fail_update_period),_global_update_rule)
      end
      
      local sys_conf_data = res_body['sys_conf_data'] 
      if sys_conf_data == nil then
        ngx.log(ngx.ERR,"sys_conf_data update fail")
        ngx.log(ngx.ERR,"60 seconds and try again ")
        return _update_at(tonumber(_fail_update_period),_global_update_rule)
      end

      local md5_succ, md5_err = waf_conf_data:set("conf_md5",res_body['conf_md5'])
      if md5_err then
        ngx.log(ngx.ERR,"init fail,can not set waf_conf_data md5")
        return _update_at(tonumber(_auto_update_period),_global_update_rule)
      end
      
      local res_body_succ, res_body_err = waf_conf_data:set("res_body",res.body)
      if res_body_err then
        ngx.log(ngx.ERR,"init fail,can not set waf_conf_data res_body")
        return _update_at(tonumber(_auto_update_period),_global_update_rule)
      end
      
      _conf_md5 = res_body['conf_md5']
      ngx.log(ngx.ALERT,"update config info success,global config info md5 is ".._conf_md5..",")
    end
    
    _auto_update_period = res_body['auto_update_period'] or _auto_update_period
    local global_ok, global_err = ngx.timer.at(tonumber(_auto_update_period),_global_update_rule)
    if not global_ok then
      if global_err ~= "process exiting" then
        ngx.log(ngx.ERR, "failed to create the cycle timer: ", global_err)
      end
    end
end

local function _worker_update_rule()
  local waf_conf_data = ngx.shared.waf_conf_data
  local conf_md5 = waf_conf_data:get("conf_md5")
  if conf_md5 and conf_md5 ~= _conf_md5 then
    local tmp_res_body = waf_conf_data:get("res_body")
    if not tmp_res_body then
      ngx.log(ngx.ERR,"worker error,init fail,failed to get resp body " )
    end
    local res_body = cjson.decode(tmp_res_body)
		if not res_body then
      ngx.log(ngx.ERR,"worker error,init fail,failed to decode resp body " )
		end

    local waf_domain_data = res_body['waf_domain_data']
    if waf_domain_data == nil  then
      ngx.log(ngx.ERR,"init fail,can not decode waf_domain_data")
    else
      _waf_domain_data = waf_domain_data
    end

    local waf_protection_data = res_body['waf_protection_data']
    if waf_protection_data == nil  then
      ngx.log(ngx.ERR,"init fail,can not decode waf_protection_data")
    else
      _waf_protection_data = waf_protection_data
    end

    local waf_scan_attack_protection_data = res_body['waf_scan_attack_protection_data']
    if waf_scan_attack_protection_data == nil  then
      ngx.log(ngx.ERR,"init fail,can not decode waf_scan_attack_protection_data")
    else
      _waf_scan_attack_protection_data = waf_scan_attack_protection_data
    end

    local waf_web_page_tamper_proof_data = res_body['waf_web_page_tamper_proof_data']
    if waf_web_page_tamper_proof_data == nil  then
      ngx.log(ngx.ERR,"init fail,can not decode waf_web_page_tamper_proof_data")
    else
      _waf_web_page_tamper_proof_data = waf_web_page_tamper_proof_data
    end
    
    local waf_web_engine_protection_data = res_body['waf_web_engine_protection_data']
    if waf_web_engine_protection_data == nil  then
      ngx.log(ngx.ERR,"init fail,can not decode waf_web_engine_protection_data")
    else
      _waf_web_engine_protection_data = waf_web_engine_protection_data
    end
    
    local waf_web_rule_protection_data = res_body['waf_web_rule_protection_data']
    if waf_web_rule_protection_data == nil  then
      ngx.log(ngx.ERR,"init fail,can not decode waf_web_rule_protection_data")
    else
      _waf_web_rule_protection_data = waf_web_rule_protection_data
    end
    
    local waf_web_white_rule_data = res_body['waf_web_white_rule_data']
    if waf_web_white_rule_data == nil  then
      ngx.log(ngx.ERR,"init fail,can not decode waf_web_white_rule_data")
    else
      _waf_web_white_rule_data = waf_web_white_rule_data
    end
    
    local waf_flow_engine_protection_data = res_body['waf_flow_engine_protection_data']
    if waf_flow_engine_protection_data == nil  then
      ngx.log(ngx.ERR,"init fail,can not decode waf_flow_engine_protection_data")
    else
      _waf_flow_engine_protection_data = waf_flow_engine_protection_data
    end
    
    local waf_flow_rule_protection_data = res_body['waf_flow_rule_protection_data']
    if waf_flow_rule_protection_data == nil  then
      ngx.log(ngx.ERR,"init fail,can not decode waf_flow_rule_protection_data")
    else
      _waf_flow_rule_protection_data = waf_flow_rule_protection_data
    end
    
    local waf_flow_white_rule_data = res_body['waf_flow_white_rule_data']
    if waf_flow_white_rule_data == nil  then
      ngx.log(ngx.ERR,"init fail,can not decode waf_flow_white_rule_data")
    else
      _waf_flow_white_rule_data = waf_flow_white_rule_data
    end
    
    local waf_flow_ip_region_block_data = res_body['waf_flow_ip_region_block_data']
    if waf_flow_ip_region_block_data == nil  then
      ngx.log(ngx.ERR,"init fail,can not decode waf_flow_ip_region_block_data")
    else
      _waf_flow_ip_region_block_data = waf_flow_ip_region_block_data
    end

    local waf_flow_black_ip_data = res_body['waf_flow_black_ip_data']
    if waf_flow_black_ip_data == nil  then
      ngx.log(ngx.ERR,"init fail,can not decode waf_flow_black_ip_data")
    else
      _waf_flow_black_ip_data = waf_flow_black_ip_data
    end

    local waf_name_list_data = res_body['waf_name_list_data']
    if waf_name_list_data == nil  then
      ngx.log(ngx.ERR,"init fail,can not decode waf_name_list_data")
    else
      _waf_name_list_data = waf_name_list_data
    end
    
    local waf_base_component_data = res_body['waf_base_component_data']
    if waf_base_component_data == nil  then
      ngx.log(ngx.ERR,"init fail,can not decode waf_base_component_data")
    else
      _waf_base_component_data = waf_base_component_data
      for _,v in ipairs(waf_base_component_data) do 
        local name = v['name']
        local code = v['code']
        if ngx.decode_base64(code) and loadstring(ngx.decode_base64(code)) then
          local load_component_data = loadstring(ngx.decode_base64(code))()
          if load_component_data then
            _waf_base_component_code[name] = load_component_data
          else
            ngx.log(ngx.ERR,"init fail,can not decode base_component_data,name is "..name)
          end 
        else
          ngx.log(ngx.ERR,"init fail,can not decode base_component_data,name is "..name)
        end        
      end
    end
    
    local waf_analysis_component_data = res_body['waf_analysis_component_data']
    if waf_analysis_component_data == nil  then
      ngx.log(ngx.ERR,"init fail,can not decode waf_analysis_component_data")
    else
      _waf_analysis_component_data = waf_analysis_component_data
      for _,v in ipairs(waf_analysis_component_data) do 
        local name = v['name']
        local code = v['code']
        if ngx.decode_base64(code) and loadstring(ngx.decode_base64(code)) then
          local load_component_data = loadstring(ngx.decode_base64(code))()
          if load_component_data then
            _waf_analysis_component_code[name] = load_component_data
          else
            ngx.log(ngx.ERR,"init fail,can not decode analysis_component_data,name is "..name)
          end 
        else
          ngx.log(ngx.ERR,"init fail,can not decode analysis_component_data,name is "..name)
        end        
      end
    end
    
    local waf_ssl_manage_data = res_body['waf_ssl_manage_data']    
    if waf_ssl_manage_data == nil  then
      ngx.log(ngx.ERR,"init fail,can not decode waf_ssl_manage_data")
    else
      _waf_ssl_manage_data = waf_ssl_manage_data
    end
    
    local sys_conf_data = res_body['sys_conf_data'] 
    if sys_conf_data == nil then
      ngx.log(ngx.ERR,"init fail,can not decode sys_conf_data")
    else 
      _sys_conf_data = sys_conf_data
    end

    if _jxcore then
      local pre_jxwaf_engine = loadstring(ngx.decode_base64(_jxcore))()
      local init_jxwaf_engine = pre_jxwaf_engine.init()
      if init_jxwaf_engine then
        _jxwaf_engine = init_jxwaf_engine
      end
    else
      ngx.log(ngx.ERR,"jxwaf_engine init fail")
    end

    _conf_md5 = res_body['conf_md5']
    ngx.log(ngx.ALERT,"worker config info md5 is ".._conf_md5..",update config info success")
  end
  
end


local function _global_name_list_item_update()
  local _name_list_item_update_website  =  _config_info.waf_name_list_item_update_website
  local httpc = http.new()
  httpc:set_timeouts(5000, 5000, 30000)
  local waf_auth = _config_info.waf_auth or ""
  local post_data = {}
  post_data['waf_auth'] = waf_auth
  post_data['conf_md5'] = _name_list_item_conf_md5
  local res, err = httpc:request_uri( _name_list_item_update_website , {
    method = "POST",
    body = cjson.encode(post_data)
  })
  if not res then
    ngx.log(ngx.ERR,"failed to request: ", err)
    ngx.log(ngx.ERR,"60 seconds and try again ")
    return _update_at(tonumber(_fail_update_period),_global_name_list_item_update)
  end
  
  local res_body = cjson.decode(res.body)
  if not res_body then
    ngx.log(ngx.ERR,"init fail,failed to decode resp body " )
    ngx.log(ngx.ERR,"60 seconds and try again ")
    return _update_at(tonumber(_fail_update_period),_global_name_list_item_update)
  end
    
  if  res_body['result'] ~= true  then
    ngx.log(ngx.ERR,"init fail,failed to request, ",res_body['message'])
    ngx.log(ngx.ERR,"60 seconds and try again ")
    return _update_at(tonumber(_fail_update_period),_global_name_list_item_update)
  end
  
  if not res_body['configure_without_change'] then
      local waf_conf_data = ngx.shared.waf_conf_data
      local waf_name_list_item_data = res_body['waf_name_list_item_data'] 
      if waf_name_list_item_data == nil then
        ngx.log(ngx.ERR,"waf_name_list_item_data update fail")
        ngx.log(ngx.ERR,"60 seconds and try again ")
        return _update_at(tonumber(_fail_update_period),_global_name_list_item_update)
      end
      
      local md5_succ, md5_err = waf_conf_data:set("name_list_item_conf_md5",res_body['conf_md5'])
      if md5_err then
        ngx.log(ngx.ERR,"init fail,can not set waf_conf_data md5")
        return _update_at(tonumber(_auto_update_period),_global_name_list_item_update)
      end
      
      local res_body_succ, res_body_err = waf_conf_data:set("name_list_item_res_body",res.body)
      if res_body_err then
        ngx.log(ngx.ERR,"init fail,can not set waf_conf_data name_list_res_body")
        return _update_at(tonumber(_auto_update_period),_global_name_list_item_update)
      end
      
      _name_list_item_conf_md5 = res_body['conf_md5']
      ngx.log(ngx.ALERT,"global name_list config info md5 is ".._name_list_item_conf_md5..",update config info success")
    end
    
    _auto_update_period = res_body['auto_update_period'] or _auto_update_period
    local global_ok, global_err = ngx.timer.at(60,_global_name_list_item_update)
    if not global_ok then
      if global_err ~= "process exiting" then
        ngx.log(ngx.ERR, "failed to create the cycle timer: ", global_err)
      end
    end
end

local function _worker_name_list_item_update()
  local waf_conf_data = ngx.shared.waf_conf_data
  local name_list_item_conf_md5 = waf_conf_data:get("name_list_item_conf_md5")
  if name_list_item_conf_md5 and name_list_item_conf_md5 ~= _name_list_item_conf_md5 then
    local tmp_res_body = waf_conf_data:get("name_list_item_res_body")
    if not tmp_res_body then
      ngx.log(ngx.ERR,"worker error,init fail,failed to get resp body " )
    end
    local res_body = cjson.decode(tmp_res_body)
		if not res_body then
      ngx.log(ngx.ERR,"worker error,init fail,failed to decode resp body " )
		end

    local waf_name_list_item_data = res_body['waf_name_list_item_data']
    if waf_name_list_item_data == nil  then
      ngx.log(ngx.ERR,"init fail,can not decode waf_name_list_item_data")
    else
      _waf_name_list_item_data = waf_name_list_item_data
    end
    
    _name_list_item_conf_md5 = res_body['conf_md5']
    ngx.log(ngx.ALERT,"worker name_list config info md5 is ".._name_list_item_conf_md5..",update config info success")
  end
  
end


function _M.init_worker()
  if process.type() == "privileged agent" then
    local monitor_ok,monitor_err = ngx.timer.at(0,_momitor_update)
    if not monitor_ok then
      if monitor_err ~= "process exiting" then
        ngx.log(ngx.ERR, "failed to create the init timer: ", monitor_err)
      end
    end
    local init_ok,init_err = ngx.timer.at(0,_global_update_rule)
    if not init_ok then
      if init_err ~= "process exiting" then
        ngx.log(ngx.ERR, "failed to create the init global timer: ", init_err)
      end
    end
    local name_list_init_ok,name_list_init_err = ngx.timer.at(0,_global_name_list_item_update)
    if not name_list_init_ok then
      if name_list_init_err ~= "process exiting" then
        ngx.log(ngx.ERR, "failed to create the  name_list init global timer: ", init_err)
      end
    end
  else
    local worker_init_ok,worker_init_err = ngx.timer.at(0,_worker_update_rule)
    if not worker_init_ok then
      if worker_init_err ~= "process exiting" then
        ngx.log(ngx.ERR, "failed to create the init worker timer: ", worker_init_err)
      end
    end
    local hdl, err = ngx.timer.every(5,_worker_update_rule)
    if err then
      ngx.log(ngx.ERR, "failed to create the worker update timer: ", err)
    end
    
    local name_list_item_worker_init_ok,name_list_item_worker_init_err = ngx.timer.at(0,_worker_name_list_item_update)
    if not name_list_item_worker_init_ok then
      if name_list_item_worker_init_err ~= "process exiting" then
        ngx.log(ngx.ERR, "failed to create the init name_list worker timer: ", name_list_item_worker_init_err)
      end
    end
    local name_list_item_hdl, name_list_item_err = ngx.timer.every(5,_worker_name_list_item_update)
    if name_list_item_err then
      ngx.log(ngx.ERR, "failed to create the name_list worker update timer: ", name_list_item_err)
    end
  end
end

function _M.init(config_path,jxcore_path)
	local init_config_path = config_path 
	local read_config = assert(io.open(init_config_path,'r+'))
	local raw_config_info = read_config:read('*all')
    read_config:close()
	local config_info = cjson.decode(raw_config_info)
	if config_info == nil then
		ngx.log(ngx.ERR,"init fail,can not decode config file")
	end
  if not config_info['waf_node_uuid'] then
    local waf_node_uuid = uuid.generate_random()
    config_info['waf_node_uuid'] = waf_node_uuid
    local new_config_info = cjson.encode(config_info)
    local write_config = assert(io.open(init_config_path,'w+'))
    write_config:write(new_config_info)
    write_config:close()
  end
  _config_info = config_info
    local init_jxcore_path = jxcore_path
  	local jxcore_read = assert(io.open(init_jxcore_path,'r+'))
	local raw_jxcore = jxcore_read:read('*all')
    jxcore_read:close()
	if raw_jxcore == nil then
		ngx.log(ngx.ERR,"init fail,can not read jxcore")
	end
	_jxcore = raw_jxcore
  
  if not geo.initted() then
    geo.init(_config_geo_path)
  end
  if not geo.initted() then
    ngx.log(ngx.ERR,"init geoip fail")
  end
  
  local ok, err = process.enable_privileged_agent()
  if not ok then
    ngx.log(ngx.ERR, "enables privileged agent failed error:", err)
  end
  ngx.log(ngx.ALERT,"jxwaf init success,waf_node_uuid is ".._config_info['waf_node_uuid'])
  
  iputils.enable_lrucache()
end



local function is_valid_ip(ip)
    local parts = {ip:match("(%d+)%.(%d+)%.(%d+)%.(%d+)")}
    if #parts ~= 4 then
        return false
    end

    for _, part in ipairs(parts) do
        local num = tonumber(part)
        if num < 0 or num > 255 then
            return false
        end
    end

    if parts[1] == "10" or (parts[1] == "172" and tonumber(parts[2]) >= 16 and tonumber(parts[2]) <= 31) or (parts[1] == "192" and parts[2] == "168") then
        return false
    end

    return true
end

function _M.access_init()
  local req_host = ngx.ctx.req_host
  local request_uuid = uuid.generate_random()
  ngx.ctx.request_uuid = request_uuid
  
  if _sys_conf_data['log_response'] == "true" then
    ngx.req.clear_header('Accept-Encoding')
    ngx.ctx.log_response = true
  end

  if req_host and req_host['advanced_conf'] == 'true' and req_host['pre_proxy'] == 'true' then
      local src_ip = ngx.var.remote_addr
      local white_ip_list = req_host['white_ip_list']
      local whitelist = iputils.parse_cidrs(white_ip_list)
      if  iputils.ip_in_cidrs(src_ip, whitelist) then
        if req_host['real_ip_conf'] == 'XRI' then
             local xri_ip = ngx.req.get_headers()['X-REAL-IP']
             if xri_ip and is_valid_ip(xri_ip) then
                ngx.ctx.src_ip = xri_ip
             end
          elseif req_host['real_ip_conf'] == 'XFF' then
            local xff = ngx.req.get_headers()['X-Forwarded-For']
            local xff_ip = ngx.re.match(xff,[=[^\d{1,3}+\.\d{1,3}+\.\d{1,3}+\.\d{1,3}+]=],'oj')[0]
            if xff_ip and is_valid_ip(xff_ip) then
                ngx.ctx.src_ip = xff_ip
            end
        end
      end
  end
  
  local iso_code = ""
  local city = ""
  local latitude = ""
  local longitude = ""
  if not geo.initted() then
     geo.init(_config_geo_path)
  end
  local src_ip =  request.get_args("http_args","src_ip")
  local res,err = geo.lookup(src_ip)

  if res and res['country'] then
     iso_code = res['country']['iso_code']
  end
  
  if res and res['city'] and res['city']['names'] then
     city = res['city']['names']['en']
  end

  if res and res['location']  then
     latitude = res['location']['latitude']
     longitude = res['location']['longitude']
  end

  ngx.ctx.iso_code = iso_code
  ngx.ctx.city = city
  ngx.ctx.latitude = latitude
  ngx.ctx.longitude = longitude
  ngx.ctx.base_component_result = {}
  ngx.ctx.name_list_result = {}
  ngx.ctx.flow_rule_protection_result = {}
  ngx.ctx.flow_engine_protection_result  = {}
  ngx.ctx.web_rule_protection_result = {}
  ngx.ctx.web_engine_protection_result = {}
  ngx.ctx.analysis_comaponent_result = {}
end


function _M.base_component()
  for _,web_base_component_conf in ipairs(_waf_base_component_data) do
    local component_conf = web_base_component_conf['conf']
    local component_name = web_base_component_conf['name']
    if _waf_base_component_code[component_name] then
      local function_result,return_result = pcall(_waf_base_component_code[component_name].check,component_conf)
      if not function_result then
        ngx.log(ngx.ERR,"component_protection error name: "..component_name.." ,error_message: "..return_result)
      end
      if return_result  then
        ngx.ctx.base_component_result[component_name] = "true"
      end 
    end
  end
end


function _M.name_list()
  for _,name_list_conf in ipairs(_waf_name_list_data) do
    local name_list_name = name_list_conf['name_list_name']
    local name_list_rule = name_list_conf['name_list_rule']
    local name_list_action = name_list_conf['name_list_action']
    local action_value = name_list_conf['action_value']
    local name_list_item_data = _waf_name_list_item_data[name_list_name]
    if name_list_item_data then
      local item_value_table = {}
      local nil_exist 
      for _,rule in ipairs(name_list_rule) do
        local key = rule['key']
        local value = rule['value']
        local return_value = request.get_args(key,value)
        if type(return_value) == "string" then
          table.insert(item_value_table,return_value)
        else
          nil_exist = true
          break
        end
      end
      if not nil_exist then
        local item_value = table.concat(item_value_table)
        if name_list_item_data[item_value] then 
          local waf_log = {}
          waf_log['waf_module'] = "name_list"
          waf_log['waf_policy'] = "名单防护-"..name_list_name
          waf_log['waf_action'] = name_list_action
          waf_log['waf_extra'] = item_value
          ngx.ctx.waf_log = waf_log
          ngx.ctx.name_list_result[name_list_name] = "true"
          if name_list_action == "block"  then
            local page_conf = {}
            if _sys_conf_data['custom_deny_page'] == 'true' then
              page_conf['code'] = _sys_conf_data['waf_deny_code']
              page_conf['html'] = _sys_conf_data['waf_deny_html']
            end
            unify_action.block(page_conf)
          elseif name_list_action == "reject_response"  then
            unify_action.reject_response()
          elseif  name_list_action == "bot_check" then
            _jxwaf_engine.bot_commit_auth(_config_info['bot_check_ip_bind'])
            _jxwaf_engine.bot_check_ip(action_value,_config_info['waf_cc_js_website'],_config_info['bot_check_ip_bind'])
          elseif name_list_action == "all_bypass" then
            unify_action.allow()
          elseif name_list_action == "web_bypass" then
            ngx.ctx.web_bypass = true
          elseif name_list_action == "flow_bypass" then
            ngx.ctx.flow_bypass = true
          end
        end
      end
    end
  end
end

function _M.domain_check()
  local req_host = ngx.ctx.req_host 
  local scheme = ngx.var.scheme
  if (not req_host) or (  req_host[scheme] == "false") then
    local page_conf = {}
     page_conf['code'] = "404"
     page_conf['html'] = "domain_is_not_exist"
     return unify_action.block(page_conf)
  end
end


function _M.flow_white_rule()
  local host = ngx.var.http_host or ngx.var.host
  local protection_data = _waf_protection_data[host] or _waf_protection_data[_config_info.waf_node_uuid]
  local flow_white_rule_data = _waf_flow_white_rule_data[host] or _waf_flow_white_rule_data[_config_info.waf_node_uuid]
  if not protection_data or not flow_white_rule_data or (protection_data and protection_data['flow_white_rule'] == "false") then
    return 
  end
  for _,rule_conf in ipairs(flow_white_rule_data) do
    local rule_name = rule_conf['rule_name']
    local rule_matchs = rule_conf['rule_matchs']
    local rule_action = rule_conf['rule_action']
    local action_value = rule_conf['action_value']
    local matchs_result = true
    for _,rule_match in ipairs(rule_matchs) do
        local match_args = rule_match['match_args']
        local args_prepocess = rule_match['args_prepocess']
        local match_operator = rule_match['match_operator']
        local match_value = rule_match['match_value']
        local operator_result = false
        for _,match_arg in ipairs(match_args) do
          local arg = request.get_args(match_arg.key,match_arg.value)
          for _,arg_prepocess in ipairs(args_prepocess) do
                 arg = preprocess.process_args(arg_prepocess,arg)
          end
          if arg then
            local operator_match_result = operator.match(match_operator,arg,match_value)
            if  operator_match_result then
                operator_result =  true
                break
            end
          end
        end
        if (not operator_result) then
          matchs_result = false
          break
        end
    end
    if matchs_result then
      local waf_log = {}
      waf_log['waf_module'] = "flow_white_rule"
      waf_log['waf_policy'] = "流量白名单规则-"..rule_name
      waf_log['waf_action'] = rule_action
      waf_log['waf_extra'] = action_value
      ngx.ctx.waf_log = waf_log
      if rule_action == "flow_bypass" then
        ngx.ctx.flow_bypass = true
      end
    end
  end
end

function _M.flow_black_ip()
  local host = ngx.var.http_host or ngx.var.host
  local protection_data = _waf_protection_data[host] or _waf_protection_data[_config_info.waf_node_uuid]
  local flow_black_ip_data = _waf_flow_black_ip_data[host] or _waf_flow_black_ip_data[_config_info.waf_node_uuid]
  if not protection_data or not flow_black_ip_data or (protection_data and protection_data['flow_black_ip'] == "false") or ngx.ctx.flow_bypass then
    return
  end

  local src_ip = request.get_args("http_args","src_ip")
  local result = flow_black_ip_data[src_ip]
  if result then
    local block_action = result['block_action']
    local action_value = result['action_value']
    local waf_log = {}
    waf_log['waf_module'] = "flow_black_ip"
    waf_log['waf_policy'] = "流量防护-IP黑名单"
    waf_log['waf_action'] = block_action
    waf_log['waf_extra'] = action_value
    ngx.ctx.waf_log = waf_log
    ngx.ctx.flow_black_ip_result = "true"
    if block_action == "block"  then
      local page_conf = {}
      if _sys_conf_data['custom_deny_page'] == 'true' then
        page_conf['code'] = _sys_conf_data['waf_deny_code']
        page_conf['html'] = _sys_conf_data['waf_deny_html']
      end
      unify_action.block(page_conf)
    elseif block_action == "reject_response"  then
      unify_action.reject_response()
    elseif  block_action == "bot_check" then
      _jxwaf_engine.bot_commit_auth(_config_info['bot_check_ip_bind'])
      _jxwaf_engine.bot_check_ip(action_value,_config_info['waf_cc_js_website'],_config_info['bot_check_ip_bind'])
    end
  end
end

function _M.flow_ip_region_block()
  local host = ngx.var.http_host or ngx.var.host
  local protection_data = _waf_protection_data[host] or _waf_protection_data[_config_info.waf_node_uuid]
  local flow_ip_region_block_data = _waf_flow_ip_region_block_data[host] or _waf_flow_ip_region_block_data[_config_info.waf_node_uuid]
  if not protection_data or not flow_ip_region_block_data or (protection_data and protection_data['flow_ip_region_block'] == "false") or ngx.ctx.flow_bypass then
    return 
  end
  
  local ip_region_block = flow_ip_region_block_data['ip_region_block']
  local region_white_list = flow_ip_region_block_data['region_white_list']
  local block_action = flow_ip_region_block_data['block_action']
  local action_value = flow_ip_region_block_data['action_value']
  if ip_region_block == 'true' then
    local iso_code = ngx.ctx.iso_code
    if iso_code then
      if not region_white_list[iso_code] then
          local waf_log = {}
          waf_log['waf_module'] = "flow_ip_region_block"
          waf_log['waf_policy'] = "流量防护-IP区域封禁"
          waf_log['waf_action'] = block_action
          waf_log['waf_extra'] = iso_code
          ngx.ctx.waf_log = waf_log
          ngx.ctx.flow_ip_region_block_result = "true"
          if block_action == "block"  then
            local page_conf = {}
            if _sys_conf_data['custom_deny_page'] == 'true' then
              page_conf['code'] = _sys_conf_data['waf_deny_code']
              page_conf['html'] = _sys_conf_data['waf_deny_html']
            end
            unify_action.block(page_conf)
          elseif block_action == "reject_response"  then
            unify_action.reject_response()
          elseif  block_action == "bot_check" then
            _jxwaf_engine.bot_commit_auth(_config_info['bot_check_ip_bind'])
            _jxwaf_engine.bot_check_ip(action_value,_config_info['waf_cc_js_website'],_config_info['bot_check_ip_bind'])
          end
      end
    end
  end
end

function _M.flow_rule_protection()
  local host = ngx.var.http_host or ngx.var.host
  local protection_data = _waf_protection_data[host] or _waf_protection_data[_config_info.waf_node_uuid]
  local flow_rule_protection_data = _waf_flow_rule_protection_data[host] or _waf_flow_rule_protection_data[_config_info.waf_node_uuid]
  if not protection_data or not flow_rule_protection_data or (protection_data and protection_data['flow_rule_protection'] == "false") or ngx.ctx.flow_bypass then
    return 
  end
  local jxwaf_inner = ngx.shared.jxwaf_inner
  local src_ip =  request.get_args("http_args","src_ip")
  local block_result = jxwaf_inner:get("flow_rule_block"..src_ip)
  if block_result then
    local block_action = cjson.decode(block_result)
    local rule_name = block_action['rule_name']
    local rule_action = block_action['rule_action']
    local action_value = block_action['action_value']
    local waf_log = {}
    waf_log['waf_module'] = "flow_rule_protection"
    waf_log['waf_policy'] = "流量防护规则-"..rule_name
    waf_log['waf_action'] = rule_action
    waf_log['waf_extra'] = action_value
    ngx.ctx.waf_log = waf_log
    if rule_action == "block"  then
      local page_conf = {}
      if _sys_conf_data['custom_deny_page'] == 'true' then
        page_conf['code'] = _sys_conf_data['waf_deny_code']
        page_conf['html'] = _sys_conf_data['waf_deny_html']
      end
      unify_action.block(page_conf)
    elseif rule_action == "reject_response"  then
      unify_action.reject_response()
    elseif  rule_action == "bot_check" then
      _jxwaf_engine.bot_commit_auth(_config_info['bot_check_ip_bind'])
      _jxwaf_engine.bot_check_ip(action_value,_config_info['waf_cc_js_website'],_config_info['bot_check_ip_bind'])
    end
  end


  for _,rule_conf in ipairs(flow_rule_protection_data) do
    local rule_name = rule_conf['rule_name']
    local filter = rule_conf['filter']
    local rule_matchs = rule_conf['rule_matchs']
    local entity = rule_conf['entity']
    local stat_time = tonumber(rule_conf['stat_time'])
    local exceed_count = tonumber(rule_conf['exceed_count'])
    local rule_action = rule_conf['rule_action']
    local action_value = rule_conf['action_value']
    local block_time = tonumber(rule_conf['block_time'])
    local matchs_result = true
    if filter == "true" then
        for _,rule_match in ipairs(rule_matchs) do
            local match_args = rule_match['match_args']
            local args_prepocess = rule_match['args_prepocess']
            local match_operator = rule_match['match_operator']
            local match_value = rule_match['match_value']
            local operator_result = false
            for _,match_arg in ipairs(match_args) do
              local arg = request.get_args(match_arg.key,match_arg.value)
              for _,arg_prepocess in ipairs(args_prepocess) do
                     arg = preprocess.process_args(arg_prepocess,arg)
              end
              if arg then
                local operator_match_result = operator.match(match_operator,arg,match_value)
                if  operator_match_result then
                    operator_result =  true
                    break
                end
              end
            end
            if (not operator_result) then
              matchs_result = false
              break
            end
        end
    end
    if matchs_result then
        local statics_object_table = {}
        statics_object_table[1] = "flow_rule_stat"
        local nil_exist
        for _,v in ipairs(entity) do
          local return_value = request.get_args(v.key,v.value)
          if type(return_value) == "string" then
            table.insert(statics_object_table,return_value)
          elseif type(return_value) == "table" and type(return_value[1]) == "string" then
            table.insert(statics_object_table,return_value[1])
          else
            nil_exist = true
            break
          end
        end
        if not nil_exist then
          local statics_object_key = table.concat(statics_object_table)
          local statics_object_result = jxwaf_inner:incr(statics_object_key,1,0,stat_time)
          if statics_object_result > exceed_count then
	        local src_ip =  request.get_args("http_args","src_ip")
	        local block_action = {}
	        block_action['rule_name'] = rule_name
	        block_action['rule_action'] = rule_action
	        block_action['action_value'] = action_value
            jxwaf_inner:set("flow_rule_block"..src_ip,cjson.encode(block_action),block_time)
          end
        end
    end
  end
end


function _M.flow_engine_protection()
  local host = ngx.var.http_host or ngx.var.host
  local protection_data = _waf_protection_data[host] or _waf_protection_data[_config_info.waf_node_uuid]
  local flow_engine_protection_data = _waf_flow_engine_protection_data[host] or _waf_flow_engine_protection_data[_config_info.waf_node_uuid]
  if not protection_data or not flow_engine_protection_data or (protection_data and protection_data['flow_engine_protection'] == "false") or ngx.ctx.flow_bypass then
    return 
  end
  local jxwaf_inner = ngx.shared.jxwaf_inner
  local src_ip =  request.get_args("http_args","src_ip")
  local block_result = jxwaf_inner:get("high_freq_cc_block"..src_ip)
  if block_result then
    local block_action = cjson.decode(block_result)
    local rule_name = block_action['rule_name']
    local rule_action = block_action['rule_action']
    local action_value = block_action['action_value']
    local waf_log = {}
    waf_log['waf_module'] = "flow_engine_protection"
    waf_log['waf_policy'] = rule_name
    waf_log['waf_action'] = rule_action
    waf_log['waf_extra'] = action_value
    ngx.ctx.waf_log = waf_log
    if rule_action == "block" then
      local page_conf = {}
      if _sys_conf_data['custom_deny_page'] == 'true' then
        page_conf['code'] = _sys_conf_data['waf_deny_code']
        page_conf['html'] = _sys_conf_data['waf_deny_html']
      end
      unify_action.block(page_conf)
    elseif rule_action == "reject_response" then
      unify_action.reject_response()
    elseif rule_action == "bot_check" then
      _jxwaf_engine.bot_commit_auth(_config_info['bot_check_ip_bind'])
      _jxwaf_engine.bot_check_ip(action_value,_config_info['waf_cc_js_website'],_config_info['bot_check_ip_bind'])
    end
    return
  end
  local check_result,check_type = _jxwaf_engine.flow_check(flow_engine_protection_data)
  if check_result then
    local flow_type 
    local block_mode 
    local block_mode_extra_parameter
    local block_time
    if check_type == "high_freq_cc_rate_check" then
      block_mode = flow_engine_protection_data['req_rate_block_mode']
      block_mode_extra_parameter =  flow_engine_protection_data['req_rate_block_mode_extra_parameter']
      block_time = tonumber(flow_engine_protection_data['req_rate_block_time'])
      flow_type = "流量防护引擎-高频CC攻击"
	  local block_action = {}
	  block_action['rule_name'] = flow_type
	  block_action['rule_action'] = block_mode
	  block_action['action_value'] = block_mode_extra_parameter
      jxwaf_inner:set("high_freq_cc_block"..src_ip,cjson.encode(block_action),block_time)
    elseif check_type == "high_freq_cc_count_check" then
      block_mode =  flow_engine_protection_data['req_count_block_mode']
      block_mode_extra_parameter = flow_engine_protection_data['req_count_block_mode_extra_parameter']
      block_time = tonumber(flow_engine_protection_data['req_count_block_time'])
      flow_type = "流量防护引擎-高频CC攻击"
	  local block_action = {}
	  block_action['rule_name'] = flow_type
	  block_action['rule_action'] = block_mode
	  block_action['action_value'] = block_mode_extra_parameter
      jxwaf_inner:set("high_freq_cc_block"..src_ip,cjson.encode(block_action),block_time)
    elseif check_type == "slow_cc_ip_count_check"  then
      block_mode = flow_engine_protection_data['ip_count_block_mode']
      block_mode_extra_parameter =  flow_engine_protection_data['ip_count_block_mode_extra_parameter']
      flow_type = "流量防护引擎-慢速CC攻击"
    elseif check_type == "slow_cc_domain_check"  then
      block_mode = flow_engine_protection_data['slow_cc_block_mode']
      block_mode_extra_parameter  = flow_engine_protection_data['slow_cc_block_mode_extra_parameter']
      flow_type = "流量防护引擎-慢速CC攻击"
    elseif check_type == "emergency_mode_check"  then
      block_mode =  flow_engine_protection_data['emergency_mode_block_mode']
      block_mode_extra_parameter =  flow_engine_protection_data['emergency_mode_block_mode_extra_parameter']
      flow_type = "流量防护引擎-应急模式"
    end
    -- log
    local waf_log = {}
    waf_log['waf_module'] = "flow_engine_protection"
    waf_log['waf_policy'] = flow_type
    waf_log['waf_action'] = block_mode
    waf_log['waf_extra'] = block_mode_extra_parameter
    ngx.ctx.waf_log = waf_log
    ngx.ctx.flow_engine_protection_result[check_type] = "true"
    -- log
    if block_mode == "block" then
      local page_conf = {}
      if _sys_conf_data['custom_deny_page'] == 'true' then
        page_conf['code'] = _sys_conf_data['waf_deny_code']
        page_conf['html'] = _sys_conf_data['waf_deny_html']
      end
      unify_action.block(page_conf)
    elseif block_mode == "reject_response" then
      unify_action.reject_response()
    elseif block_mode == "bot_check" then
      _jxwaf_engine.bot_commit_auth(_config_info['bot_check_ip_bind'])
      _jxwaf_engine.bot_check_ip(block_mode_extra_parameter,_config_info['waf_cc_js_website'],_config_info['bot_check_ip_bind'])
    end
  end
end


function _M.web_white_rule()
  local host = ngx.var.http_host or ngx.var.host
  local protection_data = _waf_protection_data[host] or _waf_protection_data[_config_info.waf_node_uuid]
  local web_white_rule_data = _waf_web_white_rule_data[host] or _waf_web_white_rule_data[_config_info.waf_node_uuid]
  if not protection_data or not web_white_rule_data or (protection_data and protection_data['web_white_rule'] == "false") then
    return 
  end
  for _,rule_conf in ipairs(web_white_rule_data) do
    local rule_name = rule_conf['rule_name']
    local rule_matchs = rule_conf['rule_matchs']
    local rule_action = rule_conf['rule_action']
    local action_value = rule_conf['action_value']
    local matchs_result = true
    for _,rule_match in ipairs(rule_matchs) do
        local match_args = rule_match['match_args']
        local args_prepocess = rule_match['args_prepocess']
        local match_operator = rule_match['match_operator']
        local match_value = rule_match['match_value']
        local operator_result = false
        for _,match_arg in ipairs(match_args) do
          local arg = request.get_args(match_arg.key,match_arg.value)
          for _,arg_prepocess in ipairs(args_prepocess) do
                 arg = preprocess.process_args(arg_prepocess,arg)
          end
          if arg then
            local operator_match_result = operator.match(match_operator,arg,match_value)
            if  operator_match_result then
                operator_result =  true
                break
            end
          end
        end
        if (not operator_result) then
          matchs_result = false
          break
        end
    end
    if matchs_result then
      local waf_log = {}
      waf_log['waf_module'] = "web_white_rule"
      waf_log['waf_policy'] = "Web白名单规则-"..rule_name
      waf_log['waf_action'] = rule_action
      waf_log['waf_extra'] = action_value
      ngx.ctx.waf_log = waf_log
      if rule_action == "web_bypass" then
        ngx.ctx.web_bypass = true
      end
    end
  end
end

function _M.web_rule_protection()
  local host = ngx.var.http_host or ngx.var.host
  local protection_data = _waf_protection_data[host] or _waf_protection_data[_config_info.waf_node_uuid]
  local web_rule_protection_data = _waf_web_rule_protection_data[host] or _waf_web_rule_protection_data[_config_info.waf_node_uuid]
  if not protection_data or not web_rule_protection_data or (protection_data and protection_data['web_rule_protection'] == "false") or ngx.ctx.web_bypass then
    return 
  end
  for _,rule_conf in ipairs(web_rule_protection_data) do
    local rule_name = rule_conf['rule_name']
    local rule_matchs = rule_conf['rule_matchs']
    local rule_action = rule_conf['rule_action']
    local action_value = rule_conf['action_value']
    local matchs_result = true
    for _,rule_match in ipairs(rule_matchs) do
        local match_args = rule_match['match_args']
        local args_prepocess = rule_match['args_prepocess']
        local match_operator = rule_match['match_operator']
        local match_value = rule_match['match_value']
        local operator_result = false
        for _,match_arg in ipairs(match_args) do
          local arg = request.get_args(match_arg.key,match_arg.value)
          for _,arg_prepocess in ipairs(args_prepocess) do
                 arg = preprocess.process_args(arg_prepocess,arg)
          end
          if arg then
            local operator_match_result = operator.match(match_operator,arg,match_value)
            if  operator_match_result then
                operator_result =  true
                break
            end
          end
        end
        if (not operator_result) then
          matchs_result = false
          break
        end
    end
    if matchs_result then
      local waf_log = {}
      waf_log['waf_module'] = "web_rule_protection"
      waf_log['waf_policy'] = "Web防护规则-"..rule_name
      waf_log['waf_action'] = rule_action
      waf_log['waf_extra'] = action_value
      ngx.ctx.waf_log = waf_log
      ngx.ctx.web_rule_protection_result[rule_name] = 'true'
      ngx.ctx.waf_action = rule_action
      if rule_action == "block"  or rule_action == "reject_response" then
        ngx.ctx.waf_action = rule_action
        return
      end
    end
  end
end

function _M.web_engine_protection()
  local host = ngx.var.http_host or ngx.var.host
  local protection_data = _waf_protection_data[host] or _waf_protection_data[_config_info.waf_node_uuid]
  local web_engine_protection_data = _waf_web_engine_protection_data[host] or _waf_web_engine_protection_data[_config_info.waf_node_uuid]
  if not protection_data or not web_engine_protection_data or (protection_data and protection_data['web_engine_protection'] == "false") or ngx.ctx.web_bypass then
    return 
  end
  local check_result,check_type,check_action,web_engine_type = _jxwaf_engine.web_check(web_engine_protection_data)
  if check_result then
    if not ngx.ctx.waf_action then
        local waf_log = {}
        waf_log['waf_module'] = "web_engine_protection"
        waf_log['waf_policy'] = "Web防护引擎-"..web_engine_type
        waf_log['waf_action'] = check_action
        waf_log['waf_extra'] = ""
        ngx.ctx.waf_log = waf_log
    end
    ngx.ctx.web_engine_protection_result[check_type] = 'true'
    if not ngx.ctx.waf_action and (check_action == "block"  or check_action == "reject_response") then
       ngx.ctx.waf_action = check_action
       return
    end
  end
end

function _M.scan_attack_protection()
  local host = ngx.var.http_host or ngx.var.host
  local protection_data = _waf_protection_data[host] or _waf_protection_data[_config_info.waf_node_uuid]
  local scan_attack_protection_data = _waf_scan_attack_protection_data[host] or _waf_scan_attack_protection_data[_config_info.waf_node_uuid]
  if not protection_data or not scan_attack_protection_data or (protection_data and protection_data['scan_attack_protection'] == "false") or ngx.ctx.web_bypass then
    return
  end
  local jxwaf_inner = ngx.shared.jxwaf_inner
  local src_ip =  request.get_args("http_args","src_ip")
  local block_result = jxwaf_inner:get("scan_block"..src_ip)
  if block_result then
    local block_action = cjson.decode(block_result)
    local rule_name = block_action['rule_name']
    local rule_action = block_action['rule_action']
    local action_value = block_action['action_value']
    local waf_log = {}
    waf_log['waf_module'] = "scan_attack_protection"
    waf_log['waf_policy'] = "扫描攻击防护-"..rule_name
    waf_log['waf_action'] = rule_action
    waf_log['waf_extra'] = action_value
    ngx.ctx.waf_log = waf_log
    ngx.ctx.waf_action = rule_action
    return
  end
  for _,rule_conf in ipairs(scan_attack_protection_data) do
    local rule_name = rule_conf['rule_name']
    local rule_module = rule_conf['rule_module']
    local statics_object = rule_conf['statics_object']
    local statics_time = tonumber(rule_conf['statics_time'])
    local statics_count =  tonumber(rule_conf['statics_count'])
    local rule_action = rule_conf['rule_action']
    local action_value = rule_conf['action_value']
    local block_time = tonumber(rule_conf['block_time'])
    local rule_module_result
    for _,check_module in ipairs(rule_module) do
      local arg = request.get_args(check_module.key,check_module.value)
      if arg then
        rule_module_result = true
        break
      end
    end
    if rule_module_result then
        local statics_object_table = {}
        statics_object_table[1] = "scan_stat"
        local nil_exist
        for _,v in ipairs(statics_object) do
          local return_value = request.get_args(v.key,v.value)
          if type(return_value) == "string" then
            table.insert(statics_object_table,return_value)
          elseif type(return_value) == "table" and type(return_value[1]) == "string" then
            table.insert(statics_object_table,return_value[1])
          else
            nil_exist = true
            break
          end
        end
        if not nil_exist then
          local statics_object_key = table.concat(statics_object_table)
          local statics_object_result = jxwaf_inner:incr(statics_object_key,1,0,statics_time)
          if statics_object_result > statics_count then
	        local block_action = {}
	        block_action['rule_name'] = rule_name
	        block_action['rule_action'] = rule_action
	        block_action['action_value'] = action_value
            jxwaf_inner:set("scan_block"..src_ip,cjson.encode(block_action),block_time)
          end
        end
    end
  end

end

function _M.waf_action_process()
  local waf_action =  ngx.ctx.waf_action
  if  waf_action == "block" then
    local page_conf = {}
    if _sys_conf_data['custom_deny_page'] == 'true' then
      page_conf['code'] = _sys_conf_data['waf_deny_code']
      page_conf['html'] = _sys_conf_data['waf_deny_html']
     end
     unify_action.block(page_conf)
  elseif waf_action == "reject_response" then
      unify_action.reject_response()
  end
end




function _M.web_page_tamper_proof()
  local host = ngx.var.http_host or ngx.var.host
  local protection_data = _waf_protection_data[host] or _waf_protection_data[_config_info.waf_node_uuid]
  local web_page_tamper_proof_data = _waf_web_page_tamper_proof_data[host] or _waf_web_page_tamper_proof_data[_config_info.waf_node_uuid]
  if not protection_data or not web_page_tamper_proof_data or (protection_data and protection_data['web_page_tamper_proof'] == "false") or ngx.ctx.web_bypass then
    return
  end

  for _,rule_conf in ipairs(web_page_tamper_proof_data) do
    local rule_name = rule_conf['rule_name']
    local rule_matchs = rule_conf['rule_matchs']
    local cache_page_url = rule_conf['cache_page_url']
    local cache_content_type = rule_conf['cache_content_type']
    local cache_page_content = rule_conf['cache_page_content']
    local matchs_result = true
    for _,rule_match in ipairs(rule_matchs) do
        local match_args = rule_match['match_args']
        local args_prepocess = rule_match['args_prepocess']
        local match_operator = rule_match['match_operator']
        local match_value = rule_match['match_value']
        local operator_result = false
        for _,match_arg in ipairs(match_args) do
          local arg = request.get_args(match_arg.key,match_arg.value)
          for _,arg_prepocess in ipairs(args_prepocess) do
                 arg = preprocess.process_args(arg_prepocess,arg)
          end
          if arg then
            local operator_match_result = operator.match(match_operator,arg,match_value)
            if  operator_match_result then
                operator_result =  true
                break
            end
          end
        end
        if (not operator_result) then
          matchs_result = false
          break
        end
    end
    if matchs_result then
      local waf_log = {}
      waf_log['waf_module'] = "web_page_tamper_proof"
      waf_log['waf_policy'] = "网页防篡改-"..rule_name
      waf_log['waf_action'] = "page_tamper_proof"
      waf_log['waf_extra'] = cache_page_url
      ngx.ctx.waf_log = waf_log
      unify_action.page_tamper_proof(cache_content_type,cache_page_content)
    end
  end
end


function _M.analysis_component()
  for _,web_analysis_component_conf in ipairs(_waf_analysis_component_data) do
    local component_conf = web_analysis_component_conf['conf']
    local component_name = web_analysis_component_conf['name']
    if _waf_analysis_component_code[component_name] then
      local function_result,return_result = pcall(_waf_analysis_component_code[component_name].check,component_conf)
      if not function_result then
        ngx.log(ngx.ERR,"component_protection error name: "..component_name.." ,error_message: "..return_result)
      end
      if return_result  then
        ngx.ctx.analysis_comaponent_result[component_name] = "true"
      end 
    end
  end
end




function _M.redirect_https()
  local req_host = ngx.ctx.req_host
  local host = ngx.var.http_host or ngx.var.host
  local scheme = ngx.var.scheme
  if scheme == "https" then
    return
  end
  if req_host and  req_host['advanced_conf'] == "true" and req_host['https'] == "true" and req_host['force_https'] == "true"  then
    local force_https = {}
    force_https[1] = 'https://'
    force_https[2] = host
    force_https[3] = ngx.var.request_uri
    return ngx.redirect(table_concat(force_https), 301)
  end
end

function _M.init_jxwaf_devid()
   local cookie_jxwaf_devid = request.get_args("cookie_args","jxwaf_devid")
   if cookie_jxwaf_devid then
      return
   end
   _jxwaf_engine.init_jxwaf_devid(_config_info.waf_auth)
end


return _M
