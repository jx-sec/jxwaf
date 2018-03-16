local waf = require "resty.jxwaf.waf"
local config_path = "/opt/jxwaf/nginx/conf/jxwaf/jxwaf_config.json" 
waf.init(config_path)

