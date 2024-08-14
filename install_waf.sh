#!/bin/bash
curl -o /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo
yum install -y  pcre-devel openssl-devel gcc cmake make  lua-devel  automake
tar zxvf openresty-1.21.4.3.tar.gz
tar zxvf libmaxminddb-1.6.0.tar.gz
cd openresty-1.21.4.3
./configure --prefix=/opt/jxwaf --with-http_v2_module --with-http_stub_status_module && gmake && gmake install
mv /opt/jxwaf/nginx/conf/nginx.conf  /opt/jxwaf/nginx/conf/nginx.conf.bak
cp ../conf/nginx.conf /opt/jxwaf/nginx/conf/
cp ../conf/full_chain.pem /opt/jxwaf/nginx/conf/
cp ../conf/private.key /opt/jxwaf/nginx/conf/
mkdir /opt/jxwaf/nginx/conf/jxwaf
cp ../conf/jxwaf_config.json /opt/jxwaf/nginx/conf/jxwaf/
cp ../conf/GeoLite2.mmdb  /opt/jxwaf/nginx/conf/jxwaf/
cp ../conf/jxcore  /opt/jxwaf/nginx/conf/jxwaf/
cp -r ../lib/resty/jxwaf  /opt/jxwaf/lualib/resty/
cd ../libmaxminddb-1.6.0
./configure
make
cp src/.libs/libmaxminddb.so.0.0.7 /opt/jxwaf/lualib/resty/jxwaf/libmaxminddb.so
/opt/jxwaf/nginx/sbin/nginx -t
