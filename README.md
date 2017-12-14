# jxwaf


[![Django](https://img.shields.io/badge/centos-7-brightgreen.svg)](https://www.centos.org/)
[![Python3](https://img.shields.io/badge/openresty-1.11.2.5-brightgreen.svg)](http://openresty.org/en/)

jxwaf(锦衣盾)是一款基于openresty(nginx+lua)开发的下一代web应用防火墙，独创的业务逻辑防护引擎和机器学习引擎可以有效对业务安全风险进行防护，解决传统WAF无法对业务安全进行防护的痛点。内置的语义分析引擎配合机器学习引擎可以避免传统WAF规则叠加太多导致速度变慢的问题，同时增强检测精准性（低误报、低漏报）。

### Feature 功能
  - 基础攻击防护
    - SQL注入攻击
    - XSS攻击
    - 目录遍历漏洞
    - 命令注入攻击
    - WebShell上传防护
    - 扫描器攻击等...
  - 机器学习
    - 支持向量机(SVM)
  - 语义分析
    - SQL注入语义分析
    - XSS攻击语义分析  
  - 业务逻辑漏洞防护
    - 短信炸弹防护
    - 越权漏洞防护
    - 短信验证码校验绕过防护等...
  - 高级CC攻击防护
    - 可针对不同URL，不同请求参数单独设置不同防护变量
    - 人机识别
  - 前端参数加密防护
    - 支持AES加解密
    - 支持DES加解密
    - 支持RSA加解密
  - 透明部署动态口令功能(将拆分成独立版本)
    - 可对后台管理系统和网站用户提供动态口令(OTP)功能 
  - 检测缓存功能
    - 对已经过WAF检测请求进行MD5缓存，提高检测效率
  - 支持协议
    - HTTP/HTTPS 
  - 性能&可靠性
     -  毫秒级响应，请求处理时间小于一毫秒
     -  支持主备部署，避免单点故障
     -  支持集群反向代理模式部署，可处理超大数据流量
     -  支持嵌入式部署，无需改变原有网络拓扑结构
  - 管理功能
    - 基础配置
    - 规则配置
    - 报表展示
    - 告警配置

### Architecture 架构

jxwaf(锦衣盾)由jxwaf与jxwaf管理后台组成:
  - [jxwaf](https://github.com/jx-sec/jxwaf) : 基于openresty(nginx+lua)开发
  - [jxwaf管理后台](https://github.com/jx-sec/jxwaf-server)(开发中)
    - web端架构
        - 前端架构: seajs + artTemplatejs + adminLTE   
        - 后端架构: django + sqlite
    - 控制端架构: ansible
    - 大数据处理架构: graylog + spark

### Environment 环境

  - jxwaf 
    - Centos 7
    - Openresty 1.11.2.5
  - jxwaf管理后台
    - Centos 7
    - Django 1.9.2
    - Ansible 2.1.2
    - Graylog 2.3.1

###  Install 安装 
将代码下载到/tmp目录，运行jxwaf_install.sh文件，jxwaf将安装在/opt/jxwaf目录，具体如下:

   1. $ cd /tmp
   2. $ git clone https://github.com/jx-sec/jxwaf.git
   3. $ cd jxwaf
   4. $ sh jxwaf_install.sh 


### Usage 使用

```

http {
    include       mime.types;
    default_type  application/octet-stream;
    sendfile        on;
    keepalive_timeout  65;

    init_by_lua_file /opt/jxwaf/lualib/resty/jxwaf/init.lua;
#    lua_shared_dict http_black 200m; 
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



 


### Docs 文档
   * [JXWAF配置说明](docs/JXWAF配置说明.md)
   * [基于Openresty实现业务安全防护 ](http://www.freebuf.com/vuls/150571.html)
   * [基于Openresty实现透明部署动态口令功能](http://www.freebuf.com/articles/network/150959.html)
    

### Contributor 贡献者
- [chenjc](https://github.com/jx-sec)  安全工程师
- [jiongrizi](https://github.com/jiongrizi) 前端开发工程师


### BUG&Requirement BUG&需求

- github提交问题或需求
- QQ群 xxxxxx

