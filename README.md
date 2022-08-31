# JXWAF

[中文版](https://github.com/jx-sec/jxwaf/blob/master/README.md)
[English](https://github.com/jx-sec/jxwaf/blob/master/English.md)

[![Centos](https://img.shields.io/badge/centos-7-brightgreen.svg)](https://www.centos.org/)
[![OpenResty](https://img.shields.io/badge/openresty-1.15.8.3-brightgreen)](http://openresty.org/en/)
[![Django](https://img.shields.io/badge/django-1.9.2-brightgreen)](https://www.djangoproject.com/)
[![Python2.7](https://img.shields.io/badge/python-2.7-brightgreen)](https://www.python.org/)

### Introduced 介绍

JXWAF 是一款开源 WEB 应用防火墙

### Notice 通知

- JXWAF-2022  RC1 release

### Feature 功能

- 基础安全防护
  - Web防护引擎
  - Web防护规则
  - Web白名单规则
- 流量安全防护
  - 流量防护引擎
  - 流量防护规则
  - 流量白名单规则
- 名单防护
- 组件防护

### Architecture 架构

JXWAF 由 jxwaf 节点与 jxwaf 管理中心组成:

- [jxwaf 节点] : 基于 openresty 开发
- [jxwaf 管理中心] : [jxwaf-mini-server](https://github.com/jx-sec/jxwaf-mini-server)

### Environment 环境

- jxwaf 节点
  - Centos 7.4
  - Openresty 1.21.4.1
- jxwaf 管理中心
  - Centos 7.4
  - Python 2.7
  - Django 1.9.2

### Quick Deploy 快速部署 (源代码部署)

#### 环境依赖

- 服务器版本 Centos 7.4

#### 管理中心部署(测试环境)

1.  \$ cd /opt
2.  \$ git clone https://github.com/jx-sec/jxwaf-mini-server.git
3.  \$ cd jxwaf-mini-server/
4.  \$ sh install.sh
5.  \$ pip install -r requirements.txt
6.  \$ python manage.py makemigrations
7.  \$ python manage.py migrate
8.  \$ nohup python manage.py runserver 0.0.0.0:80 &
9.  假设管理中心 IP 为 10.0.0.1,则打开网址 http://10.0.0.1 进行注册并登陆,登陆成功后系统会自动进行初使化。
10.  当前部署方式适用于测试环境，线上环境部署请参考 JXWAF最佳实践

#### 节点部署

1.  \$ cd /tmp
2.  \$ git clone https://github.com/jx-sec/jxwaf.git
3.  \$ cd jxwaf
4.  \$ sh install_waf.sh
5.  \$ 运行后显示类似信息即安装成功:

```
nginx: the configuration file /opt/jxwaf/nginx/conf/nginx.conf syntax is ok
nginx: configuration file /opt/jxwaf/nginx/conf/nginx.conf test is successful
```

6.  假设管理中心 IP 为 10.0.0.1,则打开网址 http://10.0.0.1 进行注册,注册完后登录账号,在 系统管理 -> 基础配置 页面获取"API_KEY"和"API_PASSWORD"
7.  \$ cd tools
8.  \$ python jxwaf_init.py --api_key=84ceb8f8-c052-4d60-9b43-b6007ba67ba7 --api_password=e5546411-4d82-48ad-a3f7-3daf0de94d19 --waf_server=http://10.0.0.1
9.  运行完成后，显示类似信息即安装成功

```
config file:  /opt/jxwaf/nginx/conf/jxwaf/jxwaf_config.json
config result:
api_key is 84ceb8f8-c052-4d60-9b43-b6007ba67ba7,access_secret is e5546411-4d82-48ad-a3f7-3daf0de94d19 
waf_update_website is http://10.0.0.1/waf_update 
auth result:
try to connect jxwaf server auth api_key and api_password,result is True
```

10. \$ /opt/jxwaf/nginx/sbin/nginx
11. 启动 openresty,openresty 会在启动或者 reload 的时候自动到 jxwaf 管理中心拉取用户配置的最新规则,之后会定期同步配置。

### Bast Practice 最佳实践

暂无

### Articles 文章

暂无

### Contributor 贡献者

- [chenjc](https://github.com/jx-sec) 负责 WAF 引擎开发,管理中心开发
- [jiongrizi](https://github.com/jiongrizi) 负责管理中心前端开发
- [thankfly](https://github.com/thankfly) 负责日志相关模块开发，业务安全模型开发

### BUG&Requirement BUG&需求

- github 提交 BUG 或需求
- QQ 群 730947092
- 微信 574604532 添加请备注 jxwaf

### Thanks 致谢

2022版本

暂无

2020版本

- P4NY(p4ny@qq.com):发现 SQL 语义识别引擎一处绕过漏洞
- zhutougg(github):发现上传绕过漏洞
- Neo(236309539): 发现 SQL 语义识别引擎一处绕过漏洞
- 1249648969(QQ 号): 发现 openresty 通用绕过
- kulozzzz(Github): 对比测试 JXWAF 与某厂商语义引擎，发现 XSS 绕过
