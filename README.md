# JXWAF


[![Django](https://img.shields.io/badge/centos-7-brightgreen.svg)](https://www.centos.org/)
[![Python3](https://img.shields.io/badge/openresty-1.13.6.2-brightgreen)](http://openresty.org/en/)

### Introduction 介绍

jxwaf(锦衣盾)是一款开源WEB应用防火墙

### Notice 通知
  - 正式版本发布
  - 新增离线部署功能
  - 新增阿里云日志服务接入功能
  - 新增HTTPS证书私钥AES加密
  
### Feature 功能
  - Web应用攻击防护
  - CC攻击智能防护
  - 自定义规则防护
  - IP黑白名单
  - 地区封禁
  - 拦截页面自定义
  - 阿里云日志服务接入功能

### Architecture 架构

jxwaf(锦衣盾)由jxwaf客户端与jxwaf管理中心组成:
  - [jxwaf客户端] : 基于openresty开发，由用户部署在自己的服务器上
  - [jxwaf线上管理中心]：https://www.jxwaf.com
  - [jxwaf管理中心私有化部署]: docker run -d -p 80:80 jxwaf/jxwaf-server:latest


### Environment 环境

  - jxwaf 
    - Centos 7
    - Openresty 1.13.6.2

###  Install 安装 (已包含openresty安装包)
将代码下载到/tmp目录，运行install_waf.sh文件，jxwaf将安装在/opt/jxwaf目录，具体如下:

   1. $ cd /tmp
   2. $ git clone https://github.com/jx-sec/jxwaf.git
   3. $ cd jxwaf
   4. $ sh install_waf.sh 
   5. $ 运行后显示类似信息即安装成功: 
   

```
nginx: the configuration file /opt/jxwaf/nginx/conf/nginx.conf syntax is ok

nginx: [alert] [lua] waf.lua:566: init(): jxwaf init success,waf node uuid is 99d977e8-401b-4ede-a427-94f7170638ce

nginx: configuration file /opt/jxwaf/nginx/conf/nginx.conf test is successful
```


   6. 访问 https://www.jxwaf.com 并注册账号,在全局配置页面获取"api key"和"api password"
   7. $ cd tools
   8. $ python jxwaf_init.py --api_key=a2dde899-96a7-40s2-88ba-31f1f75f1552 --api_password=653cbbde-1cac-11ea-978f-2e728ce88125
   9. api_key 为全局配置页面中"api key"的值，api_password为"api password"的值，运行完成后，显示类似信息即安装成功
   



如果管理中心为私有化部署，则

   6. 假设管理中心地址为 http://192.168.1.1 ,打开网站注册账号,邮箱验证码随便填写，注册完登录账号后在全局配置页面获取"api key"和"api password"
   7. $ cd tools
   8. $ python jxwaf_local_init.py --api_key=a2dde899-96a7-40s2-88ba-31f1f75f1552 --api_password=653cbbde-1cac-11ea-978f-2e728ce88125 --waf_server=http://192.168.1.1
   9. api_key 为全局配置页面中"api key"的值，api_password为"api password"的值，运行完成后，显示类似信息即安装成功

```
config file:  /opt/jxwaf/nginx/conf/jxwaf/jxwaf_config.json
config result:
init success,access_id is a20be899-96a6-40b2-88ba-32f111111111,access_secret is a42ca0ca-80b5-8e4b-f250-3dc309cccccc
auth result:
try to connect jxwaf server auth api_key and api_password,result is True
```
   10. $ /opt/jxwaf/nginx/sbin/nginx
   11. 启动openresty,openresty会在启动或者reload的时候自动到jxwaf管理中心拉取用户配置的最新规则,之后会定期同步配置,周期可在全局配置页面设置。
  

### Usage 使用
使用详情请参考文档
https://docs.jxwaf.com


### Articles 文章
   * [基于Openresty实现业务安全防护 ](http://www.freebuf.com/vuls/150571.html)
   * [基于Openresty实现透明部署动态口令功能](http://www.freebuf.com/articles/network/150959.html)
   * [WAF开发之Cookie安全防护  ](http://www.freebuf.com/articles/web/164232.html) 
   * [JXWAF正式版发布](https://mp.weixin.qq.com/s/EWbWXJoUlcKlu3vTDDDYuQ)
   * [JXWAF最佳实践-离线部署](https://mp.weixin.qq.com/s/3Q8FvAd9Lx7DLvrttE8xkw)
   * [JXWAF部署指南](https://mp.weixin.qq.com/s/7WXUQRCnq4-_hUXS1kmlZQ)

更多文章请关注公众号 JXWAF

![](img/qrcode.jpg)
    

### Contributor 贡献者
- [chenjc](https://github.com/jx-sec) 负责WAF引擎开发
- [jiongrizi](https://github.com/jiongrizi) 负责管理中心前端开发,人机识别功能开发,小程序JXWAF助手开发
- [thankfly](https://github.com/thankfly)   负责日志,大数据分析平台及机器学习平台开发


### BUG&Requirement BUG&需求

- github 提交BUG或需求
- QQ群 730947092
- 邮箱 jx-sec@outlook.com
- 微信/QQ 574604532 添加请备注 jxwaf

### Thanks 致谢
 - P4NY(p4ny@qq.com):发现SQL语义识别引擎一处绕过漏洞  
 - zhutougg(github):发现上传绕过漏洞
 - Neo(236309539): 发现SQL语义识别引擎一处绕过漏洞
 - 1249648969(QQ号)：发现openresty通用绕过
 - kulozzzz(Github): 对比测试JXWAF与某厂商语义引擎，发现XSS绕过
