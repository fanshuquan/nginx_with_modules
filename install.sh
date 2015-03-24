#!/bin/bash

user="`whoami`"
if [ "$user" != "root" ];then
	echo "execute $0 with root !!! "
	exit 0;
fi

sed -i 's/^exclude/#exclude/'  /etc/yum.conf && yum -y install gcc && sed -i 's/^#exclude/exclude/'  /etc/yum.conf

#获取源文件
yum -y install gcc gcc-c++ autoconf automake make
yum -y install zlib zlib-devel openssl openssl--devel pcre pcre-devel

cp ./nginx.txt /tmp/
cp ./conf /tmp/ -r
cd /tmp

tar -zxvf nginx-1.2.0.tar.gz

tar -zxvf ngx_cache_purge-1.3.tar.gz

tar -zxvf pcre-8.10.tar.gz

tar -zxvf openssl-1.0.0c.tar.gz

tar -zxvf gperftools-2.0.tar.gz

cd gperftools-2.0
./configure --prefix=/usr
make&&make install

echo "/usr/local/lib" > /etc/ld.so.conf.d/usr_local_lib.conf
/sbin/ldconfig

mkdir /tmp/tcmalloc
chmod 0777 /tmp/tcmalloc

mkdir /usr/local/nginx
cd /usr/local/nginx
#wget https://naxsi.googlecode.com/files/naxsi-0.47.tgz
#if [ $? -eq 0 ]
#then
#	tar xvzf naxsi-0.47.tgz
#	rm -rf naxsi-0.47.tgz
#else
#	echo "Downloading https://naxsi.googlecode.com/files/naxsi-0.47.tgz failured !!!"
#	exit 1
#fi 

#rm -rf naxsi-0.47.tgz
#mv naxsi-0.47 naxsi

#change file before compile
sed -i 's/\"nginx/\"firefoxbug/i' /tmp/nginx-1.2.0/src/core/nginx.h
#sed -i 's/\" NGINX_VER \"/SecOn/' /tmp/nginx-1.2.0/src/http/ngx_http_special_response.c
sed 's/>nginx</>firefoxbug</' -i /tmp/nginx-1.2.0/src/http/ngx_http_special_response.c

#complie nginx with new args
groupadd www
useradd -g www -s /bin/false -M www

cd /tmp/nginx-1.2.0
./configure --user=www --group=www --prefix=/usr/local/nginx --with-pcre=../pcre-8.10 --with-openssl=../openssl-1.0.0c --add-module=../ngx_cache_purge-1.3 --with-http_stub_status_module --with-http_ssl_module --with-http_gzip_static_module --without-mail_pop3_module     --without-mail_smtp_module     --without-mail_imap_module     --without-http_uwsgi_module     --without-http_scgi_module --with-google_perftools_module

make && make install

if [ $? -ne 0 ];then
	echo "error"
	exit 1
fi 
#set auto start scripts
cp /tmp/nginx.txt /etc/init.d/nginx

chmod u+x /etc/init.d/nginx

chkconfig --add nginx
chkconfig --level 345 nginx on
chkconfig --list nginx

service nginx start

# set nginx + nassi
rm -rf /usr/local/nginx/conf
mv /tmp/conf /usr/local/nginx/

mkdir /home/cache/
mkdir /home/logs/

service nginx reload


