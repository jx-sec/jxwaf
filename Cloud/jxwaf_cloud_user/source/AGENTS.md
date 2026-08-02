# AGENTS.md — JXWAF Cloud_user 开发指南

> 本文件是 **AI 编码 Agent** 与人工开发者在本仓库工作的权威指南。开始任何开发任务前，请先阅读本文。
>
> 目标：让 AI 能够独立、正确地完成「新增页面」「新增接口」「修改业务逻辑」等任务，避免破坏既有架构与约定。

---

## 1. 项目一句话

Cloud_user 是 JXWAF 云 WAF 的开源用户控制台：**Vue3 前端 + Go 后端**。Go 后端不做业务存储，仅做「会话管理 + 反向代理」，把所有业务请求转发到 Cloud 主控台的 `/user/` API。

```
浏览器 ──► Cloud_user Go 后端 ──(双Token)──► Cloud 主控台 /user/ API
             │ 本地路由 /api/*（仅会话 + CDN 预热/刷新）
             └─ 会话(Cookie) / 登录注册 / 静态资源
```

**重要推论**：
- 所有业务数据都在 Cloud 主控台侧，本仓库**不含数据库表结构**（MySQL 仅为可选回退）
- 新增业务功能时，先确认 Cloud 侧是否已有对应 `/user/` 接口；没有则需要主控台先提供（不在本仓库范围）
- 后端只是「薄代理」，**不要在后端复制业务逻辑**

---

## 2. 技术栈

| 层 | 技术 |
|---|---|
| 前端 | Vue 3（Composition API）、Vite、Element Plus、ECharts、vue-router、axios |
| 后端 | Go 1.24+，标准库 `net/http`，仅依赖 `github.com/go-sql-driver/mysql` |
| 构建 | `build.sh`（前端 npm build → static/，Go build，Docker build） |

---

## 3. 目录职责

```
Cloud_user/
├── main.go                 入口：加载配置、装配路由、托管静态资源
├── internal/
│   ├── config.go           环境变量 → ServerConfig（必填校验）
│   ├── cloudapi.go         CloudClient：Post/PostWithMainAuth，双 Token 鉴权
│   ├── handlers.go         【核心】所有 /api/* 路由注册与代理逻辑
│   ├── session.go          SessionStore：内存会话 + Cookie + TTL 清理
│   ├── database.go         可选 MySQL：GetSubWafAuth / GetUserNameByWafAuth
│   └── response.go         统一响应：FailResponse / SuccessResponse / RawResponse
├── front-end/
│   └── src/
│       ├── main.js         入口（注册 Element Plus + 图标）
│       ├── App.vue         布局（侧边栏菜单 + Header），登录/注册页独立布局
│       ├── router/index.js 路由表（meta.requiresAuth 控制访问）
│       ├── views/          页面组件（文件名 = 功能名，如 domain.vue）
│       ├── components/     公共组件（MatchConditionBuilder.vue 等）
│       └── assets/scripts/common.js   JXAjax 请求封装、校验函数、工具函数
└── static/                 前端构建产物（勿手改，由 build.sh 生成）
```

---

## 4. 后端架构（Go）

### 4.1 请求链路

```
HTTP 请求 POST /user/get_domain_list（前端直连业务接口）
  → main.go /user/ 路由
  → Handler.genericUserProxy（会话模式校验）
  → 校验会话（Cookie → SessionStore.GetFromRequest）
  → 透传 body，调用 cloud.Post(path, body, session)
      ├─ Header: jxwaf-waf-auth      = CLOUD_API_KEY（主账号 waf_auth）
      └─ Header: jxwaf-sub-waf-auth  = session.SubWafAuth（子账号 waf_auth）
  → 200：RawResponse 原样透传 Cloud 响应 JSON
  → 非 200 / 网络错误：FailResponse（中文提示）
```

> **重要**：前端直接调用 `POST /user/<cloud接口名>`，路径与 Cloud 接口完全一致，后端不重命名、不做本地 `/api/<资源>/<动作>` 中转。业务代理只保留 `genericUserProxy` 一个入口。

> **路由行为**：`/user/` 前缀仅 POST 请求走代理，其余方法返回前端 SPA（前端路由）；根路径 `/` 上未匹配的 POST `/api/*` 直接返回 404。

### 4.2 两种代理模式（main.go + handlers.go）

| 模式 | 函数 | 用途 | 示例 |
|---|---|---|---|
| 直连透传（会话） | `genericUserProxy` | 任意 `/user/` POST 透传，需子账号会话双层鉴权 | 前端所有业务接口 `/user/get_domain_list` 等 |
| 本地实现 | `Login` / `Register` / `Logout` / `CheckSession` / `GetOtpQrUrl` | 仅主账号鉴权或本地会话流程 | `/api/login`、`/api/register` 等 |

### 4.3 特殊路由（非简单一对一）

| 路由前缀 | 处理函数 | 说明 |
|---|---|---|
| `/api/cdn_warmup/<action>` | `cdnWarmupRoute` | 预热任务（list / create / detail / delete） |
| `/api/cdn_refresh/<action>` | `cdnRefreshRoute` | 刷新任务（list / create / detail / delete） |
| `/api/login` `api/register` `api/check_session` `api/get_otp_qr_url` `api/logout` | 本地实现 | 会话/账号流程（见 4.4） |

### 4.4 会话与账号流程

- **登录** `POST /api/login`：调用 Cloud `/user/sub_account_login`（主账号鉴权）→ 成功取 `waf_auth` → 创建 Session → 写 Cookie → 返回 `{result, message, waf_auth}`
- **登录（MySQL 回退）**：若 Cloud 未返回 `waf_auth`，且配置了 MySQL，则先用主账号 waf_auth 反查 `user_name`，再查子账号 `waf_auth`（见 `database.go`）
- **OTP（可选）**：`/api/get_otp_qr_url` 生成 `otp_secret_key`（用于扫码绑定）；登录时传 `otp_auth_code` 一并校验
- **注册** `POST /api/register`：自动注入 `website_access_conf = DEFAULT_WEBSITE_ACCESS_CONF` → 调用 Cloud `/user/sub_account_register` → **不创建会话**（注册成功跳登录页，见前端约定）
- **会话** `POST /api/check_session`：校验 Cookie 有效性，返回 `{result, data: {sub_user_name}}`
- 会话 Cookie：`jxwaf_user_session`，HttpOnly，TTL 24h，每次访问滑动续期；会话密钥可用环境变量 `SESSION_SECRET` 指定（未配置时自动生成）
- `SessionStore` 为内存实现，重启即失效，不可横向扩展（如需要可自行替换为 Redis）

### 4.5 新增接口（标准流程）

**业务接口（绝大多数情况）**：
1. 确认 Cloud 侧 `/user/` 接口存在（参考 `docs/API_REFERENCE.md`）
2. 前端直接 `JXAjax('post', '/user/<cloud接口名>', ...)` 调用，**无需改 Go 代码**
3. 后端 `genericUserProxy` 已覆盖所有 `/user/` POST 透传

**本地接口（仅限会话类或需要多资源映射时）**：
1. 在 `handlers.go` 的 `RegisterRoutes` 中注册：
   ```go
   mux.HandleFunc("/api/<名称>", h.<本地handler>)
   ```
2. 会话校验用 `h.sessions.GetFromRequest(r)`，转发 Cloud 用 `h.cloud.Post(path, body, session)` 或 `PostWithMainAuth`
3. 编译验证：`go build ./...`

> 业务接口不要在后端新写代理路由，直接走 `/user/*` 透传；只有「本地会话相关」或「需要映射多资源」的接口才写专门 handler。

---

## 5. 前端架构（Vue3）

### 5.1 页面结构

每个页面通常是一个独立的 `.vue` 文件（列表页 + 编辑页）。标准模式：

```
<script setup> 或 Options API
  ├─ 页面状态（搜索条件、表格数据、分页）
  ├─ 数据加载：JXAjax('post', '/user/<接口名>', {page}, cb)
  └─ 增删改：调用 /user/<接口名>，成功后刷新列表
<template>
  ├─ 搜索栏（el-form inline）
  ├─ 数据表格（el-table + 分页 el-pagination）
  └─ 对话框/抽屉（编辑表单 el-dialog）
```

### 5.2 请求封装 JXAjax（必须使用）

所有后端请求**必须**走 `assets/scripts/common.js` 导出的 `JXAjax`：

```js
import { JXAjax } from '../assets/scripts/common'

JXAjax('post', '/user/get_domain_list', { page: 1 },
  function (response) {
    // 成功：response.data 已保证 result === true
    // 列表接口数据在 response.data.records / total_records
  },
  function () {
    // 失败：已自动弹出错误提示，这里做业务回滚即可
  }
)
```

**JXAjax 内置行为**（不要重复实现）：
- 自动判断 `result === true` / `code === 200` 为成功
- 自动弹出成功/失败 ElMessage（`messageStatus: 'no-message'` 可静默）
- 认证失效自动跳转登录页（错误消息命中内置认证错误列表时）
- 登录成功（`/api/login`）自动写本地登录态

### 5.3 本地登录态

```js
import { setLoggedIn, clearSession, getUserName } from '../assets/scripts/common'
```

| 函数 | 作用 |
|---|---|
| `setLoggedIn(username)` | 登录成功后调用，写 sessionStorage + localStorage |
| `clearSession()` | 退出/失效时清空 |
| `getUserName()` | 读取当前用户名 |

**约定**：
- 登录态只在**登录成功**时设置；注册成功**不得**设置登录态，应提示后跳转「立即登录」页
- 路由守卫（`router/index.js`）依据 `localStorage.getItem('isLogin')` 判断，`requiresAuth` 标记需登录页面

**页面登录态校验（mixin，必须引入）**：所有业务页面均 `mixins: [mixin]`（从 `common.js` 导入），组件 mounted 时自动调用 `/api/check_session` 校验登录态，未登录自动跳转登录页。新页面务必按 5.6 步骤引入 `mixin`，否则刷新后登录态可能失效。

### 5.4 表单校验函数（common.js 已提供）

签名固定为 `(rule, value, callback)`（Element Plus 要求），**不要**写成 `(value)`：

| 函数 | 用途 |
|---|---|
| `validateRuleName` | 规则名：字母开头，字母/数字/`_`/`-` |
| `validatePositiveInt` | 正整数 |
| `validatePort` | 1~65534 |
| `validateDomainPort` | 域名/IP 输入合法性 |

### 5.5 规则匹配条件组件

涉及 `rule_matchs` 的页面**必须**使用 `components/MatchConditionBuilder.vue`（可视化匹配条件构建器），**禁止**让用户直接编辑 JSON。

### 5.6 新增前端页面（标准流程）

1. 在 `views/` 创建页面文件（参考同类已有页面，如 `web-rule-protection.vue`）
2. 在 `router/index.js` 注册路由（`meta: { requiresAuth: true }`）
3. 在 `App.vue` 侧边栏菜单添加菜单项
4. 调用接口：直接 `JXAjax('post', '/user/<接口名>', ...)`（业务接口无需后端路由，见 `docs/API_REFERENCE.md`；本地会话/预热刷新类才用 `/api/*`）
5. 校验：`npm run dev` 手测 + `npm run build` 确认无编译错误

---

## 6. 响应格式与错误约定

Cloud 主控台统一响应（经代理原样透传）：

```json
{ "result": true,  "message": "..." }                        // 操作成功
{ "result": false, "message": "错误原因" }                     // 失败
{ "result": true,  "records": [...], "page": 1,              // 分页列表
  "total_pages": 5, "total_records": 250 }
{ "result": true,  "message": { ... } }                      // 单条详情
```

前端处理原则：
- 判断成功一律用 `result === true`
- 展示错误用 Cloud 返回的 `message`（已是中文，如 `domain is exist` → 需在页面映射为中文提示或直接展示）
- 后端代理层错误（未登录/网络异常）返回中文：`未登录或会话已过期，请重新登录`、`请求后端服务失败` 等

---

## 7. 开发约定（硬性要求）

1. **命名**：文件/函数/接口与 Cloud 接口名保持一致（domain / web_rule / ssl / usage_stat...）；Go 函数用驼峰，前端文件用小写连字符
2. **所有业务请求走 JXAjax**，禁止裸用 axios（登录态/错误处理会失效）
3. **禁止暴露内部字段**：用户界面不得出现 `jxwaf_devid`、`waf_node_uuid`、`user_name` 等内部字段；字段名映射为中文标签
4. **产品名**：界面统一显示 `JXWAF`（全大写）
5. **UI 一致性**：新页面复用 Element Plus 组件与既有页面的布局/间距/配色；统计类图表用折线图，单位与数值直接关联
6. **rule_matchs** 一律可视化配置（MatchConditionBuilder），页面不出现 JSON 输入框
7. **不添加未要求的功能**：只实现任务要求的页面/接口，不擅自加菜单或功能
8. **修改后验证**：至少 `go build ./...`（后端）与 `cd front-end && npm run build`（前端）通过

---

## 8. 构建与验证命令

```bash
# 后端
go build ./...
go vet ./...

# 前端
cd front-end
npm install
npm run build      # 编译校验（有语法/引用错误会失败）

# 整体
./build.sh binary        # 仅 Go 二进制
./build.sh frontend      # 仅前端
./build.sh               # 全部
```

---

## 9. 常见问题（FAQ）

| 问题 | 原因与解决 |
|---|---|
| 页面报 `未登录或会话已过期` | Cookie 会话丢失/过期，重新登录；或接口错误地用了需会话的代理而页面未登录 |
| 接口返回 `invalid jxwaf_sub_waf_auth` | 子账号 waf_auth 失效：主控台重置过 waf_auth，需重新登录获取 |
| 登录报 `认证服务暂时不可用` | Cloud 侧 `/user/sub_account_login` 不可达：检查 `CLOUD_API_URL`、主控台 `USER_API_ENABLE=true` |
| 注册成功但登录提示无权限 | 注册未绑定接入配置：检查 `DEFAULT_WEBSITE_ACCESS_CONF` 是否与主控台配置一致 |
| 接口 404 | 业务接口：Cloud 侧无对应 `/user/` 接口（检查主控台是否提供）；本地接口：未在 `RegisterRoutes` 注册 |
| 登录态错乱 | 注册流程误调 `setLoggedIn`：注册成功只跳转登录页，不设置登录态 |

---

## 10. AI 修改代码前的检查清单

- [ ] 是否先阅读了本文档与相关文件？（不要凭猜测改代码）
- [ ] 该功能 Cloud 侧是否有对应 `/user/` 接口？参数/响应是否与 `docs/API_REFERENCE.md` 一致？
- [ ] 后端改动是否只是一行代理？若不是，说明原因
- [ ] 前端是否使用 JXAjax？是否误用 JSON 输入框？是否泄露内部字段？
- [ ] 是否运行了 `go build ./...` 与 `npm run build` 验证？
- [ ] 是否遵守「不添加未要求的功能」原则？
