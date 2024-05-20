# JXWAF

[中文版](https://github.com/jx-sec/jxwaf/blob/master/README.md)
[English](https://github.com/jx-sec/jxwaf/blob/master/English.md)

### Introduced 介绍

JXWAF 是一款开源 WEB 应用防火墙

### Notice 通知

- JXWAF4 发布

### Feature 功能

- 防护管理
  - 网站防护
  - 名单防护
  - 基础组件
  - 分析组件
- 运营中心
  - 业务数据统计
  - Web安全报表
  - 流量安全报表
  - 攻击事件
  - 日志查询
  - 节点状态
- 系统管理
  - 基础信息
  - SSL证书管理
  - 日志传输配置
  - 日志查询配置
  - 拦截页面配置
  - 配置备份&加载

### Architecture 架构
- JXWAF系统由三个子系统组成
  - jxwaf节点
  - jxwaf控制台
  - jxlog日志系统 

![jxwaf_architecture](img/jxwaf_architecture.jpg)

### 测试环境部署 

#### 环境依赖

- 服务器版本 Centos 7.x

#### 快速部署

```
# 安装docker
curl -sSLk https://get.docker.com/ | bash
service docker start
# 下载docker compose文件
yum install git
git clone https://github.com/jx-sec/jxwaf-docker-file.git
# 运行程序
#国内环境可以使用 jxwaf-docker-file/test_env_cn 速度更快
cd jxwaf-docker-file/test_env
docker compose  up -d
```

