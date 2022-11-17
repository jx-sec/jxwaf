

if ngx.ctx.response_header_replace_data then
    local response_header_replace_data = ngx.ctx.response_header_replace_data
    for k,v in pairs(response_header_replace_data) do
        local header_key = k
        local replace_match = v['replace_match'] 
        local replace_data = v['replace_data']
        local header_value =ngx.header[header_key]
        if header_value then
          local replace_string = ngx.re.gsub(header_value,replace_match,replace_data)
            if replace_string then 
                ngx.header[header_key] = replace_string
            end
        end
    end
end



if ngx.ctx.response_data_replace_match then
    ngx.header.content_length = nil
end
