local cjson = require "cjson.safe"
local request = require "resty.jxwaf.request"
local transform = require "resty.jxwaf.transform"
local operator = require "resty.jxwaf.operator"
local resty_random = require "resty.random"
local str = require "resty.string"
local pairs = pairs
local ipairs = ipairs
local table_insert = table.insert
local table_sort = table.sort
local table_concat = table.concat
local http = require "resty.jxwaf.http"
local upload = require "resty.upload"
local _M = {}
_M.version = "1.0"


local _config_path = "/opt/jxwaf/nginx/conf/jxwaf/jxwaf_config.json"
local _config_info = {}
local _rules = {}
local _resp_rules = {}
local _resp_header_chunk = nil
local function _sort_rules(a,b)
        return tonumber(a.rule_id)<tonumber(b.rule_id)
end


local function _process_request(var,otp)
	local t = request.request[var.rule_var]()
	if type(t) ~= "string" and type(t) ~= "table" then
		ngx.log(ngx.ERR,"run fail,can not decode http args ",type(t).."   "..var.rule_var)
		ngx.log(ngx.ERR,ngx.req.raw_header())
		ngx.exit(500)
	end
	if type(t) == "string" then
		return t
	end
	
	local rule_var = var.rule_var

	if (rule_var == "ARGS" or rule_var == "ARGS_GET" or rule_var == "ARGS_POST" or rule_var == "REQUEST_COOKIES" or rule_var == "REQUEST_HEADERS" or rule_var == "RESP_HEADERS" ) then
		
	
		if( type(var.rule_specific) == "table" ) then
			local specific_result = {}
			for _,v in ipairs(var.rule_specific) do
				local specific = t[v]
				if specific ~= nil then
					
					specific_result[v] = specific
				end
			end
			
			
			return specific_result
		end
		
		if( type(var.rule_ignore) == "table" ) then
			local ignore_result = {}
			ignore_result = t
			for _,v in ipairs(var.rule_ignore) do
				ignore_result[string.lower(v)] = nil
			end
			
			return ignore_result
 
		
		end				
				
	end
	
	return t
end



function _M.process_request(var)

	return _process_request(var)
end



local function _process_transform(process_request,rule_transform,var)
        if type(process_request) ~= "string" and type(process_request) ~= "table" then
                ngx.log(ngx.ERR,"run fail,can not transfrom http args")
                ngx.exit(500)
        end

	if  type(rule_transform) ~= "table" then
                ngx.log(ngx.ERR,"run fail,can not decode config file,transfrom error")
                ngx.exit(500)
        end

	if type(process_request) == "string" then
		local string_result = process_request
		for _,v in ipairs(rule_transform) do
			string_result = transform.request[v](string_result)				
		end
		return 	string_result
	end

	local result = {}
	local rule_var = var.rule_var
	if (rule_var == "ARGS" or rule_var == "ARGS_GET" or rule_var == "ARGS_POST" or rule_var == "REQUEST_COOKIES" or rule_var == "REQUEST_HEADERS" or rule_var == "RESP_HEADERS") then
		for k,v in pairs(process_request) do
                        if type(v) == "table" then
				local _result_table = {}
                                for _,_v in ipairs(v) do
					local _result = _v
                                        for _,__v in ipairs(rule_transform) do
                                                _result = transform.request[__v](_result)
                                        end 
					if type(_result) == "string" then
						table_insert(_result_table,_result)
					end
                                end
				result[k] = _result_table

                        else
				local _result = v
                                for _,_v in ipairs(rule_transform) do
		
                                        _result = transform.request[_v](_result)
                                end
				if type(_result) == "string" then
					result[k] = _result
				end
                        end
                end
	else
		for _,v in ipairs(process_request) do
			local _result = v
			for _,_v in ipairs(rule_transform) do
		
				_result = transform.request[_v](_result)
			end

			if type(_result) == "string" then
				table_insert(result,_result)
			end
		end
	end

	return result 

end


local function _process_operator( process_transform , match , var , rule )
	local rule_operator = match.rule_operator
	local rule_pattern = match.rule_pattern
	local rule_negated = match.rule_negated
	local rule_var = var.rule_var
	if type(process_transform) ~= "string" and type(process_transform) ~= "table" then
		ngx.log(ngx.ERR,"run fail,can not operator http args")
                ngx.exit(500)
        end
	if type(rule_operator) ~= "string" and type(rule_pattern) ~= "string" then
		ngx.log(ngx.ERR,"rule_operator and rule_pattern error")
		ngx.exit(500)
	end
	
	if type(process_transform) == "string" then
		local result ,value,captures
		result,value,captures = operator.request[rule_operator](process_transform,rule_pattern)
		if rule_negated == "true" then
			result = not result
		end

		if result  then
			return result,value,rule_var,captures
		else
			return result
		end

	end
	
 
	if (rule_var == "ARGS" or rule_var == "ARGS_GET" or rule_var == "ARGS_POST" or rule_var == "REQUEST_COOKIES" or rule_var == "REQUEST_HEADERS" or rule_var == "RESP_HEADERS") then
		for k,v in pairs(process_transform) do
			if type(v) == "table" then
				for _,_v in ipairs(v) do
					local result,value,captures
					result,value,captures = operator.request[rule_operator](_v,rule_pattern)	
					if rule_negated == "true" then
						result = not result
					end
					if result  then
						return result,value,k,captures
					end
				end
			else
				local result,value,captures
				result,value,captures = operator.request[rule_operator](v,rule_pattern) 
                                if rule_negated == "true" then
                                	result = not result
                                end
			
                                if result  then
                                	return result,value,k,captures
                                end
			end
		end	
	
	else
		for _,v in ipairs(process_transform) do
			local result,value,captures
			result,value,captures = operator.request[rule_operator](v,rule_pattern)
			if rule_negated == "true" then
				result = not result
			end

			if result  then
				return result,value,rule_var,captures
			end


		end


	end


	return false

end



local function _rule_match(rules)
	local result
	ngx.ctx.rule_observ_log = {}
	for _,rule in ipairs(rules) do
		
	
			local matchs_result = true
			local ctx_rule_log = {}
			for _,match in ipairs(rule.rule_matchs) do
				local operator_result = false
			
				for _,var in ipairs(match.rule_vars) do
					local process_request = _process_request(var)
					local process_transform = _process_transform(process_request,match.rule_transform,var)
					local _operator_result,_operator_value,_operator_key,captures = _process_operator(process_transform,match,var,rule)
					
					if _operator_result and rule.rule_log == "true" then
                                                ctx_rule_log.rule_var = var.rule_var
                                                ctx_rule_log.rule_operator = match.rule_operator
                                                ctx_rule_log.rule_negated = match.rule_negated
                                                ctx_rule_log.rule_transform = match.rule_transform
												if ngx.get_phase() == "body_filter" then
													ctx_rule_log.rule_match_var = var.rule_var
												else
													ctx_rule_log.rule_match_var = _operator_value
												
												end
						
						
                                                ctx_rule_log.rule_match_key = _operator_key
						ctx_rule_log.rule_uri = ngx.var.uri
						ctx_rule_log.rule_remote_ip = ngx.var.remote_addr
						ctx_rule_log.rule_match_captures = captures

					end
		
                                	if  _operator_result then
						operator_result = _operator_result
						break
                                	end
				end	
		
				if (not operator_result) then
					matchs_result = false
					break
				end
				
			     end
                if matchs_result and rule.rule_log == "true" then                       
                    ctx_rule_log.rule_id = rule.rule_id
                    ctx_rule_log.rule_detail = rule.rule_detail
                    ctx_rule_log.rule_serverity = rule.rule_serverity
                    ctx_rule_log.rule_category = rule.rule_category
                    ctx_rule_log.rule_action = rule.rule_action
					if _config_info.log_all == "true" or rule.rule_log_all=="true" then
						ctx_rule_log.rule_raw_headers =  request.request['REQUEST_HEADERS']()
						ctx_rule_log.rule_url = request.request['REQUEST_URI']()
						ctx_rule_log.rule_raw_post =  ngx.req.get_body_data()
					end
					ngx.ctx.rule_log = ctx_rule_log
				end
				if _config_info.observ_mode == "true" and matchs_result and rule.rule_log == "true" then
				
				
						table_insert(ngx.ctx.rule_observ_log,ctx_rule_log)
						matchs_result = false
		
				end
	
                if rule.rule_action == "pass" and matchs_result then
					matchs_result = false
				end
		
			
			if matchs_result then
				return matchs_result,rule
			end
		end

	return result
end


function _M.rule_match(rules)

	return _rule_match(rules)

end


      

local function _base_update_rule()
	local _base_update_rule = {}
	local _resp_update_rule = {}
	local _update_website  =  _config_info.base_rule_update_website or "http://update.jxwaf.com/waf/update_rule"		
	local httpc = http.new()
	local api_key = _config_info.waf_api_key or "jxwaf"
      	local res, err = httpc:request_uri( _update_website , {
           method = "POST",
           body = "api_key="..api_key,
           headers = {
            ["Content-Type"] = "application/x-www-form-urlencoded",
           }
      	})
	if not res then
        	ngx.log(ngx.ERR,"failed to request: ", err)
		return
      	end
	
	local read_body = res.body

	
	
		
	local _update_rule = cjson.decode(read_body)
	if _update_rule == nil or #_update_rule == 0 then
		ngx.log(ngx.ERR,"init fail,can not decode base rule config file")
	end
	for _,v in ipairs(_update_rule) do
		if v.rule_phase == "resp" then
			table_insert(_resp_update_rule,v)
			if v.rule_action == "inject_js" or v.rule_action == "rewrite" or v.rule_action == "replace" then
				_resp_header_chunk = true
			end
		else
			table_insert(_base_update_rule,v)
		end
	end	
	table_sort(_resp_update_rule,_sort_rules)
	table_sort(_base_update_rule,_sort_rules)
	_rules =  _base_update_rule
	_resp_rules = _resp_update_rule
	ngx.log(ngx.ALERT,"success load base rule,count is "..#_rules)
	ngx.log(ngx.ALERT,"success load resp rule,count is "..#_resp_rules)
	

	
end

local function _global_update_rule()
      
        local _update_website  =  _config_info.global_rule_update_website or "http://update.jxwaf.com/waf/update_global_rule"
        local httpc = http.new()
        local api_key = _config_info.waf_api_key or "jxwaf"
        local res, err = httpc:request_uri( _update_website , {
	
           method = "POST",
           body = "api_key="..api_key,
           headers = {
            ["Content-Type"] = "application/x-www-form-urlencoded",
           }
        })
        if not res then
                ngx.log(ngx.ERR,"failed to request: ", err)
                return
        end
	local read_body = res.body
	
        local _update_rule = cjson.decode(read_body)
	
        if _update_rule == nil  then
               ngx.log(ngx.ERR,"init fail,can not decode remote global rule")
        end
	_config_info.base_engine = _config_info.base_engine or _update_rule['base_engine'] or "true"
	_config_info.log_all = _config_info.log_all or  _update_rule['log_all'] or "false"
	_config_info.log_remote = _config_info.log_remote or  _update_rule['log_remote'] or "false"
	_config_info.log_local = _config_info.log_local or  _update_rule['log_local'] or "true"
	_config_info.http_redirect = _config_info.http_redirect or  _update_rule['http_redirect'] or "/"
	_config_info.log_ip = _config_info.log_ip or  _update_rule['log_ip'] or "127.0.0.1"
	_config_info.log_port = _config_info.log_port or  _update_rule['log_port'] or "5555"
	_config_info.log_sock_type = _config_info.log_sock_type or  _update_rule['log_sock_type'] or "udp"
	_config_info.log_flush_limit = _config_info.log_flush_limit or  _update_rule['log_flush_limit'] or "1"
	_config_info.cookie_safe = _config_info.cookie_safe or _update_rule['cookie_safe'] or "true"
	_config_info.cookie_safe_client_ip = _config_info.cookie_safe_client_ip or _update_rule['cookie_safe_client_ip'] or "true"
	_config_info.cookie_safe_is_safe = _config_info.cookie_safe_is_safe or _update_rule['cookie_safe_is_safe'] or "false"	
	_config_info.aes_random_key = _config_info.aes_random_key or _update_rule['aes_random_key'] or  str.to_hex(resty_random.bytes(8))
	_config_info.observ_mode =  _config_info.observ_mode or _update_rule['observ_mode'] or "false"
	--_config_info.observ_mode_white_ip =  _config_info.observ_mode_white_ip or _update_rule['observ_mode_white_ip'] or "false"
	_config_info.resp_engine =  _config_info.resp_engine or _update_rule['resp_engine'] or "false"
        ngx.log(ngx.ALERT,"success load global config ",_config_info.base_engine)
	if _config_info.base_engine == "true" or _config_info.resp_engine == "true" then
		_base_update_rule()
	end
	
end



function _M.init_worker()
	local global_ok, global_err = ngx.timer.at(0,_global_update_rule)
	if not global_ok then
                ngx.log(ngx.ERR, "failed to create the global timer: ", global_err)
        end

end


function _M.init(config_path)
	local init_config_path = config_path or _config_path
	local read_config = assert(io.open(init_config_path,'r'))
	local raw_config_info = read_config:read('*all')
	read_config:close()
	local config_info = cjson.decode(raw_config_info)
	if config_info == nil then
		ngx.log(ngx.ERR,"init fail,can not decode config file")
	end

	_config_info = config_info


end


function _M.get_config_info()
	
	local config_info = _config_info

	return config_info

end

function _M.get_resp_rule()

	return  _resp_rules

end

function _M.base_check()
	if _config_info.base_engine == "true" then
	local rules = _rules
	if  #rules == 0 then
		ngx.log(ngx.CRIT,"can not find rules")
		return
	--	ngx.exit(500)	
	end
	local result,rule = _rule_match(rules)	
	
	if result then
		if rule.rule_action == 'deny' then
			ngx.exit(403)
		elseif rule.rule_action == 'allow' then
			ngx.exit(0)
		elseif rule.rule_action == 'redirect' then
			ngx.redirect(_config_info.http_redirect)
		elseif rule.rule_action == 'rewrite' then
--			ngx.ctx.resp_action = "rewrite"
--			ngx.ctx.resp_rewrite_data = rule.rule_action_data
			ngx.header["Content-Type"] = "text/html; charset=utf-8"
			ngx.say(ngx.decode_base64(rule.rule_action_data))		
		elseif rule.rule_action == 'inject_js' then
			ngx.ctx.resp_action = "inject_js"
			ngx.ctx.resp_inject_js_data = rule.rule_action_data
		elseif rule.rule_action == "replace" then
			ngx.ctx.resp_action = "replace"
			ngx.ctx.resp_replace_check = rule.rule_action_data
			ngx.ctx.resp_replace_data = rule.rule_action_replace_data
		else
			ngx.log(ngx.ERR,"rule action ERR!")
		end
	end

	end
end


function _M.access_init()
	local content_type = ngx.req.get_headers()["Content-type"]
	if content_type and  ngx.re.find(content_type, [=[^multipart/form-data]=],"oij") and tonumber(ngx.req.get_headers()["Content-Length"]) ~= 0 then
		local form, err = upload:new()
		local _file_name = {}
		local _form_name = {}
		local _file_type = {}
		local t ={}
		local _type_flag = "false"
		if not form then
			ngx.log(ngx.ERR, "failed to new upload: ", err)
			ngx.exit(500)	
		end
		ngx.req.init_body()
		ngx.req.append_body("--" .. form.boundary)
		local lasttype, chunk
		local count = 0
		while true do
			count = count + 1
			local typ, res, err = form:read()
                if not typ then
                    ngx.say("failed to read: ", err)
                	return nil
                end
				if typ == "header" then
				--	chunk = res[3]
				--	ngx.req.append_body("\r\n" .. chunk)
                    if res[1] == "Content-Disposition" then
                    	local _tmp_form_name = ngx.re.match(res[2],[=[(.+)\bname=[" ']*?([^"]+)[" ']*?]=],"oij")
						local _tmp_file_name =  ngx.re.match(res[2],[=[(.+)filename=[" ']*?([^"]+)[" ']*?]=],"oij")
                    	if _tmp_form_name  then
                        	table.insert(_form_name,_tmp_form_name[2]..count)
						end
						if _tmp_file_name  then
							table.insert(_file_name,_tmp_file_name[2])
						end
						if _tmp_form_name and _tmp_file_name then
							chunk = string.format([=[Content-Disposition: form-data; name="%s"; filename="%s"]=],_tmp_form_name[2],_tmp_file_name[2])
							ngx.req.append_body("\r\n" .. chunk)
						elseif _tmp_form_name then
							chunk = string.format([=[Content-Disposition: form-data; name="%s"]=],_tmp_form_name[2])
							 ngx.req.append_body("\r\n" .. chunk)
						else
							ngx.log(ngx.ERR,"Content-Disposition ERR!")
							ngx.exit(503)
						end

                	end
                	if res[1] == "Content-Type" then
                    	table.insert(_file_type,res[2])
						_type_flag = "true"
						chunk = string.format([=[Content-Type: %s]=],res[2])
						ngx.req.append_body("\r\n" .. chunk)
                	end
            	end
				if typ == "body" then
					chunk = res
					if lasttype == "header" then
						ngx.req.append_body("\r\n\r\n")
					end
					ngx.req.append_body(chunk)
                    if _type_flag == "true" then
                        _type_flag = "false"
						t[_form_name[#_form_name]] = ""
					else
						if lasttype == "header" then
							t[_form_name[#_form_name]] = res
						else
							t[_form_name[#_form_name]] = ""
						end
                    end
				end
				if typ == "part_end" then 
					ngx.req.append_body("\r\n--" .. form.boundary)
				end
				if typ == "eof" then
					ngx.req.append_body("--\r\n")
                    break
				end
				lasttype = typ
		end
		form:read()
		ngx.req.finish_body()
		ngx.ctx.form_post_args = t
		ngx.ctx.form_file_name = _file_name
		ngx.ctx.form_file_type = _file_type
	else
		ngx.req.read_body()
	end
end

function _M.resp_header_chunk()
	return _resp_header_chunk
end

return _M
