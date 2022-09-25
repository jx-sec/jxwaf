#!/bin/bash

tar zxvf openresty-1.21.4.1.tar.gz
cd openresty-1.21.4.1
./configure --prefix=/opt/jxwaf --with-http_v2_module --with-http_stub_status_module && gmake && gmake install
mv /opt/jxwaf/nginx/conf/nginx.conf  /opt/jxwaf/nginx/conf/nginx.conf.bak
cp ../conf/nginx.conf /opt/jxwaf/nginx/conf/
cp ../conf/full_chain.pem /opt/jxwaf/nginx/conf/
cp ../conf/private.key /opt/jxwaf/nginx/conf/
mkdir /opt/jxwaf/nginx/conf/jxwaf
cp ../conf/jxwaf_config.json /opt/jxwaf/nginx/conf/jxwaf/
cp -r ../lib/resty/jxwaf  /opt/jxwaf/lualib/resty/
/opt/jxwaf/nginx/sbin/nginx -t