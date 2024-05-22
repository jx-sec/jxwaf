# JXWAF

[中文版](https://github.com/jx-sec/jxwaf/blob/master/README.md)
[English](https://github.com/jx-sec/jxwaf/blob/master/English.md)

### Introduction

JXWAF is an open-source WEB Application Firewall.

### Notice

- Release of JXWAF4.

### Features

- Protection Management
  - Website Protection
  - List Protection
  - Basic Components
  - Analysis Components
- Operations Center
  - Business Data Statistics
  - Web Security Reports
  - Traffic Security Reports
  - Attack Events
  - Log Inquiry
  - Node Status
- System Management
  - Basic Information
  - SSL Certificate Management
  - Log Transmission Configuration
  - Log Inquiry Configuration
  - Block Page Configuration
  - Configuration Backup & Load

### Architecture

- The JXWAF system is composed of three subsystems:
  - jxwaf Console
  - jxwaf Node
  - jxlog Logging System

<kbd><img src="img/jxwaf_architecture.jpg" width="1000"></kbd>

### Demo Environment

http://demo.jxwaf.com:8000/  

Account: test  

Password: 123456  

### Test Environment Deployment
#### Requirements
- Server System: Centos 7.x
#### Quick Deployment
Allocate a pay-as-you-go server with IP address 119.45.234.74 and complete the following deployment steps:
```bash
curl -sSLk https://get.docker.com/ | bash
service docker start
yum install git -y
git clone https://github.com/jx-sec/jxwaf-docker-file.git
cd jxwaf-docker-file/test_env
docker compose up -d
```
#### Verification
Access the console at http://119.45.234.74:8000 with the default account 'test' and password '123456'. After logging in to the console, create a new website under "Website Protection," using the following configuration as a reference:
<kbd><img src="img/website_conf.jpg" width="600"></kbd>

After configuring, return to the server:

```bash
[root@VM-0-11-centos test_env_cn]# pwd
/tmp/jxwaf-docker-file/test_env_cn
[root@VM-0-11-centos test_env_cn]# cd ../waf_test/
[root@VM-0-11-centos waf_test]# python waf_poc_test.py -u http://119.45.234.74
```

After running the WAF test script, you can view the protection effect in the "Operations Center" on the console.

<kbd><img src="img/web_flow.jpg"></kbd>

### Production Environment Deployment
#### Requirements
- Server system: Centos 7.x
- Recommended server specification: At least 4 cores, 8 GB RAM
#### Deployment of jxwaf Console
Server IP Address:
- Public address: 175.27.128.142
- Private address: 10.206.0.10
```
curl -sSLk https://get.docker.com/ | bash
service docker start
yum install git -y
git clone https://github.com/jx-sec/jxwaf-docker-file.git
cd jxwaf-docker-file/prod_env/jxwaf-mini-server
docker compose  up -d
```
After deployment, access the console at http://175.27.128.142:8000. The first visit will redirect you to the account registration page. For security considerations, it is recommended to restrict the IP addresses that can access the console, such as allowing only office network IPs. After registration and logging into the console, click on "System Configuration" -> "Basic Information" to see the 'waf_auth' value required for subsequent node configuration.

<kbd><img src="img/waf_auth.jpg" width="500"></kbd>

#### Deployment of jxwaf Node

Server IP Address

- Public address: 1.13.193.150
- Private address: 10.206.0.3

```
curl -sSLk https://get.docker.com/ | bash
service docker start
yum install git -y
git clone https://github.com/jx-sec/jxwaf-docker-file.git
cd jxwaf-docker-file/prod_env/jxwaf
vim docker-compose.yml
```

Modify the values of 'JXWAF_SERVER' and 'WAF_AUTH' in the file

<kbd><img src="img/compose_conf.jpg" width="500"></kbd>

The value of 'JXWAF_SERVER' should be the address of the jxwaf console server, here it is http://10.206.0.10:8000. Note that the address should not include a path, so http://10.206.0.10:8000/ would be incorrect.

'WAF_AUTH' is the value found in System Configuration -> Basic Information under 'waf_auth'.

After modification

<kbd><img src="img/compose_conf_edit.jpg" width="500"></kbd>

```
docker compose  up -d
```

After starting, you can check if the node is online in the Operations Center -> Node Status on the console.

<kbd><img src="img/node_status.jpg"></kbd>

#### Deployment of jxlog

Server IP Address

- Internal address: 10.206.0.13

```
curl -sSLk https://get.docker.com/ | bash
service docker start
yum install git -y
git clone https://github.com/jx-sec/jxwaf-docker-file.git
cd jxwaf-docker-file/prod_env/jxlog
docker compose  up -d
```

After deployment, configure "Log Transfer Configuration" in the console under "System Configuration":

<kbd><img src="img/jxlog_conf.jpg" width="500"></kbd>

In the console under "System Configuration" -> "Log Query Configuration," configure as follows. The ClickHouse database credentials can be modified in the docker-compose.yml file.

<kbd><img src="img/clickhouse_conf.jpg" width="500"></kbd>

#### Verification

In the console, under "Protection Management" -> "Website Configuration," create a new website using the following configuration as a reference:

<kbd><img src="img/prod_test.jpg" width="500"></kbd>

After configuration, return to the jxlog server:

```
[root@VM-0-13-centos jxlog]# pwd
/root/jxwaf-docker-file/prod_env_cn/jxlog
[root@VM-0-13-centos jxlog]# cd ../../waf_test/
[root@VM-0-13-centos waf_test]# python waf_poc_test.py -u http://1.13.193.150
```

Run the WAF test script and then you can view the protection effect under "Operations Center" -> "Attack Events" in the console.

<kbd><img src="img/attack_event.jpg" width="1000"></kbd>

### Contributor 

- [chenjc](https://github.com/jx-sec)
- [jiongrizi](https://github.com/jiongrizi)
- [thankfly](https://github.com/thankfly)

### BUG&Requirement 

- WeChat: 574604532, please add a note stating jxwaf when adding.

- The WeChat group is updated periodically.

<kbd><img src="img/wx_qrcode.png" width="300"></kbd>

