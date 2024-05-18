require "resty.core"
local waf = require "resty.jxwaf.waf"
local config_path = "/opt/jxwaf/nginx/conf/jxwaf/jxwaf_config.json"
local jxcore_path = "/opt/jxwaf/nginx/conf/jxwaf/jxcore"
waf.init(config_path,jxcore_path)

