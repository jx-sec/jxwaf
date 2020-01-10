#!/bin/bash
yum install -y epel-release pcre-devel openssl-devel gcc cmake make g++ curl lua-devel gcc-c++ automake
tar zxvf openresty-1.13.6.2.tar.gz
tar zxvf libmaxminddb-1.3.2.tar.gz
tar zxvf aliyun-log-c-sdk-lite.tar.gz
tar zxvf curl-7.64.1.tar.gz
server_name=`ip addr | grep inet | awk '{ print $2; }' | sed 's/\/.*$//'|grep -v 127.0.0.1|head -1`
server_mac=`hostname`
aes_enc_key=`cat /dev/urandom|head -n 10|md5sum|head -c 16`
aes_enc_iv=`cat /dev/urandom|head -n 10|md5sum|head -c 16`
cd curl-7.64.1
make
make install
cd ../openresty-1.13.6.2
./configure --prefix=/opt/jxwaf && gmake && gmake install
mv /opt/jxwaf/nginx/conf/nginx.conf  /opt/jxwaf/nginx/conf/nginx.conf.bak
cp ../conf/nginx.conf /opt/jxwaf/nginx/conf/
cp ../conf/full_chain.pem /opt/jxwaf/nginx/conf/
cp ../conf/private.key /opt/jxwaf/nginx/conf/
mkdir /opt/jxwaf/nginx/conf/jxwaf
cp ../conf/jxwaf_config.json /opt/jxwaf/nginx/conf/jxwaf/
cp ../conf/GeoLite2-Country.mmdb /opt/jxwaf/nginx/conf/jxwaf/
cp -r ../lib/resty/jxwaf  /opt/jxwaf/lualib/resty/
cd ../libmaxminddb-1.3.2
./configure
make
cp src/.libs/libmaxminddb.so.0.0.7 /opt/jxwaf/lualib/libmaxminddb.so
cd ../aliyun-log-c-sdk-lite
cmake .
make
cp build/lib/liblog_c_sdk.so.2.0.0 /opt/jxwaf/lualib/liblog_c_sdk.so
sed -i "s/server_info_detail/$server_name|$server_mac/g" /opt/jxwaf/nginx/conf/jxwaf/jxwaf_config.json
sed -i "s/jxwaf_aes_enc_key/$aes_enc_key/g" /opt/jxwaf/nginx/conf/jxwaf/jxwaf_config.json
sed -i "s/jxwaf_aes_enc_iv/$aes_enc_iv/g" /opt/jxwaf/nginx/conf/jxwaf/jxwaf_config.json
/opt/jxwaf/nginx/sbin/nginx -t


