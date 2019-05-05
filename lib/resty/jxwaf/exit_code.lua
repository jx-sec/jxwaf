local _M = {}

local default_exist_html = [[
<head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
<title>JXWAF网站应用防火墙</title>
</head>
<body>
<p>请求包含非法字符,请检查提交内容</p>
<p>普通网站访客，请联系网站管理员处理</p>
</body>
</html>
]]

local default_error_html = [[
<head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
<title>JXWAF网站应用防火墙</title>
</head>
<body>
    <p>内部错误,请联系网站管理员处理</p>
</body>
</html>
]]

local default_no_exist_html = [[
<head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
<title>JXWAF网站应用防火墙</title>
</head>
<body>
  <p>访问网站不存在,请联系网站管理员处理</p>
</body>
</html>
]]

local default_limit_html = [[
<head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
<title>JXWAF网站应用防火墙</title>
</head>
<body>
  <p>访问频率异常,请稍后访问</p>
</body>
</html>
]]

local default_attack_ip_html = [[
  <!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
<title>JXWAF网站应用防火墙</title>
</head>
<body>
  <p>IP已进入黑名单,禁止访问网站</p>
  <p>普通网站访客，请联系网站管理员处理</p>
</body>
</html>
]]


local function return_exit(exit_code,exit_html)
  local code = 403
  local html = default_exist_html
  if exit_code and exit_html then
    code = tonumber(exit_code) 
    html = exit_html 
    ngx.status = code
    ngx.header.content_type = "text/html;charset=utf-8"
    ngx.say(html)
    return ngx.exit(code)
  else
    return ngx.exit(code)
  end
end
_M.return_exit = return_exit

local function return_error(exit_code,exit_html)
  local code = 500
  local html = default_error_html
  if exit_code and exit_html then
    code = tonumber(exit_code) 
    html = exit_html 
    ngx.status = code
    ngx.header.content_type = "text/html;charset=utf-8"
    ngx.say(html)
    return ngx.exit(code)
  else
    return ngx.exit(code)
  end
end
_M.return_error = return_error

local function return_no_exist(exit_code,exit_html)
  local code = 404
  local html = default_no_exist_html
  if exit_code and exit_html then
    code = tonumber(exit_code) 
    html = exit_html 
    ngx.status = code
    ngx.header.content_type = "text/html;charset=utf-8"
    ngx.say(html)
    return ngx.exit(code)
  else
    return ngx.exit(code)
  end
end
_M.return_no_exist = return_no_exist

local function return_limit(exit_code,exit_html)
  local code = 404
  local html = default_limit_html
  if exit_code and exit_html then
    code = tonumber(exit_code) 
    html = exit_html 
    ngx.status = code
    ngx.header.content_type = "text/html;charset=utf-8"
    ngx.say(html)
    return ngx.exit(code)
  else
    return ngx.exit(code)
  end
end
_M.return_limit = return_limit

local function return_attack_ip(exit_code,exit_html)
  local code = 404
  local html = default_attack_ip_html
  if exit_code and exit_html then
    code = tonumber(exit_code) 
    html = exit_html 
    ngx.status = code
    ngx.header.content_type = "text/html;charset=utf-8"
    ngx.say(html)
    return ngx.exit(code)
  else
    return ngx.exit(code)
  end
end
_M.return_attack_ip = return_attack_ip



return _M