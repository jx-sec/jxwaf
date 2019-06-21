# jxwaf


[![Django](https://img.shields.io/badge/centos-7-brightgreen.svg)](https://www.centos.org/)
[![Python3](https://img.shields.io/badge/openresty-1.11.2.5-brightgreen.svg)](http://openresty.org/en/)

jxwaf(锦衣盾)是一款基于openresty(nginx+lua)开发的下一代web应用防火墙，独创的业务安全防护引擎和机器学习引擎可以有效对业务安全风险进行防护，解决传统WAF无法对业务安全进行防护的痛点。内置的语义分析引擎配合机器学习引擎可以避免传统WAF规则叠加太多导致速度变慢的问题，同时增强检测精准性（低误报、低漏报）。

### Notice 通知
  - 新版本jxwaf2正式发布,欢迎使用,地址为 http://www.jxwaf.com
  - 旧版本将维护至年底,新用户请使用jxwaf2 
  - 测试账号为test@jxwaf.com,密码 123456
  - 测试网站为 tmp.jxwaf.com
  - 注册如未收到邮件,请查看垃圾邮箱
  
### Feature 功能
  - 待补充

### Architecture 架构

jxwaf(锦衣盾)由jxwaf与jxwaf管理中心组成:
  - [jxwaf](https://github.com/jx-sec/jxwaf) : 基于openresty(nginx+lua)开发
  - [jxwaf管理中心](http://www.jxwaf.com)：http://www.jxwaf.com


### Environment 环境

  - jxwaf 
    - Centos 7
    - Openresty 1.11.2.4

###  Install 安装 (已包含openresty安装包)
将代码下载到/tmp目录，运行install_waf.sh文件，jxwaf将安装在/opt/jxwaf目录，具体如下:

   1. $ cd /tmp
   2. $ git clone https://github.com/jx-sec/jxwaf.git
   3. $ cd jxwaf
   4. $ sh install_waf.sh 
   5. $ 运行后显示如下信息即安装成功: 
   
      nginx: the configuration file /opt/jxwaf/nginx/conf/nginx.conf syntax is ok

      nginx: configuration file /opt/jxwaf/nginx/conf/nginx.conf test is successful

   6. 访问 http://www.jxwaf.com 并注册账号,在全局配置页面获取"api key"和"api password"
   7. 修改/opt/jxwaf/nginx/conf/jxwaf/jxwaf_config.json 中的"waf_api_key"为你自己账号的"api key","waf_api_password"为你自己账号的"api password"
   8. $ /opt/jxwaf/nginx/sbin/nginx 启动openresty,openresty会在启动或者reload的时候自动到jxwaf管理中心拉取用户配置的最新规则,之后会定期同步配置,周期可在全局配置页面设置,默认为五分钟同步一次

### Usage 使用

```

待补充

```

### Rule Local load 规则本地加载
  1. $ curl "http://update2.jxwaf.com/waf_update" -d 'api_key=3d96848e-bab2-40b7-8c0b-abac3b613585&api_password=8d86848e-bab2-40b7-880b-abac3b613585&md5=""' > /opt/jxwaf/nginx/conf/jxwaf/jxwaf_local_config.json
  2. $ 修改/opt/jxwaf/nginx/conf/jxwaf/jxwaf_config.json 中的”waf_local”为”true”
  3. $ /opt/jxwaf/nginx/sbin/nginx -s reload
注意:api_key需修改为你自己账号的”api key”,api_password需修改为你自己账号的”api password"




 


### Docs 文档
   * [JXWAF使用说明](docs/JXWAF使用说明.md)
   * [基于Openresty实现业务安全防护 ](http://www.freebuf.com/vuls/150571.html)
   * [基于Openresty实现透明部署动态口令功能](http://www.freebuf.com/articles/network/150959.html)
   * [WAF开发之Cookie安全防护  ](http://www.freebuf.com/articles/web/164232.html) 
    

### Contributor 贡献者
- [chenjc](https://github.com/jx-sec)  安全工程师,负责waf引擎开发
- [jiongrizi](https://github.com/jiongrizi) 前端开发工程师,负责管理中心前端开发,人机识别功能开发,小程序JXWAF助手开发
- [thankfly](https://github.com/thankfly)   安全工程师,负责日志,大数据分析平台及机器学习平台开发


### BUG&Requirement BUG&需求

- github 提交BUG题或需求
- QQ群 730947092
- 邮箱 jx-sec@outlook.com

### Thanks 致谢
 - P4NY(p4ny@qq.com):发现SQL语义识别引擎一处绕过漏洞  
 - zhutougg(github):发现上传绕过漏洞
 - Neo(236309539): 发现SQL语义识别引擎一处绕过漏洞
