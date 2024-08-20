FROM centos:centos7 as builder
WORKDIR /tmp
COPY .  .

RUN curl -o /etc/yum.repos.d/CentOS-Base-aliyun.repo https://mirrors.aliyun.com/repo/Centos-7.repo
RUN curl -o /etc/yum.repos.d/CentOS-Base-hw.repo https://mirrors.huaweicloud.com/artifactory/os-conf/centos/centos-7.repo


RUN yum install -y pcre-devel openssl-devel gcc cmake make lua-devel automake

RUN tar zxvf openresty-1.21.4.3.tar.gz \
    && tar zxvf libmaxminddb-1.6.0.tar.gz \
    && cd /tmp/openresty-1.21.4.3 \
    && ./configure --prefix=/opt/jxwaf --with-http_v2_module --with-http_stub_status_module \
    && make && make install


RUN mv /opt/jxwaf/nginx/conf/nginx.conf /opt/jxwaf/nginx/conf/nginx.conf.bak \
    && cp /tmp/conf/nginx.conf /opt/jxwaf/nginx/conf/ \
    && cp /tmp/conf/full_chain.pem /opt/jxwaf/nginx/conf/ \
    && cp /tmp/conf/private.key /opt/jxwaf/nginx/conf/ \
    && mkdir /opt/jxwaf/nginx/conf/jxwaf \
    && cp /tmp/conf/jxwaf_config.json /opt/jxwaf/nginx/conf/jxwaf/ \
    && cp /tmp/conf/GeoLite2.mmdb /opt/jxwaf/nginx/conf/jxwaf/ \
    && cp /tmp/conf/jxcore /opt/jxwaf/nginx/conf/jxwaf/ \
    && cp -r /tmp/lib/resty/jxwaf /opt/jxwaf/lualib/resty/

WORKDIR /tmp/libmaxminddb-1.6.0
RUN ./configure \
    && make \
    && cp src/.libs/libmaxminddb.so.0.0.7 /opt/jxwaf/lualib/resty/jxwaf/libmaxminddb.so

RUN /opt/jxwaf/nginx/sbin/nginx -t

FROM golang:1.19 as go_builder
WORKDIR /opt/app

COPY ./tools/dockerun /opt/app

ENV GOPROXY=https://goproxy.cn,direct
RUN go mod download \
    && go build -o /opt/app/run ./run.go

FROM centos:centos7
WORKDIR /opt/jxwaf

COPY --from=builder /opt/jxwaf /opt/jxwaf

COPY --from=go_builder /opt/app/run /opt/

ENV HTTP_PORT=80 \
    HTTPS_PORT=443 \
    JXWAF_SERVER="" \
    WAF_AUTH="" \
    BOT_CHECK_IP_BIND="true" \
    WAF_CC_JS_WEBSITE="https://cc.jxwaf.top/"

WORKDIR /opt

CMD ["/opt/run"]
