local waf = require "resty.jxwaf.waf"

waf.access_init()
waf.limitreq_check()
waf.base_check()
