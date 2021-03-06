#!/bin/bash

src=/usr/local/nginx/conf/

/usr/local/bin/inotifywait -rmq  -e modify $src |  while read  event
do
	Yes=`/usr/local/nginx/sbin/nginx -t 2> temp.txt ; grep successful temp.txt  | wc -l ; rm -rf  temp.txt`
	if [ $Yes -eq 1 ];then
		kill -HUP `cat /usr/local/nginx/logs/nginx.pid`
	else
	   	echo `hostname`":nginx.conf configure error." 
	fi
done
