from centos:centos7 as builder 

WORKDIR /tmp
COPY .  .
RUN yum install -y epel-release pcre-devel openssl-devel gcc cmake make  lua-devel  automake
RUN tar zxvf openresty-1.21.4.1.tar.gz
WORKDIR /tmp/openresty-1.21.4.1
RUN ./configure --prefix=/opt/jxwaf --with-http_v2_module --with-http_stub_status_module && gmake && gmake install
RUN mv /opt/jxwaf/nginx/conf/nginx.conf  /opt/jxwaf/nginx/conf/nginx.conf.bak
RUN cp ../conf/nginx.conf /opt/jxwaf/nginx/conf/  &&\
    cp ../conf/full_chain.pem /opt/jxwaf/nginx/conf/  &&\
    cp ../conf/private.key /opt/jxwaf/nginx/conf/ &&\
    mkdir /opt/jxwaf/nginx/conf/jxwaf &&\
    cp ../conf/jxwaf_config.json /opt/jxwaf/nginx/conf/jxwaf/ &&\
    cp -r ../lib/resty/jxwaf  /opt/jxwaf/lualib/resty/ &&\
    mv -r ../lib/resty/kafka  /opt/jxwaf/lualib/resty/ &&\
    /opt/jxwaf/nginx/sbin/nginx -t

FROM golang:1.19 as dokerun_builder
WORKDIR /opt/app
COPY ./tools/* ./
ENV GOPROXY=https://goproxy.cn,direct
RUN go mod download
RUN  go build  -o /opt/app/run ./run.go



FROM centos:centos7
# from alpine:3.16
WORKDIR /opt/jxwaf 
COPY --from=builder /opt/jxwaf /opt/jxwaf
COPY --from=dokerun_builder /opt/app/run /

CMD   ["/run"]
