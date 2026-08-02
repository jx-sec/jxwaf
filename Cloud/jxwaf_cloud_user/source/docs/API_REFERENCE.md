# JXWAF Cloud_user 本地 API 接口参考

> 本文件描述 Cloud_user 后端对外暴露的接口：**本地 `/api/*` 接口**（会话、CDN 预热/刷新）与 **Cloud `/user/*` 直连接口**（全部业务接口，经 `genericUserProxy` 透传）。
>
> 所有接口均为 **POST** + `application/json`。
>
> 完整字段定义（rule_matchs / filter / source_ip / 枚举值等）见 Cloud 主控台的 `USER_API_DOCUMENT.md` 第十四章，业务接口的详细参数与响应格式均以该文档为准。

---

## 一、总体架构与调用模式

Cloud_user 为薄代理架构，业务数据全部来自 Cloud 主控台。对外暴露三种调用模式：

| 模式 | 路径 | 说明 |
|---|---|---|
| 直连透传 | `POST /user/*` | 前端直接调用 Cloud `/user/*` 业务接口，后端 `genericUserProxy` 校验本地会话后自动注入双层 Header 透传，响应原样返回 |
| 本地会话 | `POST /api/login` 等 5 个 | 登录/注册/登出/会话校验/OTP，由 Go 本地处理（仅需主账号认证） |
| CDN 预热/刷新 | `POST /api/cdn_warmup/*`、`POST /api/cdn_refresh/*` | Go 将路径映射为 Cloud `/user/` 缓存接口后透传 |

**注意**：早期版本曾在本地实现 `/api/domain/*`、`/api/web_rule/*` 等业务中转路由，现已全部删除。调用业务接口请直接使用 `POST /user/*`，否则返回 `API not found`。

---

## 二、认证与会话

### 2.1 本地会话接口

| 接口 | 说明 |
|---|---|
| `POST /api/login` | 登录：验证子账号密码（+OTP），成功后创建本地会话并写 Cookie |
| `POST /api/register` | 注册：注入默认接入配置后转发 Cloud，**不创建会话** |
| `POST /api/logout` | 退出：销毁本地会话 |
| `POST /api/check_session` | 校验会话：返回 `{result, data: {sub_user_name}}` |
| `POST /api/get_otp_qr_url` | 获取 OTP 绑定二维码 URL 与密钥（本地生成） |

**登录请求参数**：`sub_user_name`、`user_password`、`otp_auth_code`（OTP 开启时必填）

**登录响应**：

```json
{"result": true, "message": "sub_user_name", "waf_auth": "<子账号waf_auth>"}
```

> **OTP 接口说明**：Cloud 主控台虽然注册了 `/user/get_otp_qr_url`，但本服务改用本地 `/api/get_otp_qr_url` 实现（密钥由 Go 本地 `crypto/rand` 生成，不透传 Cloud），两者不重叠。前端统一调用 `/api/get_otp_qr_url`。

### 2.2 双层鉴权

`/user/*` 透传时，后端自动携带（开发者无需在请求中传）：

```
jxwaf-waf-auth:      <主账号 waf_auth>（CLOUD_API_KEY 配置）
jxwaf-sub-waf-auth:  <子账号 waf_auth>（登录会话持有）
```

> 请求头名称使用**连字符**。Cloud 侧 nginx 通过 `$http_jxwaf_waf_auth` 读取，默认 `underscores_in_headers off`，带下划线的头会被丢弃。

---

## 三、统一响应格式

Cloud 主控台响应经后端透传，四种格式：

| 类型 | 格式 |
|---|---|
| 操作成功 | `{"result": true, "message": "..."}` |
| 失败 | `{"result": false, "message": "错误原因"}` |
| 分页列表 | `{"result": true, "records": [...], "page": 1, "total_pages": 5, "total_records": 250}` |
| 单条详情 | `{"result": true, "message": {对象}}` |

分页约定：列表类接口 pageSize 固定 50；攻击事件/日志查询/业务明细固定 20。

---

## 四、本地 `/api/*` 接口明细

### 4.1 会话类（5 个）

| 接口 | 请求参数 | 响应 |
|---|---|---|
| `POST /api/login` | `sub_user_name, user_password, otp_auth_code` | `{result, message, waf_auth}` |
| `POST /api/register` | `sub_user_name, user_password, sub_otp_auth, otp_auth_code, otp_secret_key`（`website_access_conf` 由后端注入，无需传） | Cloud 原样透传：`{result, message: "register success", waf_auth}` |
| `POST /api/logout` | 无 | `{result: true, message: "已退出登录"}` |
| `POST /api/check_session` | 无（读 Cookie） | `{result: true, data: {sub_user_name}}` |
| `POST /api/get_otp_qr_url` | 无 | `{result, message: "otpauth://...", otp_secret_key}` |

### 4.2 CDN 预热 / 刷新（8 个路由）

| 接口 | Cloud /user/ 接口 | 说明 |
|---|---|---|
| `POST /api/cdn_warmup/list` | `/user/get_cache_warmup_list` | 预热任务列表 |
| `POST /api/cdn_warmup/create` | `/user/create_cache_warmup_task` | 创建预热任务 |
| `POST /api/cdn_warmup/detail` | `/user/get_cache_warmup_detail` | 预热任务详情 |
| `POST /api/cdn_warmup/delete` | `/user/delete_cache_warmup_task` | 删除预热任务 |
| `POST /api/cdn_refresh/list` | `/user/get_cache_refresh_list` | 刷新任务列表 |
| `POST /api/cdn_refresh/create` | `/user/create_cache_refresh_task` | 创建刷新任务 |
| `POST /api/cdn_refresh/detail` | `/user/get_cache_refresh_detail` | 刷新任务详情 |
| `POST /api/cdn_refresh/delete` | `/user/delete_cache_refresh_task` | 删除刷新任务 |

> 请求参数见 Cloud USER_API_DOCUMENT 缓存模块说明。内置前端 `cache-warmup.vue` / `cache-refresh.vue` 通过此组路由调用。

---

## 五、Cloud `/user/*` 直连接口（业务）

以下接口由前端直接 `POST /user/<接口名>` 调用，经 `genericUserProxy` 透传，均需已登录会话。按模块列出内置前端实际使用（✔）及 Cloud 已提供、可被自定义前端调用（○）的接口。

### 5.1 账号与辅助

| 接口 | 标记 | 请求参数 | 说明 |
|---|---|---|---|
| `/user/sub_account_login` | ✔（后端调用） | `sub_user_name, user_password, otp_auth_code` | 登录验证，仅需主账号 Header |
| `/user/sub_account_register` | ✔（后端调用） | `sub_user_name, user_password, website_access_conf, sub_otp_auth, otp_auth_code, otp_secret_key` | 子账号注册，仅需主账号 Header。成功返回 `{result, message: "register success", waf_auth}` |
| `/user/edit_password` | ✔ | `old_password, new_password` | 修改密码 |
| `/user/get_account_info` | ○ | 无 | 子账号基础信息 |
| `/user/get_waf_auth` | ○ | 无 | 获取子账号 waf_auth |
| `/user/api_get_sub_account_list` | ✔ | 无 | 子账号列表（含 waf_auth），SOC 页筛选用 |
| `/user/api_get_global_name_list_list` | ✔ | 无 | 全局名单列表（IP/UA/URL 名单，不分页），规则匹配条件下拉用 |
| `/user/create_global_name_list_item` | ○ | `name_list_name, name_list_item` | 向指定全局名单新增条目（已存在则刷新过期时间）；Cloud 已提供，内置前端暂未调用 |
| `/user/get_sys_report_conf_conf` | ✔ | 无 | 报表配置读取 |

### 5.2 总览

| 接口 | 标记 | 请求参数 | 说明 |
|---|---|---|---|
| `/user/get_dashboard_summary` | ○ | 无 | 仪表盘汇总（6 张表并行统计） |
| `/user/get_resource_quota` | ○ | 无 | 资源配额配置 |

### 5.3 域名管理

| 接口 | 标记 | 请求参数 |
|---|---|---|
| `/user/get_domain_list` | ✔ | `page` |
| `/user/get_domain_search_list` | ✔ | `page, search_domain` |
| `/user/get_domain` | ✔ | `domain` |
| `/user/create_domain` | ✔ | `domain, http, https, ssl_domain, source_ip(JSON数组串), source_http_port, source_https_port, origin_protocol, balance_type, pre_proxy, real_ip_conf, connect_timeout, send_timeout, read_timeout, detail` |
| `/user/edit_domain` | ✔ | 同 create（domain 为 WHERE 条件） |
| `/user/delete_domain` | ✔ | `domain` |

### 5.4 Web 防护

**Web 引擎**：

| 接口 | 标记 | 请求参数 |
|---|---|---|
| `/user/get_web_engine_protection` | ✔ | 无 |
| `/user/edit_web_engine_protection` | ✔ | `ai_protection, protection_mode, model_provider, model_api_key, engine_protection, unknown_request`（至少一个） |

**Web 规则**（7 个）：

| 接口 | 标记 | 请求参数 |
|---|---|---|
| `/user/get_web_rule_protection_list` | ✔ | `page` |
| `/user/get_web_rule_protection` | ✔ | `rule_name` |
| `/user/create_web_rule_protection` | ✔ | `rule_name, rule_detail, rule_matchs, rule_action, action_value` |
| `/user/edit_web_rule_protection` | ✔ | 同 create |
| `/user/delete_web_rule_protection` | ✔ | `rule_name` |
| `/user/edit_web_rule_protection_status` | ✔ | `rule_name, status("true"/"false")` |
| `/user/exchange_web_rule_protection_priority` | ✔ | `rule_name, type("top"/"exchange")[, exchange_rule_name]` |

**Web 白名单**（7 个，行为与 Web 规则一致）：

| 接口 | 标记 | 请求参数 |
|---|---|---|
| `/user/get_web_white_rule_list` | ✔ | `page` |
| `/user/get_web_white_rule` | ✔ | `rule_name` |
| `/user/create_web_white_rule` | ✔ | `rule_name, rule_detail, rule_matchs, rule_action, action_value` |
| `/user/edit_web_white_rule` | ✔ | 同 create |
| `/user/delete_web_white_rule` | ✔ | `rule_name` |
| `/user/edit_web_white_rule_status` | ✔ | `rule_name, status` |
| `/user/exchange_web_white_rule_priority` | ✔ | `rule_name, type[, exchange_rule_name]` |

**网页防篡改**（8 个）：

| 接口 | 标记 | 请求参数 |
|---|---|---|
| `/user/get_web_page_tamper_proof_list` | ✔ | `page` |
| `/user/get_web_page_tamper_proof` | ✔ | `rule_name` |
| `/user/create_web_page_tamper_proof` | ✔ | `rule_name, rule_detail, rule_matchs, cache_page_url, cache_page_content, cache_content_type` |
| `/user/edit_web_page_tamper_proof` | ✔ | 同 create |
| `/user/delete_web_page_tamper_proof` | ✔ | `rule_name` |
| `/user/edit_web_page_tamper_proof_status` | ✔ | `rule_name, status` |
| `/user/exchange_web_page_tamper_proof_priority` | ✔ | `rule_name, type[, exchange_rule_name]` |
| `/user/waf_get_cache_page_url` | ✔ | `cache_page_url` | 防篡改页面缓存抓取 |

### 5.5 Flow 防护

**Flow 引擎**：

| 接口 | 标记 | 请求参数 |
|---|---|---|
| `/user/get_flow_engine_protection` | ✔ | 无 |
| `/user/edit_flow_engine_protection` | ✔ | `engine_status, protection_plan, plans_config` |

**Flow 规则**（7 个）：

| 接口 | 标记 | 请求参数 |
|---|---|---|
| `/user/get_flow_rule_protection_list` | ✔ | `page` |
| `/user/get_flow_rule_protection` | ✔ | `rule_name` |
| `/user/create_flow_rule_protection` | ✔ | `rule_name, rule_detail, rule_matchs, rule_action, action_value, filter, entity, stat_time, exceed_count, block_time` |
| `/user/edit_flow_rule_protection` | ✔ | 同 create |
| `/user/delete_flow_rule_protection` | ✔ | `rule_name` |
| `/user/edit_flow_rule_protection_status` | ✔ | `rule_name, status` |
| `/user/exchange_flow_rule_protection_priority` | ✔ | `rule_name, type[, exchange_rule_name]` |

**Flow 白名单**（7 个，行为与 Web 规则一致）：

| 接口 | 标记 | 请求参数 |
|---|---|---|
| `/user/get_flow_white_rule_list` | ✔ | `page` |
| `/user/get_flow_white_rule` | ✔ | `rule_name` |
| `/user/create_flow_white_rule` | ✔ | `rule_name, rule_detail, rule_matchs, rule_action, action_value` |
| `/user/edit_flow_white_rule` | ✔ | 同 create |
| `/user/delete_flow_white_rule` | ✔ | `rule_name` |
| `/user/edit_flow_white_rule_status` | ✔ | `rule_name, status` |
| `/user/exchange_flow_white_rule_priority` | ✔ | `rule_name, type[, exchange_rule_name]` |

**Flow 区域封禁**（2 个）：

| 接口 | 标记 | 请求参数 |
|---|---|---|
| `/user/get_flow_ip_region_block` | ✔ | 无 |
| `/user/edit_flow_ip_region_block` | ✔ | `ip_region_block, check_model, country_list(JSON数组串), block_action, action_value` |

### 5.6 SSL 证书

| 接口 | 标记 | 请求参数 |
|---|---|---|
| `/user/get_ssl_manage_list` | ✔ | `page` |
| `/user/get_ssl_manage_search_list` | ✔ | `page, search_ssl_domain` |
| `/user/get_ssl_manage` | ✔ | `ssl_domain` |
| `/user/create_ssl_manage` | ✔ | `ssl_domain, detail, private_key, public_key` |
| `/user/edit_ssl_manage` | ✔ | 同 upload |
| `/user/delete_ssl_manage` | ✔ | `ssl_domain` |
| `/user/request_wildcard_cert` | ✔ | `ssl_domain, dns_type, dns_api_key, dns_api_secret, auto_update, detail` |
| `/user/retry_ssl_cert` | ✔ | `ssl_domain` |
| `/user/edit_ssl_cert_config` | ✔ | `ssl_domain` + DNS 配置字段（系统签发证书的 DNS 配置编辑） |

### 5.7 安全日志与攻击事件（SOC）

**攻击事件 / 日志**：

| 接口 | 标记 | 请求参数 |
|---|---|---|
| `/user/get_attack_event_list` | ✔ | `from_time, to_time, page, domain(可选)` |
| `/user/get_attack_behave_track` | ✔ | `from_time, to_time, attack_ip, domain(可选)` |
| `/user/get_log_query_list` | ✔ | `from_time, to_time, page, sql_rules([{field,operation,value}])` |

> 以上接口的数据源为 ClickHouse，需主账号开启日志远程上报与安全报表（前置条件与 user 侧文档一致）。

**Web 攻击统计**（10 个）：

| 接口 | 标记 | 请求参数 |
|---|---|---|
| `/user/get_web_attack_count_total` | ✔ | `from_time, to_time, domain(可选)` |
| `/user/get_web_attack_count_trend` | ✔ | 同 total |
| `/user/get_web_attack_api_count_total` | ✔ | 同 total |
| `/user/get_web_attack_ip_count_total` | ✔ | 同 total |
| `/user/get_web_attack_isocode_count_total` | ✔ | 同 total |
| `/user/get_web_attack_api_top` | ✔ | 同 total |
| `/user/get_web_attack_type_top` | ✔ | 同 total |
| `/user/get_web_attack_ip_top` | ✔ | 同 total |
| `/user/get_web_attack_isocode_top` | ✔ | 同 total |
| `/user/get_web_attack_geoip` | ✔ | 同 total |

**Flow 攻击统计**（10 个）：

| 接口 | 标记 | 请求参数 |
|---|---|---|
| `/user/get_flow_attack_count_total` | ✔ | `from_time, to_time, domain(可选)` |
| `/user/get_flow_attack_count_trend` | ✔ | 同 total |
| `/user/get_flow_attack_api_count_total` | ✔ | 同 total |
| `/user/get_flow_attack_ip_count_total` | ✔ | 同 total |
| `/user/get_flow_attack_isocode_count_total` | ✔ | 同 total |
| `/user/get_flow_attack_api_top` | ✔ | 同 total |
| `/user/get_flow_attack_type_top` | ✔ | 同 total |
| `/user/get_flow_attack_ip_top` | ✔ | 同 total |
| `/user/get_flow_attack_isocode_top` | ✔ | 同 total |
| `/user/get_flow_attack_geoip` | ✔ | 同 total |

> **count_total 响应结构**：8 个 count_total 接口（Web/Flow 各 4 个：`get_*_attack_count_total`、`get_*_attack_api_count_total`、`get_*_attack_ip_count_total`、`get_*_attack_isocode_count_total`）统一返回嵌套格式：
>
> ```json
> {"result": true, "message": {"current": 1500, "previous": 1200, "trend": "up"}}
> ```
>
> `current` 为当期总数，`previous` 为上一同等长度周期总数，`trend` 为 `up`（上升）/`down`（下降）/`flat`（持平）。前端 `soc-web-report.vue` / `soc-flow-report.vue` 通过 `response.data.message.{current,previous,trend}` 取值并据此计算环比百分比。

### 5.8 业务数据统计（usage_stat）

数据源 MySQL，按子账号隔离，sub_user_name 由会话确定（不接受 body 传入）。

| 接口 | 标记 | 请求参数 |
|---|---|---|
| `/user/get_soc_usage_stat_overview` | ✔ | `from_time, to_time, domain(可选)` |
| `/user/get_soc_usage_stat_qps_trend` | ✔ | 同 overview |
| `/user/get_soc_usage_stat_bandwidth_trend` | ✔ | 同 overview |
| `/user/get_soc_usage_stat_status_distribution` | ✔ | 同 overview |
| `/user/get_soc_usage_stat_latency_trend` | ✔ | 同 overview |
| `/user/get_soc_usage_stat_domains` | ○ | 无 |
| `/user/get_soc_usage_stat_detail` | ○ | `from_time, to_time, domain(可选), page` |

**overview 响应字段**：`total_request`、`traffic_in`、`traffic_out`、`status_2xx/3xx/4xx/5xx`、`request_latency_avg`、`upstream_latency_avg`、`status_detail`（明细状态码计数）

**趋势接口响应记录字段**：`stat_time`、`total_request`、`traffic_in`、`traffic_out`、`status_2xx/3xx/4xx/5xx`、`request_latency_avg`、`upstream_latency_avg`

### 5.9 缓存模块

**缓存开关**（2 个，内置前端 `cache-policy.vue` 使用）：

| 接口 | 标记 | 请求参数 | 响应 |
|---|---|---|---|
| `/user/get_cache_switch` | ✔ | 无 | `{"result": true, "message": {"static_resource_cache": "true"/"false", "query_param_cache": "true"/"false"}}` |
| `/user/edit_cache_switch` | ✔ | `switch_name("static_resource_cache"/"query_param_cache"), switch_status("true"/"false")` | `{"result": true, "message": "edit success"}`（重复开启返回 `already enabled`） |

**缓存策略 CRUD**（传统策略，Cloud 已提供，可被自定义前端调用；`cache_key` 为 JSON 数组串，如 `[{"key":"http_args","value":"path"}]`）：

| 接口 | 标记 | 请求参数 |
|---|---|---|
| `/user/get_cache_policy_list` | ○ | `page` |
| `/user/get_cache_policy` | ○ | `rule_name` |
| `/user/create_cache_policy` | ○ | `rule_name, rule_detail, rule_matchs, cache_key` |
| `/user/edit_cache_policy` | ○ | 同 create |
| `/user/delete_cache_policy` | ○ | `rule_name` |
| `/user/edit_cache_policy_status` | ○ | `rule_name, status` |
| `/user/exchange_cache_policy_priority` | ○ | `rule_name, type[, exchange_rule_name]` |

**不缓存策略**（7 个）：`get_no_cache_policy_list` / `get_no_cache_policy` / `create_no_cache_policy` / `edit_no_cache_policy` / `delete_no_cache_policy` / `edit_no_cache_policy_status` / `exchange_no_cache_policy_priority`，参数同缓存策略（无 `cache_key`）。

**缓存绕过策略**（7 个）：`get_cache_bypass_policy_list` / `get_cache_bypass_policy` / `create_cache_bypass_policy` / `edit_cache_bypass_policy` / `delete_cache_bypass_policy` / `edit_cache_bypass_policy_status` / `exchange_cache_bypass_policy_priority`，参数同不缓存策略。

**预热 / 刷新 / 强制刷新**：

| 接口 | 标记 | 说明 |
|---|---|---|
| `/user/create_cache_warmup_task` / `/user/get_cache_warmup_list` / `/user/get_cache_warmup_detail` / `/user/delete_cache_warmup_task` | ✔（经 `/api/cdn_warmup/*`） | 预热任务管理 |
| `/user/create_cache_refresh_task` / `/user/get_cache_refresh_list` / `/user/get_cache_refresh_detail` / `/user/delete_cache_refresh_task` | ✔（经 `/api/cdn_refresh/*`） | 刷新任务管理 |
| `/user/create_cdn_cache_preheat` | ○ | 创建 CDN 预热 |
| `/user/create_cdn_cache_refresh` | ○ | 创建 CDN 刷新 |

### 5.10 自定义配置（28 个，可透传调用）

Cloud 提供 4 类自定义配置，每类 7 个接口（list / get / create / edit / delete / edit_status / exchange_priority），内置前端暂无对应页面，自定义前端可直接调用。

| 资源 | Cloud 接口前缀 | 请求参数 |
|---|---|---|
| 自定义请求头 | `custom_request_header` | `rule_name, rule_detail, rule_matchs, filter, header_name, header_value` |
| 自定义响应头 | `custom_response_header` | `rule_name, rule_detail, rule_matchs, filter, header_name, header_value` |
| 自定义响应内容 | `custom_response_content` | `rule_name, rule_detail, rule_matchs, filter, content_type, return_code, return_content` |
| 自定义回源地址 | `custom_upstream_address` | `rule_name, rule_detail, rule_matchs, filter, source_ip, source_http_port, source_https_port` |

示例：`POST /user/get_custom_request_header_list`（参数 `page`）、`POST /user/exchange_custom_response_content_priority`（参数 `rule_name, type[, exchange_rule_name]`）。

---

## 六、常见错误响应

| 场景 | 响应 |
|---|---|
| 未登录/会话过期（本地） | `{"result": false, "message": "未登录或会话已过期，请重新登录"}` |
| Cloud 不可达（本地） | `{"result": false, "message": "请求后端服务失败"}` |
| Cloud 返回非 200（本地） | `{"result": false, "message": "后端服务异常"}` |
| 本地不存在的 `/api/` 业务路由（POST） | `{"result": false, "message": "API not found: <path>"}` |
| 业务失败（透传） | `{"result": false, "message": "<Cloud返回的业务错误>"}` |

> 前端 JXAjax 会对认证类错误（含 Cloud 返回的 `invalid jxwaf_sub_waf_auth` 等）自动跳转登录页。
