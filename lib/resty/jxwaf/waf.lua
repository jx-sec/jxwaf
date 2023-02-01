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

local _M = {}
_M.version = "20220831"

local _config_info = {}
local _conf_md5 = ""
local _name_list_item_conf_md5 = ""
local _fail_update_period = "60"
local _auto_update_period = "5"
local _waf_node_monitor_period = "5"
local _waf_domain_data = {}
local _waf_group_domain_data = {}
local _waf_group_id_data = {}
local _sys_web_rule_protection_data = {}
local _sys_web_white_rule_data = {}
local _sys_flow_rule_protection_data = {}
local _sys_flow_white_rule_data = {}
local _sys_shared_dict_data = {}
local _sys_name_list_data = {}
local _sys_ssl_manage_data = {}
local _sys_component_protection_data = {}
local _sys_web_engine_protection_data = nil
local _sys_flow_engine_protection_data = nil
local _waf_global_name_list_data = {}
local _waf_global_component_protection_data = {}
local _waf_global_ssl_component_protection_data = {}
local _waf_global_default_404_page_data = {}
local _sys_name_list_item_data = {}
local _sys_abnormal_handle_data = {}
local _sys_global_default_page_data = {}
local _sys_log_conf_data = {}
local _sys_action_data = {}

function _M.get_config_info()
	return _config_info
end

function _M.get_waf_domain_data()
	return _waf_domain_data
end

function _M.get_waf_group_domain_data()
	return _waf_group_domain_data
end

function _M.get_waf_group_id_data()
	return _waf_group_id_data
end

function _M.get_sys_ssl_manage_data()
	return _sys_ssl_manage_data
end

function _M.get_waf_global_name_list_data()
	return _waf_global_name_list_data
end

function _M.get_sys_name_list_item_data()
	return _sys_name_list_item_data
end

function _M.get_sys_name_list_data()
	return _sys_name_list_data
end

function _M.get_sys_shared_dict_data()
  return _sys_shared_dict_data
end

function _M.get_sys_abnormal_handle_data()
	return _sys_abnormal_handle_data
end

function _M.get_sys_log_conf_data()
	return _sys_log_conf_data
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
    post_data['api_key'] = _config_info.waf_api_key 
    post_data['api_password'] = _config_info.waf_api_password
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
   -- ngx.log(ngx.ALERT,"monitor report success")
end

local function _global_update_rule()
    local _update_website  =  _config_info.waf_update_website
    local httpc = http.new()
    httpc:set_timeouts(5000, 5000, 30000)
    local api_key = _config_info.waf_api_key or ""
    local api_password = _config_info.waf_api_password or ""
    local post_data = {}
    post_data['api_key'] = api_key
    post_data['api_password'] = api_password
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
      
      local waf_group_domain_data = res_body['waf_group_domain_data'] 
      if waf_group_domain_data == nil   then
        ngx.log(ngx.ERR,"waf_group_domain_data update fail")
        ngx.log(ngx.ERR,"60 seconds and try again ")
        return _update_at(tonumber(_fail_update_period),_global_update_rule)
      end
      
      local waf_group_id_data = res_body['waf_group_id_data'] 
      if waf_group_id_data == nil then
        ngx.log(ngx.ERR,"waf_group_domain_data update fail")
        ngx.log(ngx.ERR,"60 seconds and try again ")
        return _update_at(tonumber(_fail_update_period),_global_update_rule)
      end
      
      local sys_web_rule_protection_data = res_body['sys_web_rule_protection_data'] 
      if sys_web_rule_protection_data == nil then
        ngx.log(ngx.ERR,"sys_web_rule_protection_data update fail")
        ngx.log(ngx.ERR,"60 seconds and try again ")
        return _update_at(tonumber(_fail_update_period),_global_update_rule)
      end
      
      local sys_web_white_rule_data = res_body['sys_web_white_rule_data'] 
      if sys_web_white_rule_data == nil then
        ngx.log(ngx.ERR,"sys_web_white_rule_data update fail")
        ngx.log(ngx.ERR,"60 seconds and try again ")
        return _update_at(tonumber(_fail_update_period),_global_update_rule)
      end
      
      local sys_flow_rule_protection_data = res_body['sys_flow_rule_protection_data'] 
      if sys_flow_rule_protection_data == nil then
        ngx.log(ngx.ERR,"sys_flow_rule_protection_data update fail")
        ngx.log(ngx.ERR,"60 seconds and try again ")
        return _update_at(tonumber(_fail_update_period),_global_update_rule)
      end
      
      local sys_flow_white_rule_data = res_body['sys_flow_white_rule_data'] 
      if sys_flow_white_rule_data == nil then
        ngx.log(ngx.ERR,"sys_flow_white_rule_data update fail")
        ngx.log(ngx.ERR,"60 seconds and try again ")
        return _update_at(tonumber(_fail_update_period),_global_update_rule)
      end
      
      local sys_shared_dict_data = res_body['sys_shared_dict_data'] 
      if sys_shared_dict_data == nil then
        ngx.log(ngx.ERR,"sys_shared_dict_data update fail")
        ngx.log(ngx.ERR,"60 seconds and try again ")
        return _update_at(tonumber(_fail_update_period),_global_update_rule)
      end
      
      local sys_name_list_data = res_body['sys_name_list_data'] 
      if sys_name_list_data == nil then
        ngx.log(ngx.ERR,"sys_name_list_data update fail")
        ngx.log(ngx.ERR,"60 seconds and try again ")
        return _update_at(tonumber(_fail_update_period),_global_update_rule)
      end
      
      local sys_ssl_manage_data = res_body['sys_ssl_manage_data'] 
      if sys_ssl_manage_data == nil then
        ngx.log(ngx.ERR,"sys_ssl_manage_data update fail")
        ngx.log(ngx.ERR,"60 seconds and try again ")
        return _update_at(tonumber(_fail_update_period),_global_update_rule)
      end
      
      local waf_global_name_list_data = res_body['waf_global_name_list_data'] 
      if waf_global_name_list_data == nil then
        ngx.log(ngx.ERR,"waf_global_name_list_data update fail")
        ngx.log(ngx.ERR,"60 seconds and try again ")
        return _update_at(tonumber(_fail_update_period),_global_update_rule)
      end
      
      local waf_global_component_protection_data = res_body['waf_global_component_protection_data'] 
      if waf_global_component_protection_data == nil then
        ngx.log(ngx.ERR,"waf_global_component_protection_data update fail")
        ngx.log(ngx.ERR,"60 seconds and try again ")
        return _update_at(tonumber(_fail_update_period),_global_update_rule)
      end
      
      local sys_web_engine_protection_data = res_body['sys_web_engine_protection_data'] 
      if sys_web_engine_protection_data == nil then
        ngx.log(ngx.ERR,"sys_web_engine_protection_data update fail")
        ngx.log(ngx.ERR,"60 seconds and try again ")
        return _update_at(tonumber(_fail_update_period),_global_update_rule)
      end
      local load_sys_web_engine_protection_data = loadstring(ngx.decode_base64(res_body['sys_web_engine_protection_data']))()
      if load_sys_web_engine_protection_data then
        _sys_web_engine_protection_data = load_sys_web_engine_protection_data 
      else
        ngx.log(ngx.ERR,"load_sys_web_engine_protection_data update fail")
        ngx.log(ngx.ERR,"60 seconds and try again ")
        return _update_at(tonumber(_fail_update_period),_global_update_rule)
      end
      
      local sys_flow_engine_protection_data = res_body['sys_flow_engine_protection_data'] 
      if sys_flow_engine_protection_data == nil then
        ngx.log(ngx.ERR,"sys_flow_engine_protection_data update fail")
        ngx.log(ngx.ERR,"60 seconds and try again ")
        return _update_at(tonumber(_fail_update_period),_global_update_rule)
      end
      local load_sys_flow_engine_protection_data = loadstring(ngx.decode_base64(res_body['sys_flow_engine_protection_data']))()
      if load_sys_flow_engine_protection_data then
        _sys_flow_engine_protection_data = load_sys_flow_engine_protection_data 
      else
        ngx.log(ngx.ERR,"load_sys_flow_engine_protection_data update fail")
        ngx.log(ngx.ERR,"60 seconds and try again ")
        return _update_at(tonumber(_fail_update_period),_global_update_rule)
      end
      
      local sys_global_default_page_data = res_body['sys_global_default_page_data'] 
      if sys_global_default_page_data == nil then
        ngx.log(ngx.ERR,"sys_global_default_page_data update fail")
        ngx.log(ngx.ERR,"60 seconds and try again ")
        return _update_at(tonumber(_fail_update_period),_global_update_rule)
      end
      
      local sys_abnormal_handle_data = res_body['sys_abnormal_handle_data'] 
      if sys_abnormal_handle_data == nil then
        ngx.log(ngx.ERR,"sys_abnormal_handle_data update fail")
        ngx.log(ngx.ERR,"60 seconds and try again ")
        return _update_at(tonumber(_fail_update_period),_global_update_rule)
      end
      
      local sys_log_conf_data = res_body['sys_log_conf_data'] 
      if sys_log_conf_data == nil then
        ngx.log(ngx.ERR,"sys_log_conf_data update fail")
        ngx.log(ngx.ERR,"60 seconds and try again ")
        return _update_at(tonumber(_fail_update_period),_global_update_rule)
      end
      
      local sys_action_data = res_body['sys_action_data'] 
      if sys_action_data == nil then
        ngx.log(ngx.ERR,"sys_action_data update fail")
        ngx.log(ngx.ERR,"60 seconds and try again ")
        return _update_at(tonumber(_fail_update_period),_global_update_rule)
      end
      
      local sys_component_protection_data = res_body['sys_component_protection_data'] 
      if sys_component_protection_data == nil then
        ngx.log(ngx.ERR,"sys_component_protection_data update fail")
        ngx.log(ngx.ERR,"60 seconds and try again ")
        return _update_at(tonumber(_fail_update_period),_global_update_rule)
      end
      for k,v in pairs(sys_component_protection_data) do 
        local load_sys_component_protection_data = loadstring(ngx.decode_base64(v))()
        if load_sys_component_protection_data then
          _sys_component_protection_data[k] = load_sys_component_protection_data
        else
          ngx.log(ngx.ERR,"init fail,can not decode load_sys_component_protection_data,uuid is "..k)
          return _update_at(tonumber(_fail_update_period),_global_update_rule)
        end 
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
      ngx.log(ngx.ALERT,"global config info md5 is ".._conf_md5..",update config info success")
    end
    
    _auto_update_period = res_body['auto_update_period'] or _auto_update_period
    local global_ok, global_err = ngx.timer.at(tonumber(_auto_update_period),_global_update_rule)
    if not global_ok then
      if global_err ~= "process exiting" then
        ngx.log(ngx.ERR, "failed to create the cycle timer: ", global_err)
      end
    end
end

local function _global_name_list_item_update()
  local _name_list_item_update_website  =  _config_info.waf_name_list_item_update_website
  local httpc = http.new()
  httpc:set_timeouts(5000, 5000, 30000)
  local api_key = _config_info.waf_api_key or ""
  local api_password = _config_info.waf_api_password or ""
  local post_data = {}
  post_data['api_key'] = api_key
  post_data['api_password'] = api_password
  post_data['conf_md5'] = _name_list_item_conf_md5
  post_data['waf_node_uuid'] = _config_info.waf_node_uuid
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
      local sys_name_list_item_data = res_body['sys_name_list_item_data'] 
      if sys_name_list_item_data == nil then
        ngx.log(ngx.ERR,"sys_name_list_item_data update fail")
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
    local global_ok, global_err = ngx.timer.at(tonumber(_auto_update_period),_global_name_list_item_update)
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

    local waf_group_domain_data = res_body['waf_group_domain_data']
    if waf_group_domain_data == nil  then
      ngx.log(ngx.ERR,"init fail,can not decode waf_group_domain_data")
    else
      _waf_group_domain_data = waf_group_domain_data
    end
    
    local waf_group_id_data = res_body['waf_group_id_data']
    if waf_group_id_data == nil  then
      ngx.log(ngx.ERR,"init fail,can not decode waf_group_id_data")
    else
      _waf_group_id_data = waf_group_id_data
    end
    
    local sys_web_rule_protection_data = res_body['sys_web_rule_protection_data']
    if sys_web_rule_protection_data == nil  then
      ngx.log(ngx.ERR,"init fail,can not decode sys_web_rule_protection_data")
    else
      _sys_web_rule_protection_data = sys_web_rule_protection_data
    end
    
    local sys_web_white_rule_data = res_body['sys_web_white_rule_data']
    if sys_web_white_rule_data == nil  then
      ngx.log(ngx.ERR,"init fail,can not decode sys_web_white_rule_data")
    else
      _sys_web_white_rule_data = sys_web_white_rule_data
    end
    
    local sys_flow_rule_protection_data = res_body['sys_flow_rule_protection_data']
    if sys_flow_rule_protection_data == nil  then
      ngx.log(ngx.ERR,"init fail,can not decode sys_flow_rule_protection_data")
    else
      _sys_flow_rule_protection_data = sys_flow_rule_protection_data
    end
    
    local sys_flow_white_rule_data = res_body['sys_flow_white_rule_data']
    if sys_flow_white_rule_data == nil  then
      ngx.log(ngx.ERR,"init fail,can not decode sys_flow_white_rule_data")
    else
      _sys_flow_white_rule_data = sys_flow_white_rule_data
    end
    
    local sys_shared_dict_data = res_body['sys_shared_dict_data']
    if sys_shared_dict_data == nil  then
      ngx.log(ngx.ERR,"init fail,can not decode sys_shared_dict_data")
    else
      _sys_shared_dict_data = sys_shared_dict_data
    end
    
    local sys_name_list_data = res_body['sys_name_list_data']
    if sys_name_list_data == nil  then
      ngx.log(ngx.ERR,"init fail,can not decode sys_name_list_data")
    else
      _sys_name_list_data = sys_name_list_data
    end
    
    local sys_ssl_manage_data = res_body['sys_ssl_manage_data']
    if sys_ssl_manage_data == nil  then
      ngx.log(ngx.ERR,"init fail,can not decode sys_ssl_manage_data")
    else
      _sys_ssl_manage_data = sys_ssl_manage_data
    end
    
    local waf_global_name_list_data = res_body['waf_global_name_list_data']
    if waf_global_name_list_data == nil  then
      ngx.log(ngx.ERR,"init fail,can not decode waf_global_name_list_data")
    else
      _waf_global_name_list_data = waf_global_name_list_data
    end
    
    local waf_global_component_protection_data = res_body['waf_global_component_protection_data']    
    if waf_global_component_protection_data == nil  then
      ngx.log(ngx.ERR,"init fail,can not decode waf_global_component_protection_data")
    else
      _waf_global_component_protection_data = waf_global_component_protection_data
    end
    
    local sys_web_engine_protection_data = res_body['sys_web_engine_protection_data'] 
    if sys_web_engine_protection_data == nil then
      ngx.log(ngx.ERR,"init fail,can not decode sys_web_engine_protection_data")
    end
    local load_sys_web_engine_protection_data = loadstring(ngx.decode_base64(res_body['sys_web_engine_protection_data']))()
    if load_sys_web_engine_protection_data then
      _sys_web_engine_protection_data = load_sys_web_engine_protection_data 
    else
      ngx.log(ngx.ERR,"init fail,can not decode load_sys_web_engine_protection_data")
    end
      
    local sys_flow_engine_protection_data = res_body['sys_flow_engine_protection_data'] 
    if sys_flow_engine_protection_data == nil then
      ngx.log(ngx.ERR,"init fail,can not decode sys_flow_engine_protection_data")
    end
    local load_sys_flow_engine_protection_data = loadstring(ngx.decode_base64(res_body['sys_flow_engine_protection_data']))()
    if load_sys_flow_engine_protection_data then
      _sys_flow_engine_protection_data = load_sys_flow_engine_protection_data 
    else
      ngx.log(ngx.ERR,"init fail,can not decode load_sys_flow_engine_protection_data")
    end
    
    local sys_global_default_page_data = res_body['sys_global_default_page_data']
    if sys_global_default_page_data == nil  then
      ngx.log(ngx.ERR,"init fail,can not decode sys_abnormal_request_handle_data")
    else
      _sys_global_default_page_data = sys_global_default_page_data
    end
    local sys_abnormal_handle_data = res_body['sys_abnormal_handle_data']
    if sys_abnormal_handle_data == nil  then
      ngx.log(ngx.ERR,"init fail,can not decode sys_abnormal_handle_data")
    else
      _sys_abnormal_handle_data = sys_abnormal_handle_data
    end
    
    local sys_log_conf_data = res_body['sys_log_conf_data']
    if sys_log_conf_data == nil  then
      ngx.log(ngx.ERR,"init fail,can not decode sys_log_conf_data")
    else
      _sys_log_conf_data = sys_log_conf_data
    end
    
    local sys_action_data = res_body['sys_action_data']
    if sys_action_data == nil  then
      ngx.log(ngx.ERR,"init fail,can not decode sys_action_data")
    else
      _sys_action_data = sys_action_data
    end
    
    local sys_component_protection_data = res_body['sys_component_protection_data']
    if sys_component_protection_data == nil  then
      ngx.log(ngx.ERR,"init fail,can not decode sys_component_protection_data")
    else
      for k,v in pairs(sys_component_protection_data) do 
        local load_sys_component_protection_data = loadstring(ngx.decode_base64(v))()
        if load_sys_component_protection_data then
          _sys_component_protection_data[k] = load_sys_component_protection_data
        else
          ngx.log(ngx.ERR,"init fail,can not decode load_sys_component_protection_data,uuid is "..k)
        end 
      end
    end
    
    _conf_md5 = res_body['conf_md5']
    ngx.log(ngx.ALERT,"worker config info md5 is ".._conf_md5..",update config info success")
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

    local sys_name_list_item_data = res_body['sys_name_list_item_data']
    if sys_name_list_item_data == nil  then
      ngx.log(ngx.ERR,"init fail,can not decode sys_name_list_item_data")
    else
      _sys_name_list_item_data = sys_name_list_item_data
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
    local hdl, err = ngx.timer.every(3,_worker_update_rule)
    if err then
      ngx.log(ngx.ERR, "failed to create the worker update timer: ", err)
    end
    
    local name_list_item_worker_init_ok,name_list_item_worker_init_err = ngx.timer.at(0,_worker_name_list_item_update)
    if not name_list_item_worker_init_ok then
      if name_list_item_worker_init_err ~= "process exiting" then
        ngx.log(ngx.ERR, "failed to create the init name_list worker timer: ", name_list_item_worker_init_err)
      end
    end
    local name_list_item_hdl, name_list_item_err = ngx.timer.every(3,_worker_name_list_item_update)
    if name_list_item_err then
      ngx.log(ngx.ERR, "failed to create the name_list worker update timer: ", name_list_item_err)
    end
  end
end

function _M.init(config_path)
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
  local ok, err = process.enable_privileged_agent()
  if not ok then
    ngx.log(ngx.ERR, "enables privileged agent failed error:", err)
  end
  ngx.log(ngx.ALERT,"jxwaf init success,waf node uuid is ".._config_info['waf_node_uuid'])
end


function _M.access_init() 
  local request_uuid = uuid.generate_random()
  ngx.ctx.request_uuid = request_uuid
  ngx.ctx.global_component_protection_result = {}
  ngx.ctx.global_name_list_result = {}
  ngx.ctx.base_component_protection_result = {}
  ngx.ctx.name_list_result = {}
  ngx.ctx.flow_rule_protection_result = {}
  ngx.ctx.flow_engine_protection_result = {}
  ngx.ctx.web_rule_protection_result = {}
  ngx.ctx.web_engine_protection_result = {}
  ngx.ctx.analysis_component_protection = {}
  local content_type = ngx.req.get_headers()["Content-type"]
  local content_length = ngx.req.get_headers()["Content-Length"]
  if ngx.ctx.req_host and content_type and  ngx.re.find(content_type, [=[^multipart/form-data]=],"oij") and content_length and tonumber(content_length) ~= 0 then
    local form, err = upload:new()
    local _file_content_disposition = {}
    local _file_content_type = {}
    local _file_body = {}
    if not form then
      ngx.log(ngx.ERR,"access_init error,upload_error failed to new upload:,"..err)
      return
    end
    while true do
      local typ, res, err = form:read()
      if not typ then
        ngx.log(ngx.ERR,"access_init error,upload_error failed to read:,"..err)
        break
      end
      if typ == "header" then
        if res[1] == "Content-Disposition" then
          table.insert(_file_content_disposition,res[2])
        end
        if res[1] == "Content-Type" then
          table.insert(_file_content_type,res[2])
        end
      end
      if typ == "body" then
        table.insert(_file_body,res)
      end
      if typ == "eof" then
        break
      end
    end
    if #_file_content_disposition > 0 then
      ngx.ctx.file_content_disposition = table.concat(_file_content_disposition" ")
    end
    if #_file_content_type > 0 then
      ngx.ctx.file_content_type = table.concat(_file_content_type," ")
    end
    if #_file_body > 0 then
      ngx.ctx.file_body = string.sub(table.concat(_file_body," "),1,65535)
    end
  end
end

function _M.global_component_protection()
  for _,global_component_protection_conf in ipairs(_waf_global_component_protection_data) do
    local global_component_uuid = global_component_protection_conf['uuid']
    local global_component_conf = global_component_protection_conf['conf']
    local global_component_name = global_component_protection_conf['name']
    if _sys_component_protection_data[global_component_uuid] then
      local function_result,return_result = pcall(_sys_component_protection_data[global_component_uuid].check,global_component_conf)
      if not function_result then
        ngx.log(ngx.ERR,"global_component_protection error name: "..global_component_name.." ,error_message: "..return_result)
      end
      if return_result then
      --ngx.ctx["global_component_result_"..global_component_name] = "true"
        ngx.ctx.global_component_protection_result[global_component_name] = true
      end
    end
  end
end


function _M.global_name_list()
  for _,name_list_uuid in ipairs(_waf_global_name_list_data) do
    if _sys_name_list_data[name_list_uuid] and _sys_name_list_item_data[name_list_uuid] then
      local name_list_conf = _sys_name_list_data[name_list_uuid]
      local name_list_item_data = _sys_name_list_item_data[name_list_uuid]
      local name_list_rule = name_list_conf['name_list_rule']
      local name_list_action = name_list_conf['name_list_action']
      local action_value = name_list_conf['action_value']
      local name_list_name = name_list_conf['name_list_name']
      local item_value_table = {}
      local nil_exist 
      for _,rule in ipairs(name_list_rule) do
        local key = rule['key']
        local value = rule['value']
        local return_value = request.get_args(key,value,_sys_shared_dict_data)
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
            waf_log['waf_module'] = "global_name_list"
            waf_log['waf_policy'] = name_list_name
            waf_log['waf_action'] = name_list_action
            waf_log['waf_extra'] = item_value
            ngx.ctx.waf_log = waf_log
            --ngx.ctx["global_name_list_result_"..name_list_name] = "true"
            ngx.ctx.global_name_list_result[name_list_name] = true
          if name_list_action == "block" or name_list_action == "tcp_block"  then
            local page_conf = {}
            page_conf['code'] = _sys_global_default_page_data['name_list_deny_code']
            page_conf['html'] = _sys_global_default_page_data['name_list_deny_html']
            unify_action.block(page_conf)
          elseif name_list_action == "allow" then
            unify_action.allow()
          elseif name_list_action == "check_bypass" then
            ngx.ctx[action_value] = true
          elseif name_list_action == "reject_response" then
            unify_action.reject_response()
          elseif name_list_action == "bot_check" then
            _sys_flow_engine_protection_data.bot_commit_auth()
            _sys_flow_engine_protection_data.bot_check_ip(action_value)
          elseif name_list_action == "custom_response" then
            unify_action.custom_response(_sys_action_data['custom_response_conf'])
          elseif name_list_action == "request_replace" then
            unify_action.request_replace(_sys_action_data['request_replace_conf'])
          elseif name_list_action == "response_replace" then
            unify_action.response_replace(_sys_action_data['response_replace_conf'])
          elseif name_list_action == "traffic_forward" then
            unify_action.traffic_forward(_sys_action_data['traffic_forward_conf'])
          end
        end
      end
    end
  end
end

function _M.domain_check()
  local req_host = ngx.ctx.req_host
  local scheme = ngx.var.scheme
  if (not req_host) or (req_host['domain_data'] and  req_host['domain_data'][scheme] == "false") then
    local page_conf = {}
    page_conf['code'] = _sys_global_default_page_data['domain_404_code']
    page_conf['html'] = _sys_global_default_page_data['domain_404_html']
    return unify_action.block(page_conf)
  end
end

function _M.base_component_protection()
  local req_host = ngx.ctx.req_host
  local component_protection_data = req_host['component_protection_data']
  local protection_data = req_host['protection_data']
  if not component_protection_data or (protection_data and protection_data['component_protection'] == "false") then
    return 
  end
  for _,component_protection in ipairs(component_protection_data) do
    local component_uuid = component_protection['uuid']
    local component_name = component_protection['name']
    local component_conf = component_protection['conf']
    if _sys_component_protection_data[component_uuid] then
      local function_result,return_result = pcall(_sys_component_protection_data[component_uuid].check,component_conf)
      if not function_result then
        ngx.log(ngx.ERR,"component_protection error component_name: "..component_name.." ,error_message: "..return_result)
      end
      if return_result  then
        --ngx.ctx["component_result_"..component_name] = "true"
        ngx.ctx.base_component_protection_result[component_name] = true
      end 
    end
  end 
end


function _M.name_list()
  local req_host = ngx.ctx.req_host
  local name_list_data = req_host['name_list_data']
  local protection_data = req_host['protection_data']
  if not name_list_data or (protection_data and protection_data['name_list'] == "false") then
    return 
  end
  if name_list_data then
  for _,name_list_uuid in ipairs(name_list_data) do
    if _sys_name_list_data[name_list_uuid] and _sys_name_list_item_data[name_list_uuid] then
      local name_list_conf = _sys_name_list_data[name_list_uuid]
      local name_list_item_data = _sys_name_list_item_data[name_list_uuid]
      local name_list_rule = name_list_conf['name_list_rule']
      local name_list_action = name_list_conf['name_list_action']
      local action_value = name_list_conf['action_value']
      local name_list_name = name_list_conf['name_list_name']
      local item_value_table = {}
      local nil_exist 
      for _,rule in ipairs(name_list_rule) do
        local key = rule['key']
        local value = rule['value']
        local return_value = request.get_args(key,value,_sys_shared_dict_data)
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
            waf_log['waf_policy'] = name_list_name
            waf_log['waf_action'] = name_list_action
            waf_log['waf_extra'] = item_value
            ngx.ctx.waf_log = waf_log
            --ngx.ctx["name_list_result_"..name_list_name] = "true"
            ngx.ctx.name_list_result[name_list_name] = true
          if name_list_action == "block" or name_list_action == "tcp_block"  then
            local page_conf = {}
            page_conf['code'] = _sys_global_default_page_data['name_list_deny_code']
            page_conf['html'] = _sys_global_default_page_data['name_list_deny_html']
            unify_action.block(page_conf)
          elseif name_list_action == "allow" then
            unify_action.allow()
          elseif name_list_action == "check_bypass" then
            ngx.ctx[action_value] = true
          elseif name_list_action == "reject_response" then
            unify_action.reject_response()
          elseif name_list_action == "bot_check" then
            _sys_flow_engine_protection_data.bot_commit_auth()
            _sys_flow_engine_protection_data.bot_check_ip(action_value)
          elseif name_list_action == "custom_response" then
            unify_action.custom_response(_sys_action_data['custom_response_conf'])
          elseif name_list_action == "request_replace" then
            unify_action.request_replace(_sys_action_data['request_replace_conf'])
          elseif name_list_action == "response_replace" then
            unify_action.response_replace(_sys_action_data['response_replace_conf'])
          elseif name_list_action == "traffic_forward" then
            unify_action.traffic_forward(_sys_action_data['traffic_forward_conf'])
          end
        end
      end
    end
  end
  end
end


function _M.flow_white_rule()
  local req_host = ngx.ctx.req_host
  local flow_white_rule_data = req_host['flow_white_rule_data']
  local protection_data = req_host['protection_data']
  if not flow_white_rule_data or (protection_data and protection_data['flow_white_rule'] == "false") then
    return 
  end
  for _,rule_uuid in ipairs(flow_white_rule_data) do
     if _sys_flow_white_rule_data[rule_uuid] then
       local rule_conf = _sys_flow_white_rule_data[rule_uuid]
       local rule_group_name = rule_conf['rule_group_name']
       local rule_name = rule_conf['rule_name']
       local rule_matchs = rule_conf['rule_matchs']
       local rule_action = rule_conf['rule_action']
       local action_value = rule_conf['action_value']
       local rule_log = rule_conf['rule_log']
       local rule_pre_match = rule_conf['rule_pre_match']
       local matchs_result = true
       if rule_pre_match == "true" then
        for _,rule_match in ipairs(rule_matchs) do
           local match_args = rule_match['match_args']
           local args_prepocess = rule_match['args_prepocess']
           local match_operator = rule_match['match_operator']
           local match_value = rule_match['match_value']
           local operator_result = false
           for _,match_arg in ipairs(match_args) do
             local arg = request.get_args(match_arg.key,match_arg.value,_sys_shared_dict_data)
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
          if rule_log == "true" then
            local waf_log = {}
            waf_log['waf_module'] = "flow_white_rule"
            waf_log['waf_policy'] = rule_name
            waf_log['waf_action'] = rule_action
            waf_log['waf_extra'] = rule_group_name
            ngx.ctx.waf_log = waf_log
          end
          if rule_action == "allow" then
            unify_action.allow()
          elseif rule_action == "flow_check_bypass" then
            for _,v in ipairs(action_value) do
              ngx.ctx[v] = true
            end
          elseif rule_action == "flow_rule_protection_bypass" then
            for _,v in ipairs(action_value) do
              ngx.ctx[v] = true
            end
          elseif rule_action == "flow_engine_protection_bypass" then
            for _,v in ipairs(action_value) do
              ngx.ctx[v] = true
            end
          end
       end
     end
  end
end

function _M.flow_rule_protection()
  local req_host = ngx.ctx.req_host
  local flow_rule_protection_data = req_host['flow_rule_protection_data']
  local protection_data = req_host['protection_data']
  if not flow_rule_protection_data or (protection_data and protection_data['flow_rule_protection'] == "false") then
    return 
  end
  for _,rule_uuid in ipairs(flow_rule_protection_data) do
     if _sys_flow_rule_protection_data[rule_uuid] then
       local rule_conf = _sys_flow_rule_protection_data[rule_uuid]
       local rule_group_name = rule_conf['rule_group_name']
       local rule_group_uuid = rule_conf['rule_group_uuid']
       local rule_name = rule_conf['rule_name']
       local rule_matchs = rule_conf['rule_matchs']
       local rule_action = rule_conf['rule_action']
       local action_value = rule_conf['action_value']
       local rule_log = rule_conf['rule_log']
       local rule_pre_match = rule_conf['rule_pre_match']
       local matchs_result = true
       if rule_pre_match == "true" then
        for _,rule_match in ipairs(rule_matchs) do
           local match_args = rule_match['match_args']
           local args_prepocess = rule_match['args_prepocess']
           local match_operator = rule_match['match_operator']
           local match_value = rule_match['match_value']
           local operator_result = false
           for _,match_arg in ipairs(match_args) do
             local arg = request.get_args(match_arg.key,match_arg.value,_sys_shared_dict_data)
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
       if matchs_result and  (not ngx.ctx['flow_check_bypass'])  and (not ngx.ctx['flow_rule_protection_bypass']) and (not ngx.ctx[rule_uuid]) and (not ngx.ctx[rule_group_uuid]) then
          if rule_log == "true" then
            local waf_log = {}
            waf_log['waf_module'] = "flow_rule_protection"
            waf_log['waf_policy'] = rule_name
            waf_log['waf_action'] = rule_action
            waf_log['waf_extra'] = rule_group_name
            ngx.ctx.waf_log = waf_log
          end
          ngx.ctx.flow_rule_protection_result[rule_name] = true
        if rule_action == "block" then
          local page_conf = {}
          page_conf['code'] = _sys_global_default_page_data['flow_deny_code']
          page_conf['html'] = _sys_global_default_page_data['flow_deny_html']
          unify_action.block(page_conf)
        elseif rule_action == "reject_response" then
          unify_action.reject_response()
        elseif rule_action == "bot_check" then
          _sys_flow_engine_protection_data.bot_commit_auth()
          _sys_flow_engine_protection_data.bot_check_ip(action_value)
        elseif rule_action == "add_shared_dict_key" then
          unify_action.add_shared_dict_key(action_value,_sys_shared_dict_data)
        elseif rule_action == "add_name_list_item" then
          unify_action.add_name_list_item(action_value,_sys_name_list_data,_config_info)
        end
       end
     end
  end
  
end


function _M.flow_engine_protection()
  local req_host = ngx.ctx.req_host
  local flow_engine_protection_data = req_host['flow_engine_protection_data']
  local protection_data = req_host['protection_data']
  if not flow_engine_protection_data or (protection_data and protection_data['flow_engine_protection'] == "false") then
    return 
  end
  local check_result,check_type = _sys_flow_engine_protection_data.check(flow_engine_protection_data)
  if check_result then
    local block_mode 
    local block_mode_extra_parameter
    if check_type == "high_freq_cc_rate_check" then
      block_mode = flow_engine_protection_data['req_rate_block_mode']
      block_mode_extra_parameter =  flow_engine_protection_data['req_rate_block_mode_extra_parameter']
    elseif check_type == "high_freq_cc_count_check" then
      block_mode =  flow_engine_protection_data['req_count_block_mode']
      block_mode_extra_parameter = flow_engine_protection_data['req_count_block_mode_extra_parameter']
    elseif check_type == "slow_cc_ip_count_check"  then
      block_mode = flow_engine_protection_data['ip_count_block_mode']
      block_mode_extra_parameter =  flow_engine_protection_data['ip_count_block_mode_extra_parameter']
    elseif check_type == "slow_cc_domain_check"  then
      block_mode = flow_engine_protection_data['slow_cc_block_mode']
      block_mode_extra_parameter  = flow_engine_protection_data['slow_cc_block_mode_extra_parameter']
    elseif check_type == "emergency_mode_check"  then
      block_mode =  flow_engine_protection_data['emergency_mode_block_mode']
      block_mode_extra_parameter =  flow_engine_protection_data['emergency_mode_block_mode_extra_parameter']
    end
    -- log
    local bypass_check = check_type.."_bypass"
    if ngx.ctx['flow_check_bypass']  and ngx.ctx['flow_engine_protection_bypass'] or ngx.ctx[bypass_check] then
      return
    end
            local waf_log = {}
            waf_log['waf_module'] = "flow_engine_protection"
            waf_log['waf_policy'] = check_type
            waf_log['waf_action'] = block_mode
            waf_log['waf_extra'] = ""
            ngx.ctx.waf_log = waf_log
    -- log
    --ngx.ctx[check_type] = true
    ngx.ctx.flow_engine_protection_result[check_type] = true
    if block_mode == "block" then
      local page_conf = {}
      page_conf['code'] = _sys_global_default_page_data['flow_deny_code']
      page_conf['html'] = _sys_global_default_page_data['flow_deny_html']
      unify_action.block(page_conf)
    elseif block_mode == "reject_response" then
      unify_action.reject_response()
    elseif block_mode == "bot_check" then
      _sys_flow_engine_protection_data.bot_commit_auth()
      _sys_flow_engine_protection_data.bot_check_ip(block_mode_extra_parameter)
    end
      
  end
end

function _M.web_white_rule()
  local req_host = ngx.ctx.req_host
  local web_white_rule_data = req_host['web_white_rule_data']
  local protection_data = req_host['protection_data']
  if not web_white_rule_data or (protection_data and protection_data['web_white_rule'] == "false") then
    return 
  end
  for _,rule_uuid in ipairs(web_white_rule_data) do
    if _sys_web_white_rule_data[rule_uuid] then
       local rule_conf = _sys_web_white_rule_data[rule_uuid]
       local rule_group_name = rule_conf['rule_group_name']
       local rule_name = rule_conf['rule_name']
       local rule_matchs = rule_conf['rule_matchs']
       local rule_action = rule_conf['rule_action']
       local action_value = rule_conf['action_value']
       local rule_log = rule_conf['rule_log']
       local matchs_result = true
       for _,rule_match in ipairs(rule_matchs) do
          local match_args = rule_match['match_args']
          local args_prepocess = rule_match['args_prepocess']
          local match_operator = rule_match['match_operator']
          local match_value = rule_match['match_value']
          local operator_result = false
          for _,match_arg in ipairs(match_args) do
            local arg = request.get_args(match_arg.key,match_arg.value,_sys_shared_dict_data)
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
          if rule_log == "true" then
            local waf_log = {}
            waf_log['waf_module'] = "web_white_rule"
            waf_log['waf_policy'] = rule_name
            waf_log['waf_action'] = rule_action
            waf_log['waf_extra'] = rule_group_name
            ngx.ctx.waf_log = waf_log
          end
          if rule_action == "allow" then
            unify_action.allow()
          elseif rule_action == "web_check_bypass" then
            for _,v in ipairs(action_value) do
              ngx.ctx[v] = true
            end
          elseif rule_action == "web_rule_protection_bypass" then
            for _,v in ipairs(action_value) do
              ngx.ctx[v] = true
            end
          elseif rule_action == "web_engine_protection_bypass" then
            for _,v in ipairs(action_value) do
              ngx.ctx[v] = true
            end
          end
       end
    end
  end
end

function _M.web_rule_protection()
  local req_host = ngx.ctx.req_host
  local web_rule_protection_data = req_host['web_rule_protection_data']
  local protection_data = req_host['protection_data']
  if not web_rule_protection_data or (protection_data and protection_data['web_rule_protection'] == "false") then
    return 
  end
  for _,rule_uuid in ipairs(web_rule_protection_data) do
    if _sys_web_rule_protection_data[rule_uuid] then
       local rule_conf = _sys_web_rule_protection_data[rule_uuid]
       local rule_group_name = rule_conf['rule_group_name']
       local rule_group_uuid = rule_conf['rule_group_uuid']
       local rule_name = rule_conf['rule_name']
       local rule_matchs = rule_conf['rule_matchs']
       local rule_action = rule_conf['rule_action']
       local action_value = rule_conf['action_value']
       local rule_log = rule_conf['rule_log']
       local matchs_result = true
       for _,rule_match in ipairs(rule_matchs) do
          local match_args = rule_match['match_args']
          local args_prepocess = rule_match['args_prepocess']
          local match_operator = rule_match['match_operator']
          local match_value = rule_match['match_value']
          local operator_result = false
          for _,match_arg in ipairs(match_args) do
            local arg = request.get_args(match_arg.key,match_arg.value,_sys_shared_dict_data)
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
       if matchs_result and (not ngx.ctx['web_check_bypass'])   and (not ngx.ctx['web_rule_protection_bypass']) and (not ngx.ctx[rule_uuid]) and (not ngx.ctx[rule_group_uuid])  then
        if rule_log == "true" then
            local waf_log = {}
            waf_log['waf_module'] = "web_rule_protection"
            waf_log['waf_policy'] = rule_name
            waf_log['waf_action'] = rule_action
            waf_log['waf_extra'] = rule_group_name 
            ngx.ctx.waf_log = waf_log
        end
        ngx.ctx.web_rule_protection_result[rule_name] = true
        if rule_action == "block" then
          local page_conf = {}
          page_conf['code'] = _sys_global_default_page_data['web_deny_code']
          page_conf['html'] = _sys_global_default_page_data['web_deny_html']
          unify_action.block(page_conf)
        elseif rule_action == "reject_response" then
          unify_action.reject_response()
        elseif rule_action == "bot_check" then
          _sys_flow_engine_protection_data.bot_commit_auth()
          _sys_flow_engine_protection_data.bot_check_ip(action_value)
        elseif rule_action == "add_shared_dict_key" then
          unify_action.add_shared_dict_key(action_value,_sys_shared_dict_data)
        elseif rule_action == "add_name_list_item" then
          unify_action.add_name_list_item(action_value,_sys_name_list_data,_config_info)
        elseif rule_action == "mimetic_defense" then
          unify_action.mimetic_defense(_sys_action_data['mimetic_defense_conf'])
        elseif rule_action == "custom_response" then
          unify_action.custom_response(_sys_action_data['custom_response_conf'])
        elseif rule_action == "request_replace" then
          unify_action.request_replace(_sys_action_data['request_replace_conf'])
        elseif rule_action == "response_replace" then
          unify_action.response_replace(_sys_action_data['response_replace_conf'])
        elseif rule_action == "traffic_forward" then
          unify_action.traffic_forward(_sys_action_data['traffic_forward_conf'])
        end
       end
    end
  end
  
end

function _M.web_engine_protection()
  local req_host = ngx.ctx.req_host
  local web_engine_protection_data = req_host['web_engine_protection_data']
  local protection_data = req_host['protection_data']
  if (not web_engine_protection_data) or (protection_data and protection_data['web_engine_protection'] == "false")  then
    return 
  end
  local check_result,check_type,check_action = _sys_web_engine_protection_data.check(web_engine_protection_data)
  if check_result then
    local bypass_check = check_type.."_bypass"
    if ngx.ctx['web_check_bypass'] or ngx.ctx['web_engine_protection_bypass'] or ngx.ctx[bypass_check] then
      return
    end
           
      local waf_log = {}
      waf_log['waf_module'] = "web_engine_protection"
      waf_log['waf_policy'] = check_type
      waf_log['waf_action'] = check_action
      waf_log['waf_extra'] = ""
      ngx.ctx.waf_log = waf_log
      --ngx.ctx[check_type] = true
      ngx.ctx.web_engine_protection_result[check_type] = true
    if  check_action == "block" then
      local page_conf = {}
      page_conf['code'] = _sys_global_default_page_data['web_deny_code']
      page_conf['html'] = _sys_global_default_page_data['web_deny_html']
      unify_action.block(page_conf)
    elseif check_action == "reject_response" then
      unify_action.reject_response()
    end
  end
end

function _M.analysis_component_protection()
  local req_host = ngx.ctx.req_host
  local analysis_component_data = req_host['analysis_component_data']
  local protection_data = req_host['protection_data']
  if not analysis_component_data or (protection_data and protection_data['component_protection'] == "false") then
    return 
  end
  for _,analysis_component in ipairs(analysis_component_data) do
    local component_uuid = analysis_component['uuid']
    local component_name = analysis_component['name']
    local component_conf = analysis_component['conf']
    if _sys_component_protection_data[component_uuid] then
      local function_result,return_result = pcall(_sys_component_protection_data[component_uuid].check,component_conf)
      if not function_result then
        ngx.log(ngx.ERR,"component_protection error component_name: "..component_name.." ,error_message: "..return_result)
      end
      if return_result  then
        --ngx.ctx["component_result_"..component_name] = "true"
        ngx.ctx.analysis_component_protection[component_name] = true
      end 
    end
  end 
end

function _M.abnormal_handle()
  if _sys_abnormal_handle_data['bypass_check'] == "true" then
    local abnormal_handle_check_result 
    local abnormal_handle_check_type 
    if _sys_abnormal_handle_data['same_name_args_check'] == "true" and ngx.ctx.same_name_args_check  then
        abnormal_handle_check_result = true
        abnormal_handle_check_type = "same_name_args_check"
    elseif _sys_abnormal_handle_data['truncated_agrs_check'] == "true" and ngx.ctx.truncated_agrs_check  then
        abnormal_handle_check_result = true
        abnormal_handle_check_type = "truncated_agrs_check"
    elseif _sys_abnormal_handle_data['client_body_size_check'] == "true" and ngx.ctx.client_body_size_check  then
        abnormal_handle_check_result = true
        abnormal_handle_check_type = "client_body_size_check"
    end
    if abnormal_handle_check_result then
      -- log --
            local waf_log = {}
            waf_log['waf_module'] = "abnormal_handle"
            waf_log['waf_policy'] = abnormal_handle_check_type
            waf_log['waf_action'] = "block"
            waf_log['waf_extra'] = ""
            ngx.ctx.waf_log = waf_log
      -- log --
      local page_conf = {}
      page_conf['code'] = _sys_global_default_page_data['web_deny_code']
      page_conf['html'] = _sys_global_default_page_data['web_deny_html']
      unify_action.block(page_conf)
    end
    
  end
  
end






return _M
