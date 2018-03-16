# 目录

- [WAF配置文件](#waf配置文件)
- [nginx.conf文件设置](#nginxconf文件设置)
- [jxwaf_config.json文件设置](#jxwaf_configjson文件设置)

 

### WAF配置文件
- jxwaf
    - nginx
        - conf
            - nginx.conf -- nginx 配置文件
            - jxwaf
                - jxwaf_config.json  -- waf全局配置文件
                
                

### nginx.conf文件设置
```

http {
    include       mime.types;
    default_type  application/octet-stream;
    sendfile        on;
    keepalive_timeout  65;
#start
    resolver  114.114.114.114;
    init_by_lua_file /opt/jxwaf/lualib/resty/jxwaf/init.lua;
    init_worker_by_lua_file /opt/jxwaf/lualib/resty/jxwaf/init_worker.lua;
    rewrite_by_lua_file /opt/jxwaf/lualib/resty/jxwaf/rewrite.lua;
    access_by_lua_file /opt/jxwaf/lualib/resty/jxwaf/access.lua;
    header_filter_by_lua_file /opt/jxwaf/lualib/resty/jxwaf/header_filter.lua;
    log_by_lua_file /opt/jxwaf/lualib/resty/jxwaf/log.lua;
    lua_code_cache on;
#end
    upstream http://1.1.1.1 {
                server 1.1.1.1;
     }
    server {
        listen       80;
        server_name  localhost;
        location / {
            root   html;
            index  index.html index.htm;
                proxy_pass  http://1.1.1.1;
        }
    }
}

```


#### 开启全局WAF防护(默认)
```
server {
    rewrite_by_lua_file /opt/jxwaf/lualib/resty/jxwaf/rewrite.lua;
    access_by_lua_file /opt/jxwaf/lualib/resty/jxwaf/access.lua;
    header_filter_by_lua_file /opt/jxwaf/lualib/resty/jxwaf/header_filter.lua;
    log_by_lua_file /opt/jxwaf/lualib/resty/jxwaf/log.lua;
}
# 全局设置，所有网站都开启waf防护
```

#### 开启局部WAF防护

```
server {

 location / {
    rewrite_by_lua_file /opt/jxwaf/lualib/resty/jxwaf/rewrite.lua;
    access_by_lua_file /opt/jxwaf/lualib/resty/jxwaf/access.lua;
    header_filter_by_lua_file /opt/jxwaf/lualib/resty/jxwaf/header_filter.lua;
    log_by_lua_file /opt/jxwaf/lualib/resty/jxwaf/log.lua;
}
}
# 对特定网站开启waf防护
```


#### lua_shared_dict 
默认值: 无

开启业务逻辑防护引擎，OTP等功能时需要设置


### jxwaf_config.json文件设置
```
{
 "waf_api_key": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
}
```

#### waf_api_key
默认值: 无

从[jxwaf管理中心](http://www.jxwaf.com)的规则展示页面获取 WAF_API_KEY，用于jxwaf和管理中心的全局配置及规则对接


