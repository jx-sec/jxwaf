local enc_ck = require "resty.jxwaf.enc_ck"
local waf = require "resty.jxwaf.waf"

local resp_js_insert = waf.resp_js_insert()
enc_ck.resp_aes_ck()
if resp_js_insert = "true" or ngx.ctx.resp_js_insert = "true" then
    ngx.header.content_length = nil
end

