# JXWAF

[中文版](https://github.com/jx-sec/jxwaf/blob/master/README.md) | [English](https://github.com/jx-sec/jxwaf/blob/master/English.md)

## Introduction

JXWAF is a cloud-based Web Application Firewall (WAF) that analyzes and detects web application traffic. It filters malicious traffic and forwards legitimate traffic to backend servers to ensure secure and stable web service operations.

🌟 Cloud WAF System | CDN Functionality | Semantic Analysis Engine | WebTDS Deep Inspection

## Documentation

https://docs.jxwaf.com/

## Features

- Protection Management
  - Website Protection
    - Protection Configuration
      - Web Protection Engine
      - Web Protection Rules
      - Scan & Attack Protection
      - Anti-Tampering
      - Web Whitelist Rules
      - Traffic Protection Engine
      - Traffic Protection Rules
      - IP Geo-Blocking
      - IP Blacklist 
      - Traffic Whitelist Rules
    - Cache Configuration
      - Cache Policy
      - No-Cache Policy
      - Cache Bypass Policy
    - Advanced Configuration
      - Custom Request Headers
      - Custom Response Headers
      - Custom Response Content
      - Custom Origin Server
  - List Protection
  - Basic Components
  - Analysis Components
- Operations Center
  - Statistics
  - Web Security Reports
  - Traffic Security Reports
  - Attack Events
  - Log Query
  - Network Blacklist
  - Network Whitelist
  - Node Status
- System Management
  - Basic Information
  - SSL Certificate Management
  - CNAME Configuration
  - Log Transfer Configuration
  - Log Query Configuration
  - WebTDS Detection Configuration
  - Block Page Configuration
  - Configuration Backup & Restore

## Architecture

- JXWAF consists of three subsystems:
  - JXWAF Admin Console
  - JXWAF Node
  - JXLOG System

<kbd><img src="img/jxwaf_architecture.png" width="1000"></kbd>

## Deployment

### Requirements

- OS: Debian 12.x
- Minimum Server Specs: 4-core CPU, 8GB RAM

### JXWAF Admin Console Deployment

Server IP Addresses:
- Public IP: 47.120.63.196
- Private IP: 172.29.198.241

```bash
# 1. Install Docker
curl -fsSL https://get.docker.com | bash -s docker --mirror Aliyun
# 2. Clone repository (Use https://gitclone.com/github.com/jx-sec/jxwaf.git in China)
git clone https://github.com/jx-sec/jxwaf.git
# 3. Start container
cd jxwaf/jxwaf_admin_server
docker compose up -d
```

After deployment, access the console at http://47.120.63.196. First-time visitors will be redirected to the registration page.

After registration and login, navigate to **System Management > Basic Information** to obtain the `waf_auth` value for node configuration.

<kbd><img src="img/waf_auth.png" width="500"></kbd>

### JXWAF Node Deployment

Server IP Addresses:
- Public IP: 47.84.176.156
- Private IP: 172.22.168.117

```bash
# 1. Install Docker
curl -fsSL https://get.docker.com | bash -s docker --mirror Aliyun
# 2. Clone repository (Use https://gitclone.com/github.com/jx-sec/jxwaf.git in China)
git clone https://github.com/jx-sec/jxwaf.git
# 3. Start container
cd jxwaf/jxwaf_node
vim docker-compose.yml
```

Modify `JXWAF_SERVER` and `WAF_AUTH` in the compose file:
- `JXWAF_SERVER`: Admin Console URL (e.g., `http://47.120.63.196`)
- `WAF_AUTH`: Value from **System Management > Basic Information**

<kbd><img src="img/compose_conf_edit.png" width="500"></kbd>

```bash
docker compose up -d
```

Verify node status in **Operations Center > Node Status**.

<kbd><img src="img/node_status.png"></kbd>

### JXLOG Deployment

Server IP Addresses:
- Public IP: 47.115.222.190
- Private IP: 172.29.198.239

```bash
# 1. Install Docker
curl -fsSL https://get.docker.com | bash -s docker --mirror Aliyun
# 2. Clone repository (Use https://gitclone.com/github.com/jx-sec/jxwaf.git in China)
git clone https://github.com/jx-sec/jxwaf.git
# 3. Start container
cd jxwaf/jxlog
docker compose up -d
```

Configure log settings in the Admin Console:
- **System Management > Log Transfer Configuration**
- **System Management > Log Query Configuration** (Use ClickHouse credentials from `docker-compose.yml`)

<kbd><img src="img/jxlog_conf.png" width="500"></kbd>
<kbd><img src="img/clickhouse_conf.png" width="500"></kbd>

### Validation

1. Create a protection group under **Protection Management > Website Protection**:
<kbd><img src="img/prod_group_conf.png" width="500"></kbd>

2. Add a website configuration:
<kbd><img src="img/prod_website_conf.png" width="500"></kbd>

3. Run test script on JXLOG server:
```bash
cd waf_test/
python3 waf_poc_test.py -u http://47.113.220.170
```

4. Check attack events in **Operations Center > Attack Events**:
<kbd><img src="img/attack_event.png" width="1000"></kbd>

## Performance Testing

### Environment
- Instance: Alibaba Cloud Compute c6
- Specs: 4-core CPU, 8GB RAM
- OS: Debian 12.8

### Results

#### HTTP Performance
```
Requests/sec: 65726.31
Transfer/sec: 16.36MB
```

#### HTTPS Performance
```
Requests/sec: 35161.18
Transfer/sec: 8.75MB
```

## Contributors

- [chenjc](https://github.com/jx-sec)
- [jiongrizi](https://github.com/jiongrizi)
- [thankfly](https://github.com/thankfly)

## BUGs & Feature Requests

- WeChat: 574604532 (Add note "jxwaf")
