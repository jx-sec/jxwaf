
local function body_filter_exec()
    local Content_Disposition = ngx.resp.get_headers()['Content-Disposition']
    local Content_Type = ngx.resp.get_headers()['Content-Type']
    local check_content_type 
    if Content_Type then
        check_content_type = ngx.re.find(Content_Type, [=[text|json|xml|javascript]=],"oij") 
    end
    if  ngx.ctx.response_data_replace_match and ngx.ctx.response_data_replace_data and (not Content_Disposition) and check_content_type and (ngx.arg[2] ~= true)  and  ngx.arg[1] and (#ngx.arg[1] > 0) then
        local resp_raw_data = ngx.arg[1]
        local replace_resp_data = ngx.re.gsub(resp_raw_data,ngx.ctx.response_data_replace_match,ngx.ctx.response_data_replace_data)
        if replace_resp_data then
            ngx.arg[1] = replace_resp_data
        end
    end
end

local body_filter_exec_result,body_filter_exec_error = pcall(body_filter_exec)
if not body_filter_exec_result then
  ngx.log(ngx.ERR,body_filter_exec_error)
end