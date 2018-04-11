local ck = require "resty.jxwaf.cookie"
local waf = require "resty.jxwaf.waf"
local aes = require "resty.aes"
local str = require "resty.string"
local _M = {}
_M.version = "1.0"

local function hexstr2bin( hexstr )  
    local h2b = {
    ["0"] = 0,
    ["1"] = 1,
    ["2"] = 2,
    ["3"] = 3,
    ["4"] = 4,
    ["5"] = 5,
    ["6"] = 6,
    ["7"] = 7,
    ["8"] = 8,
    ["9"] = 9,
    ["a"] = 10,
    ["b"] = 11,
    ["c"] = 12,
    ["d"] = 13,
    ["e"] = 14,
    ["f"] = 15
    }

    
local s = string.gsub(hexstr, "(.)(.)", 
function ( h, l ) 
                 if  h2b[h] and h2b[l] then
 return string.char(h2b[h]*16+h2b[l]) end end)
    return s  
end  

local function _aes_ck()
	local config_info = waf.get_config_info()

	if config_info.cookie_safe == "true" then
		local new_cookie = {}
		local aes_key
		local aes_random_key = config_info.aes_random_key 
		
		if config_info.cookie_safe_client_ip == "true" then
			aes_key = aes_random_key..ngx.var.remote_addr
		
		else
			aes_key = aes_random_key
		end
		local cookie,err = ck:new()
		if not cookie then
	
			return
		end
		local fields,err = cookie:get_all()
		if not fields then
	
			return
		end
	
		local aes_init = aes:new(aes_key,nil,aes.cipher(256,"ecb"),aes.hash.sha1)
		if config_info.cookie_safe_is_safe == "true" then
			
			for k,v in pairs(fields) do
		--		local key = aes_init:decrypt(hexstr2bin(k))
				local key = k
				local value = aes_init:decrypt(hexstr2bin(v))
		
				if key and value then
					table.insert(new_cookie,key.."="..value)		
				end						
			end
			
		else
			 for k,v in pairs(fields) do
                --              local key = aes_init:decrypt(hexstr2bin(k))
                		local key = k
                                local value = aes_init:decrypt(hexstr2bin(v))

				 
                                if key and value then
                                        table.insert(new_cookie,key.."="..value)             
				else

					table.insert(new_cookie,k.."="..v)  
                                end                                             
                        end
		
			
		end
		
		 ngx.req.set_header("Cookie", table.concat(new_cookie,";"))
--		 ngx.log(ngx.ERR, ngx.req.get_headers()['Cookie'])

	end
end

function _M.aes_ck()
 
	return _aes_ck()
end



local function trim( value)
   return ngx.re.gsub(value, [=[^\s*|\s+$]=], '')
end
 
local function split( str,reps )
    local resultStrList = {}
    string.gsub(str,'[^'..reps..']+',function ( w )
        table.insert(resultStrList,w)
    end)
    return resultStrList
end




local function _resp_aes_ck()
	local config_info = waf.get_config_info()
	if config_info.cookie_safe == "true" then
                local new_cookie = {}
                local aes_key
                local aes_random_key = config_info.aes_random_key

                if config_info.cookie_safe_client_ip == "true" then
                        aes_key = aes_random_key..ngx.var.remote_addr
		else
                        aes_key = aes_random_key
                end
		local _resp_cookie = ngx.resp.get_headers()['Set-Cookie']
		local resp_cookie = {}
		
		if type(_resp_cookie) == "table" then
			for _,v in ipairs(_resp_cookie) do
				string.gsub(v,'[^'..";"..']+',function ( w )
					table.insert(resp_cookie,w)
 				end)
			end
		elseif type(_resp_cookie) == "string" then
			resp_cookie = split(_resp_cookie,";") 
		else
			return
		end
		local aes_init = aes:new(aes_key,nil,aes.cipher(256,"ecb"),aes.hash.sha1)
		local tmp_result = {}
		for k,v in pairs(resp_cookie) do
			local _tmp = split(v,"=")
			local _tmp_result = {}

			for _k,_v in ipairs(_tmp) do
				        local value = _v
                                        local lower_value = string.lower(trim(value))
					if _k == 1 then

						if lower_value == "expires" or lower_value == "max-age" or lower_value == "domain" or lower_value == "path" or lower_value == "secure" or lower_value == "httponly" or lower_value == "sameSite" then
							table.insert(_tmp_result,value)
						else
							break
						end
							
					else  

							table.insert(_tmp_result,value)
					end
			end

			for _k,_v in ipairs(_tmp)do
					local value = trim(_v)
					local lower_value = string.lower(value)

					if _k == 1 then
						if lower_value == "expires" or lower_value == "max-age" or lower_value == "domain" or lower_value == "path" or lower_value == "secure" or lower_value == "httponly" or lower_value == "sameSite" then
						
							break
						else
						
							
					--		table.insert(_tmp_result,str.to_hex(aes_init:encrypt(value)))
							table.insert(_tmp_result,value)
						end
					else
					
						table.insert(_tmp_result,str.to_hex(aes_init:encrypt(value)))
					end	


			end
			


			table.insert(tmp_result,table.concat(_tmp_result,"="))
		end
		ngx.header['Set-Cookie'] = table.concat(tmp_result,";")
		


	end




end





function _M.resp_aes_ck()

        return _resp_aes_ck()
end








return _M
