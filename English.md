[中文](README.md) | English

# JXWAF

A Web Application Firewall (WAF) powered by AI large models. It analyses web traffic in real time, scrubs malicious traffic, and forwards clean traffic to your backend servers — keeping your business secure and stable.

| Resource | Link |
|----------|------|
| Product homepage | https://www.jxwaf.com |
| Documentation | https://docs.jxwaf.com |
| Policy repository | https://hub.jxwaf.com |
| Tech article | [Semantic caching for AI large models](https://mp.weixin.qq.com/s/eGFhzsFtSwRhShwgh9j0mg) |

## Core Technology

- **AI security model**: multi-dimensional sparse attention plus online distillation transfers large-model detection capability into a local inference engine, with automatic 0-day detection and automatic false-positive handling — runs on CPU only.
- **Semantic analysis engine**: dynamic context-aware semantic analysis defends against SQL injection, XSS, command/code execution, deserialization and other attacks.
- **SSL behaviour analysis engine**: SSL fingerprint and handshake behaviour analysis identifies non-browser clients and detects CC floods and crawler traffic.
- **WebTDS real-time analytics**: millisecond-level threat analysis with visual policy configuration, enabling APT detection, crawler countermeasures and business risk control.

## Product Lines

| Dimension | Standard Edition | Professional Edition | WebTDS |
|-----------|------------------|----------------------|--------|
| Deployment architecture | All subsystems on a single server | Console / node / log deployed separately | Console / node / log deployed separately |
| Log storage | MySQL | ClickHouse | ClickHouse |
| Scaling | Single node | Node cluster, horizontal scaling | Node horizontal scaling |
| Typical use cases | Personal sites, small businesses | Medium and large enterprises, high-concurrency workloads | APT detection, crawler countermeasures, business risk control |
| Repository directory | `Standard/` | `Professional/` | `WebTDS/` |
| Documentation | [Standard docs](https://docs.jxwaf.com/jxwaf-standard/Product-Introduction.html) | [Professional docs](https://docs.jxwaf.com/jxwaf-professional/Product-Introduction.html) | [WebTDS docs](https://docs.jxwaf.com/webtds/Product-Introduction.html) |

## Quick Start

### Standard Edition: single-server, one-command deployment

The Standard Edition packages the WAF node, console, MySQL, log collection, network blocking and certificate service into a single orchestration file.

Requirements: Debian 12.x / Ubuntu 20.04+, 4 vCPU / 8 GB RAM or more, Docker and Docker Compose installed.

```bash
# 1. Install Docker (skip if already installed)
curl -fsSL https://get.docker.com | bash -s docker --mirror Aliyun

# 2. Clone the repository (mainland China: use the accelerator; overseas: clone from GitHub directly)
git clone --depth=1 https://gh.jxwaf.top/https://github.com/jx-sec/jxwaf.git
# Direct (overseas): git clone --depth=1 https://github.com/jx-sec/jxwaf.git
# Source archive (China): wget https://gh.jxwaf.top/https://github.com/jx-sec/jxwaf/archive/refs/heads/master.zip
# Source archive (overseas): wget https://github.com/jx-sec/jxwaf/archive/refs/heads/master.zip
cd jxwaf/Standard

# 3. Change the default credentials, then start
vim docker-compose.yml
docker compose up -d
```

Once deployed, visit `http://<server-IP>:8000`; the system redirects to the registration page automatically — create the first administrator account there.

Four protection modes can be switched at any time: **Model Training** (learn only, no action), **Daily Protection** (business first), **Major-Event Protection** (security first) and **Offline Protection** (no model service connection).

For detailed steps see the [Standard Edition deployment guide](https://docs.jxwaf.com/jxwaf-standard/Deployment-Tutorial.html).

### Professional Edition: separated console / node / log deployment

Deploy on three servers in order: console first, then nodes, then the log service:

```bash
# Clone the repository (mainland China: use the accelerator; for direct clone and source archives see the Standard Edition section above)
git clone --depth=1 https://gh.jxwaf.top/https://github.com/jx-sec/jxwaf.git

# 1. Console (also provides waf_auth for node configuration)
cd jxwaf/Professional/jxwaf_admin_server
vim docker-compose.yml      # change the MySQL password and other settings
docker compose up -d

# 2. Each node server
cd jxwaf/Professional/jxwaf_node
vim docker-compose.yml      # JXWAF_SERVER = console address; WAF_AUTH = console waf_auth
docker compose up -d

# 3. Log server
cd jxwaf/Professional/jxlog
docker compose up -d
```

After the console is deployed, visit `http://<console-public-IP>` and follow the on-page prompts to register the first administrator account. Once logged in, obtain `waf_auth` from **System Management → Basic Information**. After the log service is deployed, complete the log forwarding and log query configuration in the console, filling in the log server address and ports (`8877` / `9004`).

For detailed steps, environment variables and upgrade instructions see the [Professional Edition deployment guide](https://docs.jxwaf.com/jxwaf-professional/Deployment-Tutorial.html).

### WebTDS: real-time threat analytics

WebTDS is built on a self-developed real-time analytics engine. Without writing any code, you can implement entity behaviour analysis, persistent APT detection, crawler countermeasures and business risk analysis through console policy configuration; it also supports online learning to train a dedicated security model. It can be deployed standalone or connected to the Professional Edition.

```bash
# Clone the repository (mainland China: use the accelerator; for direct clone and source archives see the Standard Edition section above)
git clone --depth=1 https://gh.jxwaf.top/https://github.com/jx-sec/jxwaf.git

# 1. Console (bundled MySQL; ssl_certs/server.crt and server.key are required only if you enable HTTPS)
cd jxwaf/WebTDS/webtds_server
vim docker-compose.yml
docker compose up -d

# 2. Analytics node (WTDS_SERVER = console address; WTDS_AUTH = console wtds_auth)
cd jxwaf/WebTDS/webtds_node
vim docker-compose.yml
docker compose up -d

# 3. Log service (wtds_log + ClickHouse)
cd jxwaf/WebTDS/webtds_jxlog
docker compose up -d
```

Once deployed, visit `http://<public-IP>`; the system redirects to the registration page automatically — create the first administrator account there. Registration requires binding a one-time password (OTP) for two-factor authentication. Node status is shown under **Operations Center → Node Status** in the console.

For detailed steps see the [WebTDS deployment guide](https://docs.jxwaf.com/webtds/Deployment-Tutorial.html); detection policies can be loaded directly from the [policy repository](https://hub.jxwaf.com).

## AI Model Service

The Standard / Professional consoles connect to the official free model service `model.jxwaf.com:39980` by default. Private deployment is also supported:

```bash
cd jxwaf/Standard   # or jxwaf/Professional/jxwaf_admin_server
# First fill in the API key and model names under PLATFORMS in docker-compose-model.yml
docker compose -f docker-compose-model.yml up -d
```

Private deployment requires your own API key and you bear the model invocation costs; see [Standard private model deployment](https://docs.jxwaf.com/jxwaf-standard/Model-Private-Deployment.html) or [Professional private model deployment](https://docs.jxwaf.com/jxwaf-professional/Model-Private-Deployment.html) for details.

## Performance and Protection Tests

### Performance (single node, 4C8G; wrk, 4 threads / 1000 connections / 60 seconds)

| Test scenario | Standard HTTP | Standard HTTPS | Professional HTTP | Professional HTTPS |
|---------------|---------------|----------------|-------------------|--------------------|
| Pure forwarding (all protection off) | 67,849 | 55,227 | 48,262 | 30,422 |
| AI + semantic engine | 36,388 | 31,081 | 31,159 | 21,343 |
| All protection modules enabled | 10,574 | 7,739 | 18,462 | 13,253 |

For the full stress-test environment and raw wrk output see the [Standard](https://docs.jxwaf.com/jxwaf-standard/Performance-Test.html) / [Professional](https://docs.jxwaf.com/jxwaf-professional/Performance-Test.html) performance test reports.

### Protection capability

BlazeHTTP cross-WAF comparison (competitor figures published by BlazeHTTP):

| WAF | Detection rate | False positive rate | Accuracy |
|-----|----------------|---------------------|----------|
| CloudFlare Free | 10.70% | 0.07% | 98.40% |
| ModSecurity PARANOIA 1 | 69.74% | 17.58% | 82.20% |
| SafeLine Free · Balanced | 71.65% | 0.07% | 99.45% |
| **JXWAF official free model** | **71.28%** | **0.64%** | **98.81%** |
| **JXWAF self-hosted model** | **69.91%** | **0.20%** | **99.22%** |

The 477 test cases based on [PayloadsAllTheThings](https://github.com/swisskyrepo/PayloadsAllTheThings) cover 36 attack categories; 461 were blocked, an **overall pass rate of 96.6%**.

For detailed category pass rates and missed samples see the [Standard Edition protection capability report](https://docs.jxwaf.com/jxwaf-standard/Protection-Capability-Test.html).

## Community

### WeChat Official Account

<p align="center"><img src="img/wx_code.jpeg" width="200"></p>

## Contributors

- [chenjc](https://github.com/jx-sec)
- [jiongrizi](https://github.com/jiongrizi)

## Feedback

- GitHub Issues: https://github.com/jx-sec/jxwaf/issues
- WeChat `574604532` (please mention jxwaf when adding)
