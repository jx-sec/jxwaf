local waf = require "resty.jxwaf.waf"
waf.access_init()
waf.custom_rule_check()
waf.geo_protection()
waf.attack_ip_protection()
waf.limitreq_check()
waf.redirect_https()
waf.jxcheck_protection()

