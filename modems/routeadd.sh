#!/bin/sh

#SRVIP=$(nslookup vtest.wifistyle.ru | tail -n 1 | cut -d' ' -f3)
#SRVIP=$(host vtest.wifistyle.ru | awk '/^[[:alnum:].-]+ has address/ { print $4 }')
SRVIP=`dig +short vtest.wifistyle.ru`
while true; do
ip route add $SRVIP dev ppp0 table 101
ip route add $SRVIP dev ppp1 table 102
ip route add $SRVIP via 10.0.0.1 table 103
sleep 1
done

