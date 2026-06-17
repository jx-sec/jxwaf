[English](English.md) | 中文

# JXWAF 专业版

基于 AI 大模型的 Web 应用防火墙，实时分析检测 Web 应用流量，清洗恶意流量后正常转发至业务服务器，保障业务安全稳定运行。

🌟 **AI 安全模型** | **语义分析引擎** | **SSL 行为分析引擎** | **WebTDS 实时分析**

> 📖 完整使用文档请访问 **[https://docs.jxwaf.com](https://docs.jxwaf.com)**

> 🔗 **在线体验**：[https://waf-demo.jxwaf.com](https://waf-demo.jxwaf.com)  
> 账号：`demo`　密码：`123456`
<table align="center">
  <tr>
    <td align="center"><b>网站防护</b></td>
    <td align="center"><b>Web安全报表</b></td>
  </tr>
  <tr>
    <td><img src="img/console-dashboard1.png" width="380"></td>
    <td><img src="img/console-dashboard2.png" width="380"></td>
  </tr>
  <tr>
    <td align="center"><b>Web防护引擎配置</b></td>
    <td align="center"><b>流量防护引擎配置</b></td>
  </tr>
  <tr>
    <td><img src="img/console-dashboard3.png" width="380"></td>
    <td><img src="img/console-dashboard4.png" width="380"></td>
  </tr>
  <tr>
    <td align="center"><b>攻击事件</b></td>
    <td align="center"><b>AI模型蒸馏记录</b></td>
  </tr>
  <tr>
    <td><img src="img/console-dashboard5.png" width="380"></td>
    <td><img src="img/console-dashboard6.png" width="380"></td>
  </tr>
</table>


## 产品亮点

### AI 安全模型
基于自研多维稀疏注意力机制与在线蒸馏技术，将大模型检测能力高效继承至本地推理引擎，实现 **高并发、低成本、低幻觉** 的 Web 安全检测。支持 **0day 自动检测** 与 **误报自动处理**，显著降低运营成本。

### 语义分析引擎
采用上下文语义动态分析技术，突破传统正则匹配局限，**精准识别攻击、大幅降低误报**。有效防御 SQL 注入、XSS、命令执行、代码执行及高危 NDay 漏洞利用等。

### SSL 行为分析引擎
基于全新 SSL 指纹算法与协议异常行为分析，快速识别非浏览器访问，有效检测 **CC 攻击**、**爬虫访问** 等异常流量。

### WebTDS 实时分析
对接 Web 流量威胁感知系统，自研实时大数据分析引擎实现毫秒级威胁分析（性能远超通用流处理系统）。无需编码，通过策略配置即可实现 **APT 检测**、**高级爬虫防护** 及 **业务安全风险分析**。

## 系统架构

JXWAF 由三个独立部署的子系统组成：

- **JXWAF 控制台（jxwaf_admin_server）** – Web 可视化运营界面，站点接入管理、策略配置、报表展示。
- **JXWAF 节点（jxwaf_node）** – 基于 OpenResty 的高性能流量代理与实时攻击检测引擎，支持集群与弹性伸缩。
- **JXLOG 日志系统（jxlog）** – 基于 Go 的轻量级日志采集，使用 ClickHouse 存储，支持事件分析与报表统计。

<p align="center"><img src="img/console-architecture.png" width="720"></p>

## 快速部署

### 环境要求

| 项目 | 要求 |
|------|------|
| 操作系统 | Debian 12.x |
| 最低配置 | 4 核 8G |
| 依赖 | Docker、Docker Compose |

> 所有组件均通过 Docker Compose 部署，请确保 Docker 已正确安装。  
> 安装命令：`curl -fsSL https://get.docker.com | bash -s docker --mirror Aliyun`

### 1. JXWAF 控制台部署

```bash
git clone https://github.com/jx-sec/jxwaf.git
cd jxwaf/Professional/jxwaf_admin_server/

# 根据需求修改 docker-compose.yml（如 MySQL 密码、HTTPS 开关）
vim docker-compose.yml

docker compose up -d
```

部署后访问 `http://<公网IP>`，首次访问需注册账号（强烈建议开启 OTP 双因素认证）。  
登录后前往 **系统管理 → 基础信息** 获取 `waf_auth`，后续节点配置使用。

#### 关键环境变量

- `MYSQL_ROOT_PASSWORD` – MySQL root 密码（生产环境务必修改）
- `OPEN_REGIST` – 是否开放注册（`false` 禁止新用户注册）
- `JXWAF_MODEL_SERVER_HOST` / `JXWAF_MODEL_SERVER_PORT` / `JXWAF_MODEL_SERVER_SSL` – AI 模型服务连接参数

### 2. JXWAF 节点部署

```bash
cd jxwaf/Professional/jxwaf_node

# 编辑 docker-compose.yml，修改：
#   JXWAF_SERVER = 控制台地址（如 http://47.120.63.196）
#   WAF_AUTH      = 控制台获取的 waf_auth
#   HTTP_PORT / HTTPS_PORT = 监听端口（支持逗号分隔）
vim docker-compose.yml

docker compose up -d
```

启动后在控制台 **运营中心 → 节点状态** 可查看节点是否上线。

#### 关键环境变量

**jxwaf_base 容器**：
- `HTTP_PORT` / `HTTPS_PORT` – 监听端口，多端口逗号分隔
- `JXWAF_SERVER` – 控制台地址（末尾不带 `/`）
- `WAF_AUTH` – 控制台认证密钥

**jxwaf_nft_node 容器**：
- `WAF_SERVER_URL` – 控制台地址
- `WAF_AUTH` – 控制台认证密钥
- `SYNC_INTERVAL` – 配置同步间隔（秒）

### 3. JXLOG 日志系统部署

```bash
cd jxwaf/Professional/jxlog
docker compose up -d
```

部署后，在控制台完成以下配置：

**系统配置 → 日志传输配置**（攻击日志上报到 jxlog）  
| 配置项 | 值 |
|--------|-----|
| 日志服务器地址 | `<jxlog 内网 IP>` |
| 日志服务器端口 | `8877` |

**系统配置 → 日志查询配置**（通过 ClickHouse 查询日志）  
| 配置项 | 值 |
|--------|-----|
| ClickHouse 地址 | `<jxlog 内网 IP>` |
| 端口 | `9004` |
| 用户名 / 密码 | `jxlog` / `jxlog`（生产环境务必修改） |
| 数据库 / 表名 | `jxwaf` / `jxlog` |


## 性能测试（单节点 4C8G）

使用 wrk 对 AI 安全模型服务接口压力测试，结果如下：

| 测试方案 | HTTP QPS | HTTPS QPS | HTTP 损耗 | HTTPS 损耗 |
|----------|----------|-----------|-----------|------------|
| 纯转发（防护全关） | 48,262 | 30,422 | — | — |
| AI 防护 + 语义引擎 | 31,159 | 21,343 | ↓ 35.5% | ↓ 29.8% |
| 全部防护引擎开启 | 18,462 | 13,253 | ↓ 61.7% | ↓ 56.4% |

**结论**  
- 纯转发模式下单节点吞吐量超 **4.8 万 QPS**（HTTP）。  
- 开启 AI 与语义引擎后性能仅下降约 **30%**，极小代价换取深度防御。  
- 全防护模式下仍可支撑 **1.8 万+ QPS**，平均延迟 < 80ms，单核吞吐超 4600 QPS，日均处理超 3 亿请求。  
- 支持集群水平扩展，线性提升吞吐量，适配高并发企业场景。

详细压测原始数据见 [性能测试报告](https://docs.jxwaf.com/jxwaf/Performance-Test.html)。


## 防护能力测试

测试基于 [PayloadsAllTheThings](https://github.com/swisskyrepo/PayloadsAllTheThings) 生成的 477 个攻击 POC，覆盖 36 种分类。

| 指标 | 数值 |
|------|------|
| 测试项目总数 | 477 |
| 成功拦截 | 461 |
| 未通过（漏报） | 16 |
| 综合通过率 | **96.6%** |

主要分类通过率：
- SQL 注入（含 MySQL/MSSQL/Oracle 等）：**100%**
- XSS（含上下文绕过）：**100%**
- 命令注入（含 WAF 绕过）：**95%+**
- 文件包含 / 目录遍历：**100%**
- 反序列化（Java/PHP/Python 等）：**100%**
- 服务端注入（SSTI/SSI/XSLT）：**100%**
- 文件上传（含绕过）：**100%**
- WAF 绕过专项（SQLi/XSS/命令/路径等）：**96%+**

详细分类通过率及未通过样本见 [防护能力测试报告](https://docs.jxwaf.com/jxwaf/Protection-Capability-Test.html)。


## 社区支持

### 捐赠支持

如果 JXWAF 帮助到了您，欢迎微信扫码打赏支持！

<p align="center"><img src="img/sponsor.jpg" width="200"></p>

> 感谢每一位支持者 ❤️

### 微信公众号

关注微信公众号，获取最新更新与技术分享。

<p align="center"><img src="img/wx_code.jpeg" width="200"></p>

### 用户交流群

扫码加入微信用户群，与更多开发者交流讨论。

<p align="center"><img src="img/wx_group.jpg" width="200"></p>

> 群二维码过期或满员时，请联系管理员微信：`574604532`（添加请备注 jxwaf）

## 贡献者

- [chenjc](https://github.com/jx-sec)
- [jiongrizi](https://github.com/jiongrizi)

## 问题反馈

- 微信 `574604532`（添加好友请备注 jxwaf）
