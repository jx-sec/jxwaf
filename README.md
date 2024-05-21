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

### 演示环境

http://demo.jxwaf.com:8000/
帐号  test
密码  123456

### 测试环境部署 

#### 环境要求

- 服务器系统 Centos 7.x

#### 快速部署

```
# 安装docker，国内网络建议输入 curl -fsSL https://get.docker.com | bash -s docker --mirror Aliyun
curl -sSLk https://get.docker.com/ | bash
service docker start
# 下载docker compose文件,国内网络建议输入 git clone https://gitclone.com/github.com/jx-sec/jxwaf-docker-file.git
yum install git
git clone https://github.com/jx-sec/jxwaf-docker-file.git
# 启动容器，国内网络建议输入 cd jxwaf-docker-file/test_env 
cd jxwaf-docker-file/test_env
docker compose  up -d
```

#### 效果验证

申请一台按量计费服务器，IP地址为 119.45.234.74 ，完成上述快速部署步骤后

访问 控制台地址  http://119.45.234.74:8000  默认帐号为 test，密码为123456

登录控制台后，在网站防护中点击新建网站，参考如下配置进行设置

![image](https://github.com/jx-sec/jxwaf/assets/9301820/b0128902-3d86-49e6-899a-9a75c2d35aaf)

配置完成后，回到服务器 

```
[root@VM-0-11-centos test_env_cn]# pwd
/tmp/jxwaf-docker-file/test_env_cn
[root@VM-0-11-centos test_env_cn]# cd ../waf_test/
[root@VM-0-11-centos waf_test]# python waf_poc_test.py -u http://119.45.234.74
```

运行waf测试脚本后,即可在控制台中的运营中心查看防护效果

![image](https://github.com/jx-sec/jxwaf/assets/9301820/1dd779f8-c64b-4706-9fa3-8abb94192c37)

![image](https://github.com/jx-sec/jxwaf/assets/9301820/7e42194c-cada-4e0a-9fec-9f4c57dbbc7d)

![image](https://github.com/jx-sec/jxwaf/assets/9301820/5034934a-339d-40b4-92dc-3bd3ff4719c0)
