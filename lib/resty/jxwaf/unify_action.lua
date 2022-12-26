local http = require "resty.jxwaf.http"
local table_insert = table.insert
local table_concat = table.concat
local request = require "resty.jxwaf.request" 
local cjson = require "cjson.safe"
local _M = {}
_M.version = "20220831"


local function _add_name_list_item(period,name_list_uuid,name_list_item,extra)
    local waf_name_list_item_website = extra['waf_add_name_list_item_website']
    local api_key = extra['waf_api_key'] or ""
    local api_password = extra['waf_api_password'] or ""
    local httpc = http.new()
    local send_body  = {}
    send_body['api_key'] = api_key
    send_body['api_password'] = api_password
    send_body['name_list_uuid'] = name_list_uuid
    send_body['name_list_item'] = name_list_item
    local res, err = httpc:request_uri( waf_name_list_item_website , {
      method = "POST",
      body = cjson.encode(send_body),
    })
    if not res then
      ngx.log(ngx.ERR,"send http failed to request: ", err)
    end
    local res_body = cjson.decode(res.body)
    if not res_body then
      ngx.log(ngx.ERR,"send http init fail,failed to decode resp body " )
    end
end


function _M.add_name_list_item(name_list_uuid,name_list_data,extra,name_list_item)
    local jxwaf_suppression = ngx.shared.jxwaf_suppression
    local name_list_conf = name_list_data[name_list_uuid]
    if name_list_conf  then
      local repeated_writing_suppression = name_list_conf['repeated_writing_suppression']
      if name_list_item then
        local suppression_key = name_list_uuid..name_list_item
        local suppression_result = jxwaf_suppression:get(suppression_key)
        if not suppression_result then
          local ok, err = ngx.timer.at(0,_add_name_list_item,name_list_uuid,name_list_item,extra)
          if not ok then
            if err ~= "process exiting" then
              ngx.log(ngx.ERR, "failed to create the send add_name_list_item http timer: ", err)
            end
          end
          jxwaf_suppression:set(suppression_key,true,tonumber(repeated_writing_suppression))
        end
      else
        local name_list_rule = name_list_conf['name_list_rule']
        local item_value_table = {}
        local nil_exist 
        for _,rule in ipairs(name_list_rule) do
          local key = rule['key']
          local value = rule['value']
          local return_value = request.get_args(key,value)
          if type(return_value) == "string" then
            table_insert(item_value_table,return_value)
          else
            nil_exist = true
            break
          end
        end
        if not nil_exist then
          local item_value = table_concat(item_value_table)
          local suppression_key = name_list_uuid..item_value
          local suppression_result = jxwaf_suppression:get(suppression_key)
          if not suppression_result then
            local ok, err = ngx.timer.at(0,_add_name_list_item,name_list_uuid,item_value,extra)
            if not ok then
              if err ~= "process exiting" then
                ngx.log(ngx.ERR, "failed to create the send add_name_list_item http timer: ", err)
              end
            end
            jxwaf_suppression:set(suppression_key,true,tonumber(repeated_writing_suppression))
          end
        end
      end
    end
end


function _M.add_shared_dict_key(shared_dict_uuid,sys_shared_dict_data)
  local jxwaf_public = ngx.shared.jxwaf_public
  local shared_dict_data = sys_shared_dict_data[shared_dict_uuid]
  if not shared_dict_data then
    return
  end
  local shared_dict_key =  shared_dict_data['shared_dict_key']
  local shared_dict_type = shared_dict_data['shared_dict_type']
  local shared_dict_expire_time = shared_dict_data['shared_dict_expire_time']
  local shared_dict_key_value = {}
  table_insert(shared_dict_key_value,shared_dict_uuid)
  for _,rule in ipairs(shared_dict_key) do
    local key = rule['key']
    local value = rule['value']
    local return_value = request.get_args(key,value)
    if type(return_value) == "string" then
      table_insert(shared_dict_key_value,return_value)
    else
      return  
    end
  end
  local set_value = table_concat(shared_dict_key_value)
  if shared_dict_type == "string"  then
    jxwaf_public:set(set_value,"true",tonumber(shared_dict_expire_time))
  elseif shared_dict_type == "number" then
    jxwaf_public:incr(set_value,1,0,tonumber(shared_dict_expire_time))
  end
  return true
end



function _M.block(page_conf)
  local code = page_conf['code']
  local html = page_conf['html']
  if html and #html > 0 then
    ngx.status = tonumber(code)
    ngx.header.content_type = "text/html;charset=utf-8"
    ngx.header.request_id = ngx.ctx.request_uuid
    ngx.say(html)
  end
  if code then
      return ngx.exit(tonumber(code))
  else
      return ngx.exit(404)
  end
end

function _M.allow()
  return ngx.exit(0)
end

function _M.reject_response()
  return ngx.exit(444)
end

--[[
function _M.mimetic_defense(mimetic_defense_conf)
  if mimetic_defense_conf and mimetic_defense_conf['mimetic_defense'] == "true"  then
    ngx.req.set_header("X-Forwarded-Proto", ngx.var.scheme)
    ngx.req.set_header("X-Forwarded-Host", ngx.var.http_host)
    ngx.req.set_header("X-Forwarded-Port", ngx.var.server_port)
    ngx.req.set_header("X-Cmd-Token", mimetic_defense_conf['token'])
    ngx.req.set_header("Host", nil)
    ngx.ctx.mimetic_defense_conf = mimetic_defense_conf
    ngx.exit(0)
  end
end
--]]

function _M.custom_response(custom_response_conf)
  if custom_response_conf   then
    local set_response_header_status = custom_response_conf['set_response_header_status']
    local set_response_header_value = custom_response_conf['set_response_header_value']
    local return_code = custom_response_conf['return_code']
    local return_html = custom_response_conf['return_html']
    if set_response_header_status == 'true' then
      for _,v in ipairs(set_response_header_value) do
        ngx.header[v['key']] = v['value']
      end
    end
    ngx.status = tonumber(return_code)
    ngx.say(return_html)
  end
end

function _M.request_replace(request_replace_conf)
  if request_replace_conf   then
    local get_status = request_replace_conf['get_status']
    local get_replace_match = request_replace_conf['get_replace_match']
    local get_replace_data = request_replace_conf['get_replace_data']
    local header_status = request_replace_conf['header_status']
    local header_replace_data = request_replace_conf['header_replace_data']
    local post_status = request_replace_conf['post_status']
    local post_replace_match = request_replace_conf['post_replace_match']
    local post_replace_data = request_replace_conf['post_replace_data']
    if get_status == 'true' then
      local encode_args = ngx.encode_args(ngx.req.get_uri_args())
      local replace_string = ngx.re.gsub(encode_args,get_replace_match,get_replace_data)
      if replace_string then
        ngx.req.set_uri_args(replace_string)
      end
    end
    if header_status == 'true' then
      for k,v in pairs(header_replace_data) do
        local header_key = k
        local replace_match = v['replace_match'] 
        local replace_data = v['replace_data']
        local header_value = ngx.req.get_headers()[header_key]
        if header_value then
          local replace_string = ngx.re.gsub(header_value,replace_match,replace_data)
           if replace_string then
                ngx.req.set_header(header_key, replace_string)
           end
        end
      end
    end
    if post_status == 'true' then
      ngx.req.read_body()
      local data = ngx.req.get_body_data()
      if data then
        local replace_string = ngx.re.gsub(data,post_replace_match,post_replace_data)
        if replace_string then
          ngx.req.set_body_data(replace_string)
        end
      end
    end
  end
end

function _M.response_replace(response_replace_conf)
  if response_replace_conf then
    local response_header_status = response_replace_conf['response_header_status']
    local response_header_replace_data = response_replace_conf['response_header_replace_data']
    local response_data_status = response_replace_conf['response_data_status']
    local response_data_replace_match = response_replace_conf['response_data_replace_match']
    local response_data_replace_data = response_replace_conf['response_data_replace_data']
    if response_header_status == "true" then
      ngx.ctx.response_header_replace_data = response_header_replace_data
    end

    if response_data_status == "true" then
      ngx.req.clear_header('Accept-Encoding')
      ngx.ctx.response_data_replace_match = response_data_replace_match
      ngx.ctx.response_data_replace_data = response_data_replace_data
    end
  end
end

function _M.traffic_forward(traffic_forward_conf)
  if traffic_forward_conf   then
    local traffic_forward_ip = traffic_forward_conf['traffic_forward_ip']
    local traffic_forward_port = traffic_forward_conf['traffic_forward_port']
    local set_request_header_status = traffic_forward_conf['set_request_header_status']
    local set_request_header_value = traffic_forward_conf['set_request_header_value']
    if set_request_header_status == 'true' then
      for _,v in ipairs(set_request_header_value) do
        if v['type'] == 'set_value' then
          ngx.req.set_header(v['key'],v['value'])
        elseif v['type'] == 'del_value' then
          ngx.req.clear_header(v['key'])
        end
      end
    end
    ngx.ctx.component_source_ip = traffic_forward_ip
    ngx.ctx.component_source_http_port = traffic_forward_port
  end
end

return _M
