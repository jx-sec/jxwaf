

# 目录

- [JXWAF](#jxwaf)
- [WAF所有配置文件](#waf所有配置文件)
- [nginx.conf文件设置](#nginxconf文件设置)
- [init.lua文件设置](#initlua文件设置)
- [jxwaf_config.json文件设置](#jxwaf_configjson文件设置)


### WAF所有配置文件
- jxwaf
    - lualib
        - resty
            - jxwaf
                - init.lua -- 设置waf全局配置文件地址
    - nginx
        - conf
            - nginx.conf -- nginx 配置文件
            - jxwaf
                - jxwaf_config.json --  waf全局配置文件
                - waf_base_rule.json -- waf base规则配置文件
                - waf_sql_rule.json -- waf sql规则配置文件
                - waf_other_rule.json -- waf other规则配置文件
                - 等...
### nginx.conf文件设置
```

http {
    include       mime.types;
    default_type  application/octet-stream;
    sendfile        on;
    keepalive_timeout  65;

    init_by_lua_file /opt/jxwaf/lualib/resty/jxwaf/init.lua;
    lua_shared_dict http_black 200m; 
#    lua_shared_dict http_white 200m; 
    upstream http://1.1.1.1 {
                server 1.1.1.1;
     }
    server {
        listen       80;
        server_name  localhost;
        lua_code_cache on;
        access_by_lua_file /opt/jxwaf/lualib/resty/jxwaf/access.lua;
        log_by_lua_file /opt/jxwaf/lualib/resty/jxwaf/log.lua;

        location / {
#        access_by_lua_file /opt/jxwaf/lualib/resty/jxwaf/access.lua;
#        log_by_lua_file /opt/jxwaf/lualib/resty/jxwaf/log.lua;
            root   html;
            index  index.html index.htm;
                proxy_pass  http://1.1.1.1;
        }



```
#### init_by_lua_file 

默认值: /opt/jxwaf/lualib/resty/jxwaf/init.lua

设置 init_by_lua_file 文件地址，详情请查看openresty文档

#### access_by_lua_file 

默认值: /opt/jxwaf/lualib/resty/jxwaf/access.lua

设置access_by_lua_file 文件地址，详情请查看openresty文档

全局开启WAF防护
```
server {
access_by_lua_file /opt/jxwaf/lualib/resty/jxwaf/access.lua; 
}
# 全局设置，所有网站都开启waf防护
```

局部开启WAF防护

```
server {

 location / {
access_by_lua_file /opt/jxwaf/lualib/resty/jxwaf/access.lua; 
}
}
# 对特定网站开启waf防护
```
#### log_by_lua_file

默认值: /opt/jxwaf/lualib/resty/jxwaf/log.lua

设置log_by_lua_file 文件地址，详情请查看openresty文档

全局设置日志记录功能
```
server {
log_by_lua_file /opt/jxwaf/lualib/resty/jxwaf/log.lua; 
}
# 全局设置，所有网站都开启日志记录功能
```

局部设置日志记录功能

```
server {

 location / {
log_by_lua_file /opt/jxwaf/lualib/resty/jxwaf/access.lua; 
}
}
# 对特定网站开启日志记录功能
```
#### lua_shared_dict 
默认值: 无

开启业务逻辑防护引擎，OTP等功能时需要设置，详情请查看openresty文档


### init.lua文件设置
```
local waf = require "resty.jxwaf.waf"
local config_path = "/opt/jxwaf/nginx/conf/jxwaf/jxwaf_config.json" 
waf.init(config_path)
```
#### config_path 
默认值: /opt/jxwaf/nginx/conf/jxwaf/jxwaf_config.json

设置waf全局配置文件地址


### jxwaf_config.json文件设置
```
{
    "rule_path": "/opt/openresty/nginx/nginx/conf/jxwaf/",
    "rulesets": [
	"waf_base_rule",
	"waf_sql_rule",
	"waf_other_rule"
    ],
    "log_ip":"1.1.1.1",
    "log_port":"666",
    "log_sock_type":"udp",
    "log_flush_limit":"1",
}
```

##### rule_path
默认值: /opt/openresty/nginx/nginx/conf/jxwaf/

设置waf基础防护规则文件目录

#### rulesets
默认值: waf_base_rule,waf_sql_rule,waf_other_rule

设置要启用的基础防护规则文件

#### log_ip
默认值: 无

设置日志服务器IP

#### log_port
默认值: 无

设置日志服务器端口

#### log_sock_type
默认值: udp

设置日志服务器接收的协议，默认为udp

#### log_ip
默认值: 1

设置日志缓存大小，默认为1，设置太大可能导致一部分日志丢失


