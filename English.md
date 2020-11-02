# JXWAF

[中文版](https://github.com/jx-sec/jxwaf/blob/master/README.md)
[English](https://github.com/jx-sec/jxwaf/blob/master/English.md)

[![Centos](https://img.shields.io/badge/centos-7-brightgreen.svg)](https://www.centos.org/)
[![OpenResty](https://img.shields.io/badge/openresty-1.15.8.3-brightgreen)](http://openresty.org/en/)
[![Django](https://img.shields.io/badge/django-1.9.2-brightgreen)](https://www.djangoproject.com/)
[![Python2.7](https://img.shields.io/badge/python-2.7-brightgreen)](https://www.python.org/)

### Introduced

JXWAF is an open source web application firewall

### Notice

- JXWAF The third edition is officially released(2020-10-01)

### Feature

- Application security protection
  - Semantic Protection Engine
  - Web attack IP processing
  - Custom rule
  - Custom block page
- Traffic safety protection
  - CC attack protection
  - CC attack IP processing
  - IP whitelists and blocklists
- Business security protection
  - TODO

### Architecture

JXWAF is composed of jxwaf nodes and jxwaf management center:

- [jxwaf nodes] : Based on Openresty development
- [jxwaf management center]：[jxwaf-mini-server](https://github.com/jx-sec/jxwaf-mini-server)

### Environment

- jxwaf nodes
  - Centos 7
  - Openresty 1.15.8.3
- jxwaf management center
  - Centos 7
  - Python 2.7
  - Django 1.9.2

### Quick Deploy (Source code deployment)

#### Environmental dependence

- Centos 7.4

#### Management center deployment

1.  \$ cd /opt
2.  \$ git clone https://github.com/jx-sec/jxwaf-mini-server.git
3.  \$ cd jxwaf-mini-server/
4.  \$ sh install.sh
5.  \$ pip install -r requirements.txt
6.  \$ python manage.py makemigrations
7.  \$ python manage.py migrate
8.  \$ nohup python manage.py runserver 0.0.0.0:80 &
9.  If the management center IP is 10.0.0.1, open the URL http://10.0.0.1 to register,Login account after registration, Select Semantic Engine Version to load in WAF Update -> Semantic Engine Update.In WAF Update -> Human Machine Recognition Update, select Human Machine Recognition Version to load, At the same time, load the Random KEY corresponding to the human-machine identification, click KEY to update.

#### Node deployment

1.  \$ cd /tmp
2.  \$ git clone https://github.com/jx-sec/jxwaf.git

```
Tip: The domestic server github download is slow, provide BaiduYun disk download，It is not updated frequently
Address: https://pan.baidu.com/s/1WAt077rrOSNZj1E4X1u6pw
Extraction code: vcgw
```

3.  \$ cd jxwaf
4.  \$ sh install_waf.sh
5.  \$ After running, similar information is displayed, the installation is successful:

```
nginx: the configuration file /opt/jxwaf/nginx/conf/nginx.conf syntax is ok
nginx: configuration file /opt/jxwaf/nginx/conf/nginx.conf test is successful
```

6.  If the management center IP is 10.0.0.1,open the URL http://10.0.0.1 to register, Login account after registration, Obtain "api key" and "api password" on the global configuration page under WAF management
7.  \$ cd tools
8.  \$ python jxwaf_local_init.py --api_key=a2dde899-96a7-40s2-88ba-31f1f75f1552 --api_password=653cbbde-1cac-11ea-978f-2e728ce88125 --waf_server=http://10.0.0.1
9.  In the global configuration page, api_key is the value of "api key" and api_password is the value of "api password", After the operation is complete, the installation is successful when similar information is displayed.

```
config file:  /opt/jxwaf/nginx/conf/jxwaf/jxwaf_config.json
config result:
init success,access_id is d7b9fe12-606c-4ca8-bcb5-3dde9853e5f4,access_secret is af5cfc8d-d564-44dd-ba11-f1fecdf95706
auth result:
try to connect jxwaf server auth api_key and api_password,result is True
```

10. \$ /opt/jxwaf/nginx/sbin/nginx
11. Start openresty, openresty will automatically go to the jxwaf management center to pull the latest rules configured by the user when it is started or reload, and then it will synchronize the configuration regularly, and the cycle can be set on the global configuration page.

### Quick Deployment Rapid Deployment (Docker Deployment)

#### Environmental dependency

- Docker  

Docker installation documentation: https://docs.docker.com/get-docker/

#### Management center deployment

1. docker pull jxwaf/jxwaf-mini-server:v20201102
2. docker run -p 80:80 -d jxwaf/jxwaf-mini-server:v20201102
3. Assuming that the Central Administration IP is 10.0.0.1, open URL http://10.0.0.1 to register, log in to the account after registration, and select the Semantic Engine version to load in the WAF Update-> Semantic Engine Update. In WAF Update-> Human Machine Identification Update, select The Human Machine Identification Version Load, and click Random KEY Update Loader Identification for KEY

#### Node deployment

1. docker pull jxwaf/jxwaf:v20201102
2. Assuming that the Central Administration IP is 10.0.0.1, open URL http://10.0.0.1 to register, log in to your account after registration, and get "api key" and "api password" on the global configuration page managed by WAF
3. docker run -p80:80 --env JXWAF_API_KEY=193b002d-5f3e-45a0-85d1-dba8f7c27b64 --env JXWAF_API_PASSWD=c7a648 c3-48f3-459a-bc93-1bbc7932f60e-env WAF_UPDATE_WEBSITE-http://10.0.0.1 jxwaf/jxwaf:v2020110
4. The JXWAF_API_KEY provides a value of "api key" JXWAF_API_PASSWD as "api password" on the global configuration page, and WAF_UPDATE_WEBSITE is the address of the management center, assuming that the running container ID is efda21c02e72, the following command is executed and similar information is displayed.
5. docker logs efda21c02e72

```
{
    "waf_api_key": "193b002d-5f3e-45a0-85d1-dba8f7c27b64",
    "waf_api_password": "c7a648c3-48f3-459a-bc93-1bbc7932f60e",
    "waf_update_website": "http://10.0.0.1/waf_update",
    "waf_monitor_website": "http://10.0.0.1/waf_monitor",
    "waf_local":"false",
    "server_info":"|efda21c02e72",
    "waf_node_monitor":"true"
}
nginx: [alert] [lua] waf.lua:647: init(): jxwaf init success,waf node uuid is ad7b29de-858a-4781-ba1c-53ca92506bfd
2020/11/02 17:01:44 [alert] 20#0: [lua] waf.lua:647: init(): jxwaf init success,waf node uuid is ad7b29de-858a-4781-ba1c-53ca92506bfd
2020/11/02 17:01:45 [alert] 23#0: *2 [lua] waf.lua:401: monitor report success, context: ngx.timer
2020/11/02 17:01:45 [error] 23#0: *4 [lua] waf.lua:483: bot check standard key count is 10, context: ngx.timer
2020/11/02 17:01:45 [error] 23#0: *4 [lua] waf.lua:484: bot check key image count is 10, context: ngx.timer
2020/11/02 17:01:45 [error] 23#0: *4 [lua] waf.lua:485: bot check key slipper count is 10, context: ngx.timer
2020/11/02 17:01:45 [alert] 23#0: *4 [lua] waf.lua:502: global config info md5 is 0f1515005b96d11464bbd130ceb6b902,update config info success, context: ngx.timer
```

### Bast Practice

[JXWAF Bast Practice](https://docs.jxwaf.com)

### Articles

Please follow the WeChat Official Accounts: JXWAF

![](img/qrcode.jpg)

### Contributor

- [chenjc](https://github.com/jx-sec) Responsible for WAF engine development and management center development
- [jiongrizi](https://github.com/jiongrizi) Responsible for the front-end development of the management center, the development of human-machine recognition functions, and the development of the JXWAF assistant for the small program
- [thankfly](https://github.com/thankfly) Responsible for log, big data analysis platform and machine learning platform development

### BUG & Requirements

- github Submit bugs or requestments
- QQ: 730947092
- E-mail: jx-sec@outlook.com
- WeChat/QQ 574604532 tip: jxwaf

### Thanks

- P4NY(p4ny@qq.com):Discovered a bypass vulnerability in the SQL semantic recognition engine
- zhutougg(github):Found upload bypass vulnerability
- Neo(236309539): Discovered a bypass vulnerability in the SQL semantic recognition engine
- 1249648969(QQ)：Found openresty universal bypass
- kulozzzz(Github): Compare and test JXWAF with a semantic engine from a certain vendor, and find that XSS bypasses
