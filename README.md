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

- JXWAF 第三版正式发布(2020-10-01)

### Feature 功能

- 应用安全防护
  - 语义防护引擎
  - Web 攻击 IP 处理
  - 自定义规则
  - 自定义拦截页面
- 流量安全防护
  - CC 攻击防护
  - CC 攻击 IP 处理
  - IP 黑白名单
- 业务安全防护
  - TODO

### Architecture 架构

JXWAF 由 jxwaf 节点与 jxwaf 管理中心组成:

- [jxwaf 节点] : 基于 openresty 开发
- [jxwaf 管理中心]：[jxwaf-mini-server](https://github.com/jx-sec/jxwaf-mini-server)

### Environment 环境

- jxwaf 节点
  - Centos 7
  - Openresty 1.15.8.3
- jxwaf 管理中心
  - Centos 7
  - Python 2.7
  - Django 1.9.2

### Quick Deploy 快速部署 (已包含 openresty 安装包)

#### 环境依赖

- 服务器版本 Centos 7.4

#### 管理中心部署

1.  \$ cd /opt
2.  \$ git clone https://github.com/jx-sec/jxwaf-mini-server.git
3.  \$ cd jxwaf-mini-server/
4.  \$ sh install.sh
5.  \$ pip install -r requirements.txt
6.  \$ python manage.py makemigrations
7.  \$ python manage.py migrate
8.  \$ nohup python manage.py runserver 0.0.0.0:80 &
9.  假设管理中心 IP 为 10.0.0.1,则打开网址 http://10.0.0.1 进行注册,注册完后登录账号,在 WAF 更新-> 语义引擎更新 中选择 语义引擎版本 加载。在 WAF 更新-> 人机识别更新 中 选择 人机识别版本 加载，同时点击 KEY 更新 加载人机识别对应的 KEY

#### 节点部署

1.  \$ cd /tmp
2.  \$ git clone https://github.com/jx-sec/jxwaf.git

```
提示: 国内服务器github下载较慢，提供百度网盘下载
https://pan.baidu.com/s/1WAt077rrOSNZj1E4X1u6pw 提取码: vcgw
```

3.  \$ cd jxwaf
4.  \$ sh install_waf.sh
5.  \$ 运行后显示类似信息即安装成功:

```
nginx: the configuration file /opt/jxwaf/nginx/conf/nginx.conf syntax is ok
nginx: configuration file /opt/jxwaf/nginx/conf/nginx.conf test is successful
```

6.  假设管理中心 IP 为 10.0.0.1,则打开网址 http://10.0.0.1 进行注册,注册完后登录账号,在 WAF 管理下的全局配置页面获取"api key"和"api password"
7.  \$ cd tools
8.  \$ python jxwaf_local_init.py --api_key=a2dde899-96a7-40s2-88ba-31f1f75f1552 --api_password=653cbbde-1cac-11ea-978f-2e728ce88125 --waf_server=http://10.0.0.1
9.  api_key 为全局配置页面中"api key"的值，api_password 为"api password"的值，运行完成后，显示类似信息即安装成功

```
config file:  /opt/jxwaf/nginx/conf/jxwaf/jxwaf_config.json
config result:
init success,access_id is d7b9fe12-606c-4ca8-bcb5-3dde9853e5f4,access_secret is af5cfc8d-d564-44dd-ba11-f1fecdf95706
auth result:
try to connect jxwaf server auth api_key and api_password,result is True
```

10. \$ /opt/jxwaf/nginx/sbin/nginx
11. 启动 openresty,openresty 会在启动或者 reload 的时候自动到 jxwaf 管理中心拉取用户配置的最新规则,之后会定期同步配置,周期可在全局配置页面设置。

### Bast Practice 最佳实践

[JXWAF 最佳实践](https://docs.jxwaf.com)

### Articles 文章

请关注公众号 JXWAF

![](img/qrcode.jpg)

### Contributor 贡献者

- [chenjc](https://github.com/jx-sec) 负责 WAF 引擎开发,管理中心开发
- [jiongrizi](https://github.com/jiongrizi) 负责管理中心前端开发,人机识别功能开发,小程序 JXWAF 助手开发
- [thankfly](https://github.com/thankfly) 负责日志,大数据分析平台及机器学习平台开发

### BUG&Requirement BUG&需求

- github 提交 BUG 或需求
- QQ 群 730947092
- 邮箱 jx-sec@outlook.com
- 微信/QQ 574604532 添加请备注 jxwaf

### Thanks 致谢

- P4NY(p4ny@qq.com):发现 SQL 语义识别引擎一处绕过漏洞
- zhutougg(github):发现上传绕过漏洞
- Neo(236309539): 发现 SQL 语义识别引擎一处绕过漏洞
- 1249648969(QQ 号)：发现 openresty 通用绕过
- kulozzzz(Github): 对比测试 JXWAF 与某厂商语义引擎，发现 XSS 绕过
