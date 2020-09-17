local waf = require "resty.jxwaf.waf"
waf.access_init()
waf.ip_config_check()
waf.black_ip_check()
waf.bot_auth_check()
waf.limitreq_check()
waf.redirect_https()
waf.file_upload_check()
waf.custom_rule_check()
waf.jxcheck_protection()

