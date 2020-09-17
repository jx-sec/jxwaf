local waf = require "resty.jxwaf.waf"
waf.ip_config_check()
waf.access_init()
waf.custom_rule_check()
waf.black_ip_check()
waf.bot_auth_check()
waf.limitreq_check()
waf.redirect_https()
waf.jxcheck_protection()

