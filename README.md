[English](English.md) | 中文

# JXWAF

基于 AI 大模型的 Web 应用防火墙（WAF）。实时分析检测 Web 应用流量，清洗恶意流量后将正常流量转发至业务服务器，保障业务安全稳定运行。

| 资源 | 地址 |
|------|------|
| 产品首页 | https://www.jxwaf.com |
| 产品文档 | https://docs.jxwaf.com |
| 策略仓库 | https://hub.jxwaf.com |
| 技术分享 | [AI 大模型语义缓存技术分享](https://mp.weixin.qq.com/s/eGFhzsFtSwRhShwgh9j0mg) |

## 核心技术

- **AI 安全模型**：多维稀疏注意力 + 在线蒸馏，将大模型检测能力继承至本地推理引擎，支持 0day 自动检测与误报自动处理，纯 CPU 运行。
- **语义分析引擎**：上下文语义动态分析，防御 SQL 注入、XSS、命令/代码执行、反序列化等攻击。
- **SSL 行为分析引擎**：SSL 指纹与握手行为分析，识别非浏览器访问，检测 CC 与爬虫流量。
- **WebTDS 实时分析**：毫秒级威胁分析，可视化策略配置实现 APT 检测、爬虫对抗与业务风控。

## 产品线一览

| 维度 | 标准版 | 专业版 | WebTDS |
|------|--------|--------|--------|
| 部署架构 | 一台服务器跑全部子系统 | 控制台 / 节点 / 日志分离部署 | 控制台 / 节点 / 日志分离部署 |
| 日志存储 | MySQL | ClickHouse | ClickHouse |
| 扩展方式 | 单节点 | 节点集群水平扩展 | 节点横向扩展 |
| 典型场景 | 个人站点、小型企业 | 中大型企业、高并发业务 | APT 检测、爬虫对抗、业务风控 |
| 仓库目录 | `Standard/` | `Professional/` | `WebTDS/` |
| 产品文档 | [标准版文档](https://docs.jxwaf.com/jxwaf-standard/Product-Introduction.html) | [专业版文档](https://docs.jxwaf.com/jxwaf-professional/Product-Introduction.html) | [WebTDS 文档](https://docs.jxwaf.com/webtds/Product-Introduction.html) |

## 快速开始

### 标准版：单机一键部署

标准版把 WAF 节点、控制台、MySQL、日志采集、网络封禁与证书服务打包进一个编排文件。

环境要求：Debian 12.x / Ubuntu 20.04+，4 核 8G 以上，已安装 Docker 与 Docker Compose。

```bash
# 1. 安装 Docker（已安装可跳过）
curl -fsSL https://get.docker.com | bash -s docker --mirror Aliyun

# 2. 克隆仓库（中国大陆用加速地址，海外直连 GitHub）
git clone --depth=1 https://gh.jxwaf.top/https://github.com/jx-sec/jxwaf.git
# 海外直连：git clone --depth=1 https://github.com/jx-sec/jxwaf.git
# 源码包（国内）：wget https://gh.jxwaf.top/https://github.com/jx-sec/jxwaf/archive/refs/heads/master.zip
# 源码包（海外）：wget https://github.com/jx-sec/jxwaf/archive/refs/heads/master.zip
cd jxwaf/Standard

# 3. 修改默认凭据后启动
vim docker-compose.yml
docker compose up -d
```

部署完成后访问 `http://<服务器IP>:8000`，系统会自动跳转到注册页面，创建首个管理员账号即可。

四种防护模式可随时切换：**模型训练**（只学习不处置）、**日常防护**（业务优先）、**重保防护**（安全优先）、**离线防护**（不连接模型服务）。

详细步骤见 [标准版部署教程](https://docs.jxwaf.com/jxwaf-standard/Deployment-Tutorial.html)。

### 专业版：控制台 / 节点 / 日志分离部署

按顺序在三台服务器上部署，先控制台、再节点、最后日志服务：

```bash
# 克隆仓库（中国大陆用加速地址；海外直连与源码包地址见上方标准版段落）
git clone --depth=1 https://gh.jxwaf.top/https://github.com/jx-sec/jxwaf.git

# 1. 控制台（同时获取 waf_auth，供节点配置使用）
cd jxwaf/Professional/jxwaf_admin_server
vim docker-compose.yml      # 修改 MySQL 密码等配置
docker compose up -d

# 2. 每台节点服务器
cd jxwaf/Professional/jxwaf_node
vim docker-compose.yml      # JXWAF_SERVER = 控制台地址；WAF_AUTH = 控制台 waf_auth
docker compose up -d

# 3. 日志服务器
cd jxwaf/Professional/jxlog
docker compose up -d
```

控制台部署后访问 `http://<控制台公网IP>`，按页面提示注册首个管理员账号；登录后从 **系统管理 → 基础信息** 获取 `waf_auth`。日志部署完成后，还需在控制台完成日志传输配置与日志查询配置，填写日志服务器地址与端口（`8877` / `9004`）。

详细步骤、环境变量与升级方式见 [专业版部署教程](https://docs.jxwaf.com/jxwaf-professional/Deployment-Tutorial.html)。

### WebTDS：实时威胁分析

WebTDS 基于自研实时分析引擎，无需编写代码，通过控制台配置检测策略即可实现实体行为分析、APT 持续威胁检测、爬虫对抗与业务风险分析；支持在线学习训练专属安全模型。它既可独立部署，也可由专业版对接。

```bash
# 克隆仓库（中国大陆用加速地址；海外直连与源码包地址见上方标准版段落）
git clone --depth=1 https://gh.jxwaf.top/https://github.com/jx-sec/jxwaf.git

# 1. 控制台（内置 MySQL；开启 HTTPS 时需准备 ssl_certs/server.crt 与 server.key）
cd jxwaf/WebTDS/webtds_server
vim docker-compose.yml
docker compose up -d

# 2. 分析节点（WTDS_SERVER = 控制台地址；WTDS_AUTH = 控制台 wtds_auth）
cd jxwaf/WebTDS/webtds_node
vim docker-compose.yml
docker compose up -d

# 3. 日志服务（wtds_log + ClickHouse）
cd jxwaf/WebTDS/webtds_jxlog
docker compose up -d
```

部署完成后访问 `http://<公网IP>`，系统会自动跳转到注册页面，创建首个管理员账号即可。

详细步骤见 [WebTDS 部署教程](https://docs.jxwaf.com/webtds/Deployment-Tutorial.html)，检测策略可直接从 [策略仓库](https://hub.jxwaf.com) 加载。

## AI 模型服务

JXWAF 标准版 / 专业版控制台默认连接官方免费模型服务 `model.jxwaf.com:39980`。用户也可以进行私有化部署：

```bash
cd jxwaf/Standard   # 或 jxwaf/Professional/jxwaf_admin_server
# 先在 docker-compose-model.yml 的 PLATFORMS 中填入 API Key 与模型名
docker compose -f docker-compose-model.yml up -d
```

私有化需自备 API Key 并承担模型调用费用；详细步骤见 [标准版私有化部署](https://docs.jxwaf.com/jxwaf-standard/Model-Private-Deployment.html) 或 [专业版私有化部署](https://docs.jxwaf.com/jxwaf-professional/Model-Private-Deployment.html)。

## 性能与防护能力测试

### 性能（单节点 4C8G，wrk 4 线程 / 1000 并发 / 60 秒）

| 测试方案 | 标准版 HTTP | 标准版 HTTPS | 专业版 HTTP | 专业版 HTTPS |
|----------|-------------|--------------|-------------|--------------|
| 纯转发（防护全关） | 67,849 | 55,227 | 48,262 | 30,422 |
| AI + 语义引擎 | 36,388 | 31,081 | 31,159 | 21,343 |
| 全部防护模块开启 | 10,574 | 7,739 | 18,462 | 13,253 |

详细压测环境与 wrk 原始输出见 [标准版](https://docs.jxwaf.com/jxwaf-standard/Performance-Test.html) / [专业版](https://docs.jxwaf.com/jxwaf-professional/Performance-Test.html) 性能测试报告。

### 防护能力

BlazeHTTP 横向对比（竞品数据由 BlazeHTTP 公开发布）：

| WAF | 检出率 | 误报率 | 准确率 |
|-----|--------|--------|--------|
| CloudFlare 免费版 | 10.70% | 0.07% | 98.40% |
| ModSecurity PARANOIA 1 | 69.74% | 17.58% | 82.20% |
| SafeLine 免费·平衡 | 71.65% | 0.07% | 99.45% |
| **JXWAF 官方免费模型** | **71.28%** | **0.64%** | **98.81%** |
| **JXWAF 私有部署模型** | **69.91%** | **0.20%** | **99.22%** |

基于 [PayloadsAllTheThings](https://github.com/swisskyrepo/PayloadsAllTheThings) 的 477 项测试覆盖 36 种攻击分类，成功拦截 461 项，**综合通过率 96.6%**。

详细分类通过率与未通过样本见 [标准版防护能力测试报告](https://docs.jxwaf.com/jxwaf-standard/Protection-Capability-Test.html)。

## 社区支持

### 微信公众号

<p align="center"><img src="img/wx_code.jpeg" width="200"></p>

## 贡献者

- [青冰](https://github.com/jx-sec)
- [jiongrizi](https://github.com/jiongrizi)

## 问题反馈

- GitHub Issues：https://github.com/jx-sec/jxwaf/issues
- 微信 `574604532`（添加请备注 jxwaf）
