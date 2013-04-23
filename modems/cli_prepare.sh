#!/bin/sh


YOTA=atest3
GSM=atest2
SKY=atest1

# SRVIP=$(nslookup vtest.wifistyle.ru | tail -n 1 | cut -d' ' -f3) # at AP
#SRVIP=$(host vtest.wifistyle.ru | awk '/^[[:alnum:].-]+ has address/ { print $4 }')
SRVIP=`dig +short vtest.wifistyle.ru`
echo "IP for vtest is: $SRVIP"
sleep 1

echo 0 > /proc/sys/net/ipv4/conf/ppp0/rp_filter
echo 0 > /proc/sys/net/ipv4/conf/ppp1/rp_filter
echo 0 > /proc/sys/net/ipv4/conf/eth2/rp_filter

ip rule del fwmark 0x1 lookup 101
ip rule add fwmark 0x1 lookup 101 # sky-WCDMA

ip rule del fwmark 0x2 lookup 102
ip rule add fwmark 0x2 lookup 102 # gsm-3G/EDGE

ip rule del fwmark 0x3 lookup 103
ip rule add fwmark 0x3 lookup 103 # yota-WiMAX

ip route add $SRVIP dev ppp0 table 101
ip route add $SRVIP dev ppp1 table 102
ip route add $SRVIP via 10.0.0.1 table 103


ip route add 195.93.181.0/24 dev lo table 101
ip route add 195.93.181.0/24 dev lo table 102
ip route add 195.93.181.0/24 dev lo table 103
ip route add 195.93.181.0/24 dev lo table 104
ip route add 195.93.181.0/24 dev lo table 105

#echo "4096 16384 131072" > /proc/sys/net/ipv4/tcp_wmem # at AP
echo "4096 16384 4194304" > /proc/sys/net/ipv4/tcp_wmem
#echo "4096 87380 174760" > /proc/sys/net/ipv4/tcp_rmem # at AP
echo "4096 87380 6291456" > /proc/sys/net/ipv4/tcp_rmem

