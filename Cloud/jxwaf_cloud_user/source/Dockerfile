# ============================================================
# JXWAF Cloud_user - Go 版本
# 不再需要 OpenResty，纯 Go 二进制 + 前端静态文件
# 前端在发布机本地构建（发布脚本执行 npm run build 后复制到 static/），
# Docker 仅负责编译 Go 二进制并打包静态文件
# ============================================================

# 第一阶段：构建 Go 应用
FROM ccr.ccs.tencentyun.com/jxwaf/golang:1.24 AS builder_go

WORKDIR /opt/app

COPY go.mod go.sum ./
COPY main.go ./
COPY internal/ ./internal/

ENV GOPROXY=https://goproxy.cn,direct

RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-w -s" -o run .

# 最终阶段：精简运行环境
FROM ccr.ccs.tencentyun.com/jxwaf/debian:12.8-slim

WORKDIR /opt/jxwaf_user_console

RUN echo "deb http://mirrors.aliyun.com/debian/ bookworm main non-free contrib" > /etc/apt/sources.list && \
    rm -rf /etc/apt/sources.list.d/* && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
    ca-certificates \
    tzdata \
    && rm -rf /var/lib/apt/lists/*

ENV TZ=Asia/Shanghai

# 拷贝 Go 二进制
COPY --from=builder_go /opt/app/run /opt/run

# 拷贝本地构建的前端产物（发布脚本已构建到 static/）
COPY static /opt/jxwaf_user_console/html

# 拷贝默认配置（可选，实际配置从环境变量读取）
COPY conf/waf_config.json /opt/jxwaf_user_console/conf/waf_config.json

WORKDIR /opt

EXPOSE 8080

CMD ["/opt/run"]
