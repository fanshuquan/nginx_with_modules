#!/bin/bash

yum remove rsync 
yum -y install rsync 
#kill `ps aux | grep rsync | awk '{ print $2 }'`
#************************************rsync*********************************#
OLD_DIR=`pwd`
# 1
cd /tmp
wget http://github.com/downloads/rvoicilas/inotify-tools/inotify-tools-3.14.tar.gz --no-check-certificate
if [ $? -eq 0 ]
then
	tar zxvf inotify-tools-3.14.tar.gz
	rm -rf inotify-tools-3.14.tar.gz
else
	echo "Downloading http://github.com/downloads/rvoicilas/inotify-tools/inotify-tools-3.14.tar.gz failured !!!"
	exit 1
fi 
cd inotify-tools-3.14
./configure && make && make install

# 2
ln -sv /usr/local/lib/libinotify* /usr/lib/
ln -s /usr/local/lib/libinotifytools.so.0 /usr/lib64/libinotifytools.so.0

# 1 create rsyncd.pass
echo "zooboa:zooboa.com" >>/etc/rsyncd.pwd
chmod 600 /etc/rsyncd.pwd

# 2 create rsyncd.pass
USER=zooboa
PASSWD=secon.rsync
cd $OLD_DIR

while : 
do
	echo -n "building /etc/rsyncd.conf,choose x or z (x/z)"
	read ANS
	case $ANS in 
		x)
			cp rsyncd_x.conf  /etc/rsyncd.conf
			if [ $? -eq 0 ];then
				echo "create /etc/rsyncd.conf successfully ! "
				break;
			fi 
			continue
			;;
		z)
			cp rsyncd_z.conf  /etc/rsyncd.conf
			if [ $? -eq 0 ];then
				echo "create /etc/rsyncd.conf successfully ! "
				break;
			fi 
			continue
			;;
		*)
			continue
			;;
	esac 
done
#chown  $USER:root /usr/local/nginx/conf
# 3 write into system service
echo "/usr/bin/rsync --daemon" >> /etc/rc.d/rc.local

# 4 run
/usr/bin/rsync --daemon

# 5 add rules of iptables

# now  change !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
#echo '-A RH-Firewall-1-INPUT -m state --state NEW -m tcp -p tcp --dport 873 -j ACCEPT' >> /etc/sysconfig/iptables

mv /etc/init.d/iptables /etc/init.d/iptables.bak
rm -f /etc/sysconfig/iptables
rm -f /etc/init.d/iptables 
cp ${OLD_DIR}/iptables_start.sh /etc/init.d/iptables
chmod u+x /etc/init.d/iptables
cp ${OLD_DIR}/iptables.conf /etc/sysconfig/iptables
service iptables restart

# now  change  end !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

# 6 rewrite configure file of nginx and reload 
cp ./nginxmon.sh  /usr/local/nginx/sbin/ -f
kill -HUP `cat /usr/local/nginx/logs/nginx.pid`  

# 7 write into system service 

chmod u+x /usr/local/nginx/sbin/nginxmon.sh
echo "nohup /bin/bash /usr/local/nginx/sbin/nginxmon.sh > /var/log/nginxmon.log 2>&1 &" >> /etc/rc.d/rc.local

#************************************rsync*********************************#

#************************************nfs***********************************#
yum install -y nfs-utils nfs4-acl-tools portmap

service rpcbind start
service nfs start

IP=10.241.92.115
while : 
do
	echo -n "now mounting (defalut IP 10.241.92.115) (y/n)?"
	read A
	case $A in 
		n|N)
			echo -n "input IP : "
			read IP
			break
			;;
		  *)
			IP=10.241.92.115
			break
			;;
	esac 
done

showmount -e $IP

mount -t nfs ${IP}:/home/logs /home/logs
echo "mount -t nfs -o nolock ${IP}:/home/logs /home/logs" >>  /etc/rc.local
echo "${IP}:/home/logs	/home/logs nfs defaults 0 0" >> /etc/fstab
