local waf = require "resty.jxwaf.waf"
local config_info = waf.get_config_info()
local request = require "resty.jxwaf.request"
local zlib = require "resty.jxwaf.ffi-zlib"


local function zlib_compress(input_data)
	local _input_data = input_data
	local count = 0 
	local input = function(bufsize)
 		local start = count > 0 and bufsize*count or 1
		local data = _input_data:sub(start, (bufsize*(count+1)-1))
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
	return compressed
end

local Content_Disposition = ngx.resp.get_headers()['Content-Disposition']
local Content_Encoding = ngx.resp.get_headers()["Content-Encoding"]
local Content_Type = ngx.resp.get_headers()['Content-Type']
if Content_Type then
local check_content_type = ngx.re.find(Content_Type, [=[text|json|xml|javascript]=],"oij") 
end

if  (not ngx.ctx.is_resp_action) and ngx.ctx.resp_action and (not Content_Disposition) and check_content_type and (ngx.arg[2] ~= true)  and (#ngx.arg[1] ~= 0) then
	local resp_raw_data = request.request['RESP_BODY']()
	local resp_data = nil
	if ngx.ctx.resp_action == 'rewrite' then
		resp_data = ngx.ctx.resp_rewrite_data
		ngx.ctx.is_resp_action = true
	elseif ngx.ctx.resp_action == 'inject_js' then
		resp_data = resp_raw_data..ngx.ctx.resp_inject_js_data
		ngx.ctx.is_resp_action = true
	elseif ngx.ctx.resp_action == "replace" then
		resp_data = ngx.re.gsub(resp_raw_data,ngx.ctx.resp_replace_check,ngx.ctx.resp_replace_data)
		ngx.ctx.is_resp_action_replace = true
	else
		ngx.log(ngx.ERR,"rule action ERR!,in resp!")

	end

	if Content_Encoding and ngx.re.find(Content_Encoding, [=[gzip]=],"oij") then
		local compressed = zlib_compress(resp_data)
		ngx.arg[1] = compressed
	else
		ngx.arg[1] = resp_data
	end	

end

if (config_info.resp_engine == "true") and (not ngx.ctx.is_resp_action) and (not ngx.ctx.is_resp_action_replace)   then
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

	if sign  or ((#ngx.arg[1] ~= 0) and (ngx.arg[2] ~= true) and (not Content_Disposition) and check_content_type) then	
			
		local result,rule = waf.rule_match(rules)
		if result then
		local resp_raw_data = request.request['RESP_BODY']()
                local resp_data = nil
                if rule.rule_action == 'deny' then
                        ngx.arg[1] = nil
			ngx.arg[2] = true 
                elseif rule.rule_action == 'rewrite' then
                        resp_data = ngx.decode_base64(rule.rule_action_data)
			ngx.ctx.is_resp_action = true
                elseif rule.rule_action == 'inject_js' then
                        resp_data = resp_raw_data..rule.rule_action_data
                	ngx.ctx.is_resp_action = true
                elseif rule.rule_action == "replace" then
                        resp_data = ngx.re.gsub(resp_raw_data,rule.rule_action_data,rule.rule_action_replace_data)
                else
                        ngx.log(ngx.ERR,"rule action ERR!,in resp!!")
                end

		if Content_Encoding and ngx.re.find(Content_Encoding, [=[gzip]=],"oij") then
                	local compressed = zlib_compress(resp_data)
                	ngx.arg[1] = compressed
        	else
                	ngx.arg[1] = resp_data
       	 	end

        	end


	end

end


