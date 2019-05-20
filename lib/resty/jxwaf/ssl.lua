local ssl = require "ngx.ssl"
local waf = require "resty.jxwaf.waf"
local request = require "resty.jxwaf.request"
local waf_rule = waf.get_waf_rule()
local host = ssl.server_name()
local string_find = string.find
local string_sub = string.sub
local ssl_host = nil

if waf_rule[host] then
  ssl_host = waf_rule[host]
else
  local dot_pos = string_find(host,".",1,true)
  local wildcard_host = "*"..string_sub(host,dot_pos)
  if waf_rule[wildcard_host] then
    ssl_host = waf_rule[wildcard_host]
  end
end

local exit_code = require "resty.jxwaf.exit_code"
if ssl_host then
	local clear_ok, clear_err = ssl.clear_certs()
  if not clear_ok then
    local error_info = {}
    error_info['log_type'] = "error_log"
    error_info['error_type'] = "ssl"
    error_info['error_info'] = "failed to clear existing (fallback) certificates: "..clear_err..",server_name is "..host
    ngx.ctx.error_log = error_info
    ngx.log(ngx.ERR, "failed to clear existing (fallback) certificates: ",clear_err..",server_name is "..host)
    exit_code.return_error()
  end
	local pem_cert_chain = assert(ssl_host["domain_set"]["public_key"])
  local der_cert_chain, err = ssl.cert_pem_to_der(pem_cert_chain)
  if not der_cert_chain then
    local error_info = {}
    error_info['log_type'] = "error_log"
    error_info['error_type'] = "ssl"
    error_info['error_info'] = "failed to convert certificate chain ","from PEM to DER: "..err..",server_name is "..host
    ngx.ctx.error_log = error_info
    ngx.log(ngx.ERR, "failed to convert certificate chain ","from PEM to DER: ", err..",server_name is "..host)
    exit_code.return_error()
  end
  local set_ok, set_err = ssl.set_der_cert(der_cert_chain)
  if not set_ok then
    local error_info = {}
    error_info['log_type'] = "error_log"
    error_info['error_type'] = "ssl"
    error_info['error_info'] = "failed to set DER cert: "..set_err..",server_name is "..host
    ngx.ctx.error_log = error_info
    ngx.log(ngx.ERR, "failed to set DER cert: ", set_err..",server_name is "..host)
    exit_code.return_error()
  end
  local pem_pkey = assert(ssl_host["domain_set"]["private_key"])
  local der_pkey, der_err = ssl.priv_key_pem_to_der(pem_pkey)
  if not der_pkey then
    local error_info = {}
    error_info['log_type'] = "error_log"
    error_info['error_type'] = "ssl"
    error_info['error_info'] = "failed to convert private key ","from PEM to DER: "..der_err..",server_name is "..host
    ngx.ctx.error_log = error_info
    ngx.log(ngx.ERR, "failed to convert private key ","from PEM to DER: ", der_err..",server_name is "..host)
    exit_code.return_error()
  end
  local set_key_ok, set_key_err = ssl.set_der_priv_key(der_pkey)
  if not set_key_ok then
    local error_info = {}
    error_info['log_type'] = "error_log"
    error_info['error_type'] = "ssl"
    error_info['error_info'] = "failed to set DER private key: "..set_key_err..",server_name is "..host
    ngx.ctx.error_log = error_info
    ngx.log(ngx.ERR, "failed to set DER private key: ", set_key_err..",server_name is "..host)
    exit_code.return_error()
  end
else
	exit_code.return_no_exist()
end
