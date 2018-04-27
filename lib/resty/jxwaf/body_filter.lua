local waf = require "resty.jxwaf.waf"
local config_info = waf.get_config_info()
local request = require "resty.jxwaf.request"
local zlib = require "resty.jxwaf.ffi-zlib"

if ngx.ctx.resp_js_insert == "true" and ngx.ctx.is_inject ~= "true" and ngx.arg[2] ~= true  then
	local payload = request.request['RESP_BODY']()..[=[<script>alert(/test/)</script>]=]
	local count = 0
local input = function(bufsize)
    local start = count > 0 and bufsize*count or 1
    local data = payload:sub(start, (bufsize*(count+1)-1))
    if data == "" then
        data = nil
    end

    count = count + 1
    return data
     end
local output_table = {}
local output = function(data)
    table.insert(output_table, data)
end
local chunk = 16384
local ok, err = zlib.deflateGzip(input, output, chunk)
if not ok then
    ngx.log(ngx.ERR,err)
end
local compressed = table.concat(output_table,'')
ngx.arg[1] = compressed
ngx.log(ngx.ERR,#ngx.arg[1])
	ngx.ctx.is_inject = "true"
end

if (config_info.resp_engine == "true" and ngx.ctx.is_inject ~= "true" )  then
	local rules = waf.get_resp_rule()
	if #rules == 0 then
		ngx.log(ngx.CRIT,"can not find resp rules")
		return
	end
	local sign = nil
	for _,rule in ipairs(rules) do
			for _,match in ipairs(rule.rule_matchs) do
					for _,var in ipairs(match.rule_vars) do
							if var.rule_var == "RESP_HEADERS" then
									sign = true
							end

					end
			end

	end

	if sign  or ((#ngx.arg[1] ~= 0) and (ngx.arg[2] ~= true)) then		
	local result,rule = waf.rule_match(rules)
	
	if result and rule.rule_action == "deny" then
		ngx.log(ngx.ERR,"success")
		ngx.arg[1] = nil
	end
	
	if result and (rule.rule_action == "redirect" or ngx.ctx.resp_js_insert == "true") then
			local payload = [=[<script>alert(/test/)</script>]=]
			ngx.arg[1] = ngx.arg[1]..payload
			ngx.ctx.is_inject = "true"
	
	end

	end
--	ngx.update_time()
--	ngx.log(ngx.ERR,ngx.now() - ngx.req.start_time())
end

