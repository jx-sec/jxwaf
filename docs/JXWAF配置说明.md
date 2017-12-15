

# 目录

- [WAF所有配置文件](#waf所有配置文件)
- [nginx.conf文件设置](#nginxconf文件设置)
- [init.lua文件设置](#initlua文件设置)
- [jxwaf_config.json文件设置](#jxwaf_configjson文件设置)
- [WAF基础防护规则文件设置](#WAF基础防护规则文件设置)
 

### WAF所有配置文件
- jxwaf
    - lualib
        - resty
            - jxwaf
                - init.lua -- waf初始化文件，设置waf全局配置文件地址
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


### WAF基础防护文件规则设置
```
	    {
        "rule_id": "000001",
        "rule_detail": "white suffix Skip detection",
        "rule_action": "allow",
        "rule_category": "base_detection",
        "rule_log": "false",
        "rule_serverity": "high",
        "rule_matchs": [
            {
                "rule_vars": [
                    {
                        "rule_var": "URI"

                    }
                ],
                "rule_transform": ["none"],
                "rule_operator": "rx",
                "rule_pattern": "(.jpg|.js|.css|.png|.gif|.jpeg)$",
                "rule_negated": false

            }


        ]
    },
	            {
        "rule_id": "000002",
        "rule_detail": "base_headers_length_detection",
        "rule_action": "deny",
        "rule_category": "base_detection",
        "rule_log": "true",
        "rule_serverity": "high",
        "rule_matchs": [
            {
                "rule_vars": [
                    {
                        "rule_var": "REQUEST_HEADERS",
			"rule_ignore": ["cookie","user-agent","Referer"]

                    }
                ],
                "rule_transform": ["length"],
                "rule_operator": "ge",
                "rule_pattern": "120",
                "rule_negated": false

            }


        ]
    }
```
#### rule_id
默认值: 无

规则ID，六位数字，数值越小越先匹配 

#### rule_detail
默认值: 无

规则描述

#### rule_action
默认值: 无

匹配到规则后执行的动作

可选项:
- allow  匹配到规则后，跳过后续所有规则
- pass   匹配到规则后，跳过该条规则继续匹配后续规则
- deny   匹配到规则后，拒绝该请求，返回403
- redirec 匹配到规则后，重定向请求到特定地址

#### rule_category
默认值: 无

规则类别

#### rule_log
默认值: true

日志记录开关，true为开启日志记录，false为不开启日志记录

#### rule_serverit
默认值: 无

设置规则报警级别，值为 high，medium，low

#### rule_matchs
默认值: 无

具体的规则匹配设置，支持多重匹配，当所有匹配都符合时，才会执行规则动作。

```
  "rule_matchs": [
	                {
                "rule_vars": [
                    {
                        "rule_var": "URI"

                    }
                ],
                "rule_transform": ["none"],
                "rule_operator": "rx",
                "rule_pattern": "/k/k$",
                "rule_negated": false

            },

            {
                "rule_vars": [
                    {
                        "rule_var": "ARGS_POST",
			"rule_specific": ["ID"]

                    }
                ],
                "rule_transform": ["none"],
                "rule_operator": "rx",
                "rule_pattern": "92",
                "rule_negated": false

            },
	            {
                "rule_vars": [
                    {
                        "rule_var": "ARGS_POST",
                        "rule_specific": ["biz_type"]

                    }
                ],
                "rule_transform": ["none"],
                "rule_operator": "rx",
                "rule_pattern": "7",
                "rule_negated": "true"

            }
        ]
```
##### rule_vars
默认值: 无

设置要进行检测的参数，支持多重参数设置
```
                "rule_vars": [
                    {
                        "rule_var": "ARGS_POST",
			"rule_specific": ["ID"，"IW"]

                    },
                                        {
                        "rule_var": "ARGS_GET",
			"rule_ignore": ["CD"]

                    },
                    {
                        "rule_var": "URI"

                    },
                ]

```
**rule_vars**

默认值:无

支持参数:
- ARGS
- ARGS_NAMES 
- ARGS_GET
- ARGS_GET_NAMES
- ARGS_POST
- ARGS_POST_NAMES
- REMOTE_ADDR
- BIN_REMOTE_ADDR
- SCHEME
- REMOTE_HOST
- SERVER_ADDR
- REMOTE_USER
- SERVER_NAME
- SERVER_PORT
- HTTP_VERSION
- REQUEST_METHOD
- URI 
- URI_ARGS 
- METHOD 
- QUERY_STRING 
- REQUEST_URI 
- REQUEST_BASENAME 
- REQUEST_LINE 
- REQUEST_PROTOCOL 
- REQUEST_COOKIES 
- REQUEST_COOKIES_NAMES 
- HTTP_USER_AGENT 
- RAW_HEADER 
- HTTP_REFERER
- REQUEST_HEADERS
- REQUEST_HEADERS_NAMES 
- TIME 
- TIME_EPOCH
- FILE_NAMES
- FILE_TYPES 
- RESP_BODY 

**rule_specific**

默认值: 无

ARGS，ARGS_GET，ARGS_POST，REQUEST_COOKIES，REQUEST_HEADERS支持该选项

值为数组，与rule_ignore互斥


**rule_ignore**

默认值: 无

ARGS，ARGS_GET，ARGS_POST，REQUEST_COOKIES，REQUEST_HEADERS支持该选项

值为数组，与rule_specific互斥


#### rule_transform
默认值: none

对参数进行预处理，数组类型，顺序相关

支持参数:
- none
- base64Decode
- base64Encode
- cmdLine
- compressWhitespace
- hexDecode
- hexEncode
- htmlDecode
- length
- lowercase
- md5
- normalisePath 
- removeComments = function(value)
- removeCommentsChar = function(value)
- removeWhitespace = function(value)
- sha1 = function(value)
- sqlHexDecode = function(value)
- trim = function(value)
- trimLeft = function(value)
- trimRight = function(value)
- uriDecode = function(value)
- uriEncode = function(value)

#### rule_operator
默认值: 无
选择参数匹配模式，单选

支持参数:
- ac 
- eq 
- gt 
- le
- ge 
- le 
- rx
- detectSQLi 
- detectXSS
- limitreq 

#### rule_pattern
默认值: 无

输入匹配值

#### rule_negated
默认值: false

是否对匹配结果取反 




