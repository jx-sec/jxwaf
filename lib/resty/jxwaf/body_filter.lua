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

local function get_resp_body()
	local data = ""
	local args = ngx.arg[1]
	if args ~= nil then
		local Content_Encoding = ngx.resp.get_headers()["Content-Encoding"]
		if Content_Encoding and ngx.re.find(Content_Encoding, [=[gzip]=],"oij") then
                        local count = 0
                        local output_table = {}
                        local input = function(bufsize)
                                local start = count > 0 and bufsize*count or 1
                                local data = args:sub(start, (bufsize*(count+1)-1) )
                                count = count + 1
                                return data
                        end
                        local output = function(data)
                            table.insert(output_table, data)
                        end
                        local chunk = 16384
                        local ok, err = zlib.inflateGzip(input, output, chunk)
                        if not ok then
			    ngx.log(ngx.ERR,err)
			    data = args
			else
                            local output_data = table.concat(output_table,'')
			    data = output_data
			end
			
		else
			data = args
		end
	end
	return data
end

local Content_Disposition = ngx.resp.get_headers()['Content-Disposition']
local Content_Encoding = ngx.resp.get_headers()["Content-Encoding"]
local Content_Type = ngx.resp.get_headers()['Content-Type']
local check_content_type 
if Content_Type then
	check_content_type = ngx.re.find(Content_Type, [=[text|json|xml|javascript]=],"oij") 
end




if  ngx.ctx.response_data_replace_match and ngx.ctx.response_data_replace_data and (not Content_Disposition) and check_content_type and (ngx.arg[2] ~= true)  and  ngx.arg[1] and (#ngx.arg[1] > 0) then
    local resp_raw_data = get_resp_body()
    local replace_resp_data = ngx.re.gsub(resp_raw_data,ngx.ctx.response_data_replace_match,ngx.ctx.response_data_replace_data)
    if replace_resp_data then
	    if Content_Encoding and ngx.re.find(Content_Encoding, [=[gzip]=],"oij") then
		    local compressed = zlib_compress(replace_resp_data)
		    ngx.arg[1] = compressed
	    else
		    ngx.arg[1] = replace_resp_data
	    end	
    end
end

