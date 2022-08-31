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

- JXWAF-2022  RC1 release

### Feature

- Basic security
  - Web protection engine
  - Web protection rules
  - Web whitelist rules
- Traffic security
  - Traffic protection engine
  - Traffic protection rules
  - Traffic whitelist rules
- Name List protection
- Component protection

### Architecture

JXWAF is composed of jxwaf nodes and jxwaf management center:

- [jxwaf nodes] : Based on Openresty development
- [jxwaf management center]：[jxwaf-mini-server](https://github.com/jx-sec/jxwaf-mini-server)

### Environment

- jxwaf nodes
  - Centos 7.4
  - Openresty 1.15.8.3
- jxwaf management center
  - Centos 7.4
  - Python 2.7
  - Django 1.9.2

### Quick Deploy (Source code deployment)

#### Environmental dependence

- Centos 7.4

#### Management center deployment(test environment)

1.  \$ cd /opt
2.  \$ git clone https://github.com/jx-sec/jxwaf-mini-server.git
3.  \$ cd jxwaf-mini-server/
4.  \$ sh install.sh
5.  \$ pip install -r requirements.txt
6.  \$ python manage.py makemigrations
7.  \$ python manage.py migrate
8.  \$ nohup python manage.py runserver 0.0.0.0:80 &
9.  Assuming that the central administration IP is 10.0.0.1, open the URL http://10.0.0.1 register and log in, and the system will automatically make the initial transition after successful login.
10.  The current deployment method is suitable for test environments, so please refer to JXWAF best practices for online environment deployment.

#### Node deployment

1.  \$ cd /tmp
2.  \$ git clone https://github.com/jx-sec/jxwaf.git
3.  \$ cd jxwaf
4.  \$ sh install_waf.sh
5.  \$ After running, similar information is displayed, the installation is successful:

```
nginx: the configuration file /opt/jxwaf/nginx/conf/nginx.conf syntax is ok
nginx: configuration file /opt/jxwaf/nginx/conf/nginx.conf test is successful
```

6.  Assuming that the central administration IP is 10.0.0.1, open the URL http://10.0.0.1 to register, log in to the account after registration, and get the "API_KEY" and "API_PASSWORD" on the System Administration - > Basic Configuration page
7.  \$ cd tools
8.  \$ python jxwaf_init.py --api_key=84ceb8f8-c052-4d60-9b43-b6007ba67ba7 --api_password=e5546411-4d82-48ad-a3f7-3daf0de94d19 --waf_server=http://10.0.0.1
9.  After the operation is complete, the installation is successful when similar information is displayed.

```
config file:  /opt/jxwaf/nginx/conf/jxwaf/jxwaf_config.json
config result:
api_key is 84ceb8f8-c052-4d60-9b43-b6007ba67ba7,access_secret is e5546411-4d82-48ad-a3f7-3daf0de94d19 
waf_update_website is http://10.0.0.1/waf_update 
auth result:
try to connect jxwaf server auth api_key and api_password,result is True
```

10. \$ /opt/jxwaf/nginx/sbin/nginx
11. Start openresty, openresty will automatically go to the jxwaf management center to pull the latest rules configured by the user when it is started or reload, and then it will synchronize the configuration regularly.


### Bast Practice

Not yet

### Articles

Not yet

### Contributor

- [chenjc](https://github.com/jx-sec) Responsible for WAF engine development and management center development
- [jiongrizi](https://github.com/jiongrizi) Responsible for the front-end development of the management center
- [thankfly](https://github.com/thankfly) Responsible for log - related module development, operational security model development

### BUG & Requirements

- github Submit bugs or requestments
- QQ: 730947092
- WeChat 574604532 tip: jxwaf

### Thanks

2022 release version

Not yet

2020 release version

- P4NY(p4ny@qq.com):Discovered a bypass vulnerability in the SQL semantic recognition engine
- zhutougg(github):Found upload bypass vulnerability
- Neo(236309539): Discovered a bypass vulnerability in the SQL semantic recognition engine
- 1249648969(QQ)：Found openresty universal bypass
- kulozzzz(Github): Compare and test JXWAF with a semantic engine from a certain vendor, and find that XSS bypasses