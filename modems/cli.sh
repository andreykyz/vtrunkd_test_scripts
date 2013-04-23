#!/bin/sh


YOTA=atest3
GSM=atest2
SKY=atest1

SRVIP=$(nslookup vtest.wifistyle.ru | tail -n 1 | cut -d' ' -f3)
echo "IP for vtest is: $SRVIP"
sleep 1

ip rule add fwmark 0x1 lookup 101 # sky-WCDMA
ip rule add fwmark 0x2 lookup 102 # gsm-3G/EDGE
ip rule add fwmark 0x3 lookup 103 # yota-WiMAX

ip route add $SRVIP dev ppp0 table 101
ip route add $SRVIP dev ppp1 table 102
ip route add $SRVIP via 10.0.0.1 table 103


ip route add 195.93.181.0/24 dev lo table 101
ip route add 195.93.181.0/24 dev lo table 102
ip route add 195.93.181.0/24 dev lo table 103
ip route add 195.93.181.0/24 dev lo table 104
ip route add 195.93.181.0/24 dev lo table 105

echo "4096 16384 131072" > /proc/sys/net/ipv4/tcp_wmem
echo "4096 87380 174760" > /proc/sys/net/ipv4/tcp_rmem
                                
echo "Yota... 5s"
        vtrunkd -f /etc/vtrunkd.conf $YOTA vtest.wifistyle.ru -P 5000
        sleep 5
echo "GSM... 5s"
        vtrunkd -f /etc/vtrunkd.conf $GSM vtest.wifistyle.ru -P 5000
        sleep 5
echo "Skylink ..."
        vtrunkd -f /etc/vtrunkd.conf $SKY vtest.wifistyle.ru -P 5000

iptables -t nat -I POSTROUTING 1 -o tun1 -j MASQUERADE
iptables -I FORWARD 1 -o tun1 -j ACCEPT

