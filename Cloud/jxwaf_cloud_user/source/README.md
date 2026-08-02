# JXWAF Cloud_user 用户控制台

> JXWAF 云 WAF 的**开源用户控制台**。基于 Cloud 主控台的 User API（`/user/`）构建，提供客户自助管理能力：网站接入、证书管理、防护配置、CDN 缓存、安全日志等。
>
> 本项目为**Go 后端 + Vue3 前端**的单体应用，便于二次开发定制自己的 WAF 控制台。

---

## 一、项目简介

Cloud_user 与 Cloud 主控台的分工：

```
┌──────────────────────┐          ┌──────────────────────┐
│    Cloud_user 控制台   │  HTTP    │  Cloud 主控台（商业版） │
│  （本项目，可开源定制）  │ ──────► │  提供 /user/ User API │
│                      │          │  持有全部业务数据       │
│  前端：Vue3 + Element  │          │                      │
│  后端：Go             │          │                      │
└──────────────────────┘          └──────────────────────┘
```

- **Cloud 主控台**：服务商侧，负责创建子账号（客户）、配置接入配置、下发 `waf_auth`
- **Cloud_user 控制台**：客户侧，本仓库。用户在此登录/注册，管理自己的域名、证书、防护规则与日志

### 核心能力

| 模块 | 说明 |
|---|---|
| 账号 | 注册（自动绑定默认接入配置）、登录（密码 + 可选 OTP）、修改密码、查看 waf_auth |
| 数据统计 | QPS / 带宽 / 时延 / 状态码趋势（折线图）、业务明细 |
| 攻击事件 | 攻击事件列表、攻击行为追踪、Web/Flow 攻击统计 |
| 网站接入 | 域名 CRUD（自动云 DNS 接入）、SSL 证书上传/泛域名申请 |
| 防护配置 | Web 引擎/规则/白名单、流量引擎/规则/白名单、IP 区域封禁、网页防篡改 |
| CDN 功能 | 静态资源缓存、资源预热、资源刷新 |
| 日志查询 | 请求日志检索（多条件过滤） |

---

## 二、目录结构

```
Cloud_user/
├── main.go                  程序入口（路由装配、静态资源、启动）
├── internal/                后端服务代码
│   ├── config.go            配置加载
│   ├── cloudapi.go          Cloud API 客户端
│   ├── handlers.go          路由与请求处理
│   ├── session.go           会话管理
│   ├── database.go          可选 MySQL 连接
│   └── response.go          统一响应格式
├── front-end/               前端源码（Vue3 + Vite + Element Plus）
│   └── src/
│       ├── views/           页面组件（按模块命名）
│       ├── components/      公共组件（如 MatchConditionBuilder）
│       ├── assets/scripts/  请求封装（JXAjax）、校验函数
│       └── router/          路由配置
├── static/                  前端构建产物（发布时由脚本生成）
├── conf/waf_config.json     默认配置（实际配置以环境变量为准）
├── Dockerfile               Go 二进制 + 静态资源镜像
├── docker-compose.yml       部署编排（环境变量注入）
└── build.sh                 构建脚本（前端/二进制/Docker）
```

---

## 三、快速开始

### 3.1 前置条件

1. 已部署 **Cloud 主控台**，并在主控台完成：
   - 创建**网站接入配置**（记录配置名）
   - 开启环境变量 `USER_API_ENABLE=true`（Cloud_user 依赖 `/user/` 接口）
2. 获取主账号 `waf_auth`（在主控台「waf_auth 管理」页面查看/设置）

### 3.2 Docker 部署

修改 `docker-compose.yml` 中的环境变量后启动：

```bash
docker compose up -d
```

**环境变量**：

| 环境变量 | 必填 | 说明 |
|---|---|---|
| `CLOUD_API_URL` | 是 | Cloud 主控台地址，如 `http://<cloud_host>:8000` |
| `CLOUD_API_KEY` | 是 | 主账号 `waf_auth` |
| `DEFAULT_WEBSITE_ACCESS_CONF` | 是 | 默认接入配置名，注册子账号时自动绑定，需与主控台创建的配置名一致 |
| `HTTP_PORT` | 否 | 监听端口，默认 `8080` |
| `SESSION_SECRET` | 否 | 会话密钥，未配置时自动生成随机密钥 |
| `MYSQL_HOST` 等 | 否 | 可选：MySQL 连接（仅当 Cloud 登录接口不返回 waf_auth 时需要，见下） |
| `TZ` | 否 | 时区，默认 `Asia/Shanghai` |

> **MySQL 是否必需？**
> - 绝大多数场景下 Cloud 登录接口会返回 `waf_auth` → **无需 MySQL**（推荐）
> - 仅当你的 Cloud 版本登录接口不返回 waf_auth 时，才需配置 MySQL 用于反查子账号 waf_auth

### 3.3 本地开发

```bash
# 1. 启动后端（先设置环境变量）
CLOUD_API_URL=http://127.0.0.1:8000 \
CLOUD_API_KEY=your_main_waf_auth \
DEFAULT_WEBSITE_ACCESS_CONF=your_access_conf \
go run main.go

# 2. 启动前端（Vite dev server，代理 /api 与 /user 到后端 8080）
cd front-end
npm install
npm run dev
# 访问 http://127.0.0.1:3000
```

前端开发代理目标默认 `http://127.0.0.1:8080`（与后端 `HTTP_PORT` 默认值一致），可通过 `VITE_API_TARGET` 覆盖（见 `front-end/vite.config.js`）。

---

## 四、构建与发布

### 4.1 本地构建

```bash
./build.sh               # 构建前端 + Docker 镜像
./build.sh frontend      # 仅构建前端（产物到 static/）
./build.sh binary        # 仅构建 Go 二进制
./build.sh docker        # 仅构建 Docker 镜像
```

### 4.2 构建并推送自己的 Docker 镜像

```bash
./build.sh        # 构建前端 + Docker 镜像
docker tag jxwaf_user_console:latest <你的镜像仓库>/jxwaf_user_console:1.0
docker push <你的镜像仓库>/jxwaf_user_console:1.0
```

流程：构建前端 → 复制到 `static/` → 构建镜像 → 推送到自己的镜像仓库。

---

## 五、二次开发指南

本项目面向「AI 辅助开发」设计，配套文档如下：

| 文档 | 说明 |
|---|---|
| [AGENTS.md](AGENTS.md) | **AI Agent 开发指南**：架构说明、代码职责、新增页面/接口的完整流程、开发约定、常见问题 |
| [docs/API_REFERENCE.md](docs/API_REFERENCE.md) | 本地 `/api/*` 接口清单：请求参数、响应格式、与 Cloud `/user/*` 接口的映射 |

### 典型定制场景

- **改品牌**：替换 `front-end/src/assets/images/` 下的 logo，修改 `App.vue` 中的控制台名称
- **新增菜单/页面**：仅需改前端 `views/` + `router/index.js`，后端无需改动（详见 AGENTS.md）
- **新增业务接口**：Cloud 主控台新增 `/user/` 接口后，前端直接调用即可

---

## 六、开源协议

- 本仓库遵循 **GPL v2**（见 [LICENSE](LICENSE)）
- 依赖的 Cloud 主控台为商业产品，本仓库仅通过其公开的 `/user/` User API 对接，不包含主控台代码
