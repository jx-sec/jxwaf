local ssl = require "ngx.ssl"
local byte = string.byte
local waf = require "resty.jxwaf.waf"
local unify_action = require "resty.jxwaf.unify_action"
local string_find = string.find
local string_sub = string.sub
local string_format = string.format
local table_concat = table.concat
local ssl_host = nil
local sys_abnormal_handle_data = waf.get_sys_abnormal_handle_data()
local sys_name_list_data = waf.get_sys_name_list_data()
local config_info = waf.get_config_info()
local ssl_attack_check = sys_abnormal_handle_data['ssl_attack_check']
local ssl_attack_count = sys_abnormal_handle_data['ssl_attack_count']
local ssl_attack_count_stat_time_period = sys_abnormal_handle_data['ssl_attack_count_stat_time_period']
local ssl_attack_block_name_list_uuid = sys_abnormal_handle_data['ssl_attack_block_name_list_uuid']
local jxwaf_limit_ssl = ngx.shared.jxwaf_limit_ssl
local host = ssl.server_name()
local server_port = ngx.var.server_port
local addr, addrtyp = ssl.raw_client_addr()

if not addr then
  return ngx.exit(444)
end

if not host then
  if ssl_attack_check == "true" then
    if addrtyp == "inet" then
      local ip = string_format("%d.%d.%d.%d", byte(addr, 1), byte(addr, 2),byte(addr, 3), byte(addr, 4))
      local val = jxwaf_limit_ssl:incr(ip, 1, 0, tonumber(ssl_attack_count_stat_time_period))
      if val and val > tonumber(ssl_attack_count) then
        unify_action.add_name_list_item(ssl_attack_block_name_list_uuid,sys_name_list_data,config_info,ip)
      end
    end
  end
  return ngx.exit(444)
end
local waf_domain_data = waf.get_waf_domain_data()
local waf_group_domain_data = waf.get_waf_group_domain_data()
local sys_ssl_manage_data = waf.get_sys_ssl_manage_data()
local dot_pos = string_find(host,".",1,true)
local wildcard_host = nil 
if dot_pos then
  wildcard_host = "*"..string_sub(host,dot_pos)
else
  wildcard_host = host 
end

if server_port ~= "443" then
  local custom_host = host + ":" + server_port
  if waf_domain_data[custom_host] then
    ssl_host = waf_domain_data[custom_host]
  elseif waf_group_domain_data[custom_host] then
    local group_id_data = {}
    group_id_data['domain_data'] = waf_group_domain_data[host]
    ssl_host = group_id_data
  end
end
if not ssl_host then
  if waf_domain_data[host] then
      ssl_host = waf_domain_data[host]
  else
    if waf_domain_data[wildcard_host] then
      ssl_host = waf_domain_data[wildcard_host]
    end
  end
end
  
if not ssl_host then
  if waf_group_domain_data[host] then
    local group_id_data = {}
    group_id_data['domain_data'] = waf_group_domain_data[host]
    ssl_host = group_id_data
  else
    if waf_group_domain_data[wildcard_host] then
      local group_id_data = {}
      group_id_data['domain_data'] = waf_group_domain_data[wildcard_host]
      ssl_host = group_id_data
    end
  end
end 

if not ssl_host then
  if ssl_attack_check == "true" then
    if addrtyp == "inet" then
      local ip = string_format("%d.%d.%d.%d", byte(addr, 1), byte(addr, 2),byte(addr, 3), byte(addr, 4))
      local val = jxwaf_limit_ssl:incr(ip, 1, 0, tonumber(ssl_attack_count_stat_time_period))
      if val and val > tonumber(ssl_attack_count) then
        unify_action.add_name_list_item(ssl_attack_block_name_list_uuid,sys_name_list_data,config_info,ip)
      end
    end
  end
  return ngx.exit(444)
end 

if ssl_host and ssl_host["domain_data"] and ssl_host["domain_data"]["https"] == 'true' then
    local clear_ok, clear_err = ssl.clear_certs()
    if not clear_ok then
      ngx.log(ngx.ERR, "failed to clear existing (fallback) certificates: ",clear_err..",server_name is "..host)
      return ngx.exit(444)
    end
    local public_key
    local private_key
    if ssl_host["domain_data"]["ssl_source"] == "ssl_manage" then
      local ssl_domain = ssl_host["domain_data"]["ssl_domain"]
      local ssl_manage_data = sys_ssl_manage_data[ssl_domain]
      if ssl_manage_data then
        public_key = ssl_manage_data["public_key"]
        private_key = ssl_manage_data["private_key"]
      else
        ngx.log(ngx.ERR, "sys_ssl_manage_data configure error")
        return ngx.exit(444)
      end
    elseif ssl_host["domain_data"]["ssl_source"] == "custom" then
      public_key = ssl_host["domain_data"]["public_key"]
      private_key = ssl_host["domain_data"]["private_key"]
    else
      ngx.log(ngx.ERR, "ssl_source configure error")
      return ngx.exit(444)
    end
    if (not public_key) or (not private_key) then
      ngx.log(ngx.ERR, "public_key or  private_key is nil")
      return ngx.exit(444)
    end
    local pem_cert_chain = public_key
    local der_cert_chain, err = ssl.cert_pem_to_der(pem_cert_chain)
    if not der_cert_chain then
      local error_info = {}
      ngx.log(ngx.ERR, "failed to convert certificate chain ","from PEM to DER: ", err..",server_name is "..host)
      return ngx.exit(444)
    end
    local set_ok, set_err = ssl.set_der_cert(der_cert_chain)
    if not set_ok then
      ngx.log(ngx.ERR, "failed to set DER cert: ", set_err..",server_name is "..host)
      return ngx.exit(444)
    end
    local pem_pkey = private_key
    local der_pkey, der_err = ssl.priv_key_pem_to_der(pem_pkey)
    if not der_pkey then
      ngx.log(ngx.ERR, "failed to convert private key ","from PEM to DER: ", der_err..",server_name is "..host)
      return ngx.exit(444)
    end
    local set_key_ok, set_key_err = ssl.set_der_priv_key(der_pkey)
    if not set_key_ok then
      ngx.log(ngx.ERR, "failed to set DER private key: ", set_key_err..",server_name is "..host)
      return ngx.exit(444)
    end
else
  if ssl_attack_check == "true" then
    if addrtyp == "inet" then
      local ip = string_format("%d.%d.%d.%d", byte(addr, 1), byte(addr, 2),byte(addr, 3), byte(addr, 4))
      local val = jxwaf_limit_ssl:incr(ip, 1, 0, tonumber(ssl_attack_count_stat_time_period))
      if val and val > tonumber(ssl_attack_count) then
        unify_action.add_name_list_item(ssl_attack_block_name_list_uuid,sys_name_list_data,config_info,ip)
      end
    end
  end
  return ngx.exit(444)
end

