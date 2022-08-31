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
  local shared_dict_uuid = shared_dict_data['shared_dict_uuid']
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
  local code = tonumber(page_conf['code'])
  local html = page_conf['html']
  if html and #html > 0 then
    ngx.status = tonumber(code)
    ngx.header.content_type = "text/html;charset=utf-8"
    ngx.header.request_id = ngx.var.request_id
    ngx.say(html)
    return ngx.exit(code)
  else
    return ngx.exit(code)
  end
end

function _M.allow()
  return ngx.exit(0)
end

function _M.reject_response()
  return ngx.exit(444)
end


return _M
