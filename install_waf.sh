#!/bin/bash
server_name=`ip addr | grep inet | awk '{ print $2; }' | sed 's/\/.*$//'|grep -v 127.0.0.1|head -1`
server_mac=`hostname`
yum install -y epel-release pcre-devel openssl-devel gcc cmake make  lua-devel  automake
tar zxvf openresty-1.15.8.3.tar.gz
cd openresty-1.15.8.3
./configure --prefix=/opt/jxwaf --with-http_v2_module --with-http_stub_status_module && gmake && gmake install
mv /opt/jxwaf/nginx/conf/nginx.conf  /opt/jxwaf/nginx/conf/nginx.conf.bak
cp ../conf/nginx.conf /opt/jxwaf/nginx/conf/
cp ../conf/full_chain.pem /opt/jxwaf/nginx/conf/
cp ../conf/private.key /opt/jxwaf/nginx/conf/
mkdir /opt/jxwaf/nginx/conf/jxwaf
cp ../conf/jxwaf_config.json /opt/jxwaf/nginx/conf/jxwaf/
cp ../conf/GeoLite2-Country.mmdb /opt/jxwaf/nginx/conf/jxwaf/
cp -r ../lib/resty/jxwaf  /opt/jxwaf/lualib/resty/
sed -i "s/server_info_detail/$server_name|$server_mac/g" /opt/jxwaf/nginx/conf/jxwaf/jxwaf_config.json
/opt/jxwaf/nginx/sbin/nginx -t


