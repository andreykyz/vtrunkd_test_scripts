#!/bin/bash

cd /home/wifistyle

SKIP1=$1
SKIP2=$2
SKIP3=$3

IP1='195.93.181.86'
IP2='195.93.181.85'
IP3='195.93.181.123'
#IP3=`dig +short bond2.wfst.co`

#SRVIP='195.93.181.123'
#SRVIP=`dig +short bond2.wfst.co`
SRVIP=`dig +short vtest.wifistyle.ru`


LCNT=~/LCNT_COUNTER
if [ ! -f $LCNT ]; then
    RND=`$(($RANDOM % 99))`
    echo -n "$RND"00 > $LCNT
fi

TEST="0"
EXEC="0"

COUNT=$((`cat $LCNT`+1));
echo -n $COUNT > $LCNT

PREFIX="$COUNT"_

YOTA=$(grep LTE /etc/vtrunkd.conf | cut -d' ' -f1)
GSM=$(grep 3G /etc/vtrunkd.conf | cut -d' ' -f1)
SKY=$(grep SKY /etc/vtrunkd.conf | cut -d' ' -f1)

PORT=5000

route del -host $IP1 dev ppp0
route del -host $IP2 dev ppp1
route del -host $IP3 dev ppp2

route add -host $IP1 dev ppp0
route add -host $IP2 dev ppp1
route add -host $IP3 dev ppp2

if ! [ "$SKIP1" == "1" ]; then
touch ${PREFIX}direct_solo
route -n
echo "PPP0 - time_total %{time_total} size_download %{size_download} speed_download %{speed_download}\n" | curl -m 120 --connect-timeout 4 http://$IP1/u100 -o /dev/null -w @- >> ${PREFIX}direct_solo
route -n

echo "PPP1 - time_total %{time_total} size_download %{size_download} speed_download %{speed_download}\n" | curl -m 120 --connect-timeout 4 http://$IP2/u100 -o /dev/null -w @- >> ${PREFIX}direct_solo
route -n
echo "PPP2 - time_total %{time_total} size_download %{size_download} speed_download %{speed_download}\n" | curl -m 120 --connect-timeout 4 http://$IP3/u100 -o /dev/null -w @- >> ${PREFIX}direct_solo
fi

if ! [ "$SKIP2" == "1" ]; then
route -n
touch ${PREFIX}direct_multi
echo "PPP0 - time_total %{time_total} size_download %{size_download} speed_download %{speed_download}\n" | curl -m 120 --connect-timeout 4 http://$IP1/u100 -o /dev/null -w @- >> ${PREFIX}direct_multi &
sleep 2s
echo "PPP1 - time_total %{time_total} size_download %{size_download} speed_download %{speed_download}\n" | curl -m 120 --connect-timeout 4 http://$IP2/u100 -o /dev/null -w @- >> ${PREFIX}direct_multi &
sleep 2s
echo "PPP2 - time_total %{time_total} size_download %{size_download} speed_download %{speed_download}\n" | curl -m 120 --connect-timeout 4 http://$IP3/u100 -o /dev/null -w @- >> ${PREFIX}direct_multi
fi
#### vtrunkd ####

#### mark gateways ####

echo 'mark gateways'

route del -host $IP1 dev ppp0
route del -host $IP2 dev ppp1
route del -host $IP3 dev ppp2

ip rule del fwmark 0x1 lookup 101 # sky-WCDMA
ip rule del fwmark 0x2 lookup 102 # gsm-3G/EDGE
ip rule del fwmark 0x3 lookup 103 # yota-WiMAX

ip rule add fwmark 0x1 lookup 101 # sky-WCDMA
ip rule add fwmark 0x2 lookup 102 # gsm-3G/EDGE
ip rule add fwmark 0x3 lookup 103 # yota-WiMAX

#ip route add $PINGHOST dev ppp0 table 101
#ip route add $PINGHOST dev ppp1 table 102
#route add -net 8.8.4.0 netmask 255.255.255.0 dev lo

ip route add default dev lo table 101
ip route add default dev lo table 102
ip route add default dev lo table 103

ip route add $SRVIP dev ppp0 table 101
ip route add $SRVIP dev ppp1 table 102
ip route add $SRVIP dev ppp2 table 103

killall -9 vtrunkd ; ipcrm -M 567888 ; ipcrm -M 567889 ; sleep 5s
touch ${PREFIX}agg_solo
ip route show table 101
ip route show table 102
ip route show table 103
echo "./vtrunkd/vtrunkd -f /etc/vtrunkd.conf $YOTA $SRVIP -P $PORT" | tee -a ${PREFIX}agg_solo
./vtrunkd/vtrunkd -f /etc/vtrunkd.conf $YOTA $SRVIP -P $PORT
sleep 8s

route del -host $TESTIP dev tun1
route add -host $TESTIP dev tun1

TUNNELIP=`ifconfig tun1 | grep 'inet addr' | awk -F: {'print$3'} | awk  {'print$1'}`
echo "Tunnel ip is $TUNNELIP"
echo "PPP2 - time_total %{time_total} size_download %{size_download} speed_download %{speed_download}\n" | curl -m 120 --connect-timeout 4 http://$TUNNELIP/u100 -o /dev/null -w @- >> ${PREFIX}agg_solo

killall -9 vtrunkd ; ipcrm -M 567888 ; ipcrm -M 567889 ; sleep 5s
echo "" >> ${PREFIX}agg_solo
ip route show table 101
ip route show table 102
ip route show table 103
echo "./vtrunkd/vtrunkd -f /etc/vtrunkd.conf $GSM $SRVIP -P $PORT" | tee -a ${PREFIX}agg_solo
./vtrunkd/vtrunkd -f /etc/vtrunkd.conf $GSM $SRVIP -P $PORT
sleep 8s

route del -host $TESTIP dev tun1
route add -host $TESTIP dev tun1

echo "PPP1 - time_total %{time_total} size_download %{size_download} speed_download %{speed_download}\n" | curl -m 120 --connect-timeout 4 http://$TUNNELIP/u100 -o /dev/null -w @- >> ${PREFIX}agg_solo

killall -9 vtrunkd ; ipcrm -M 567888 ; ipcrm -M 567889 ; sleep 5s
echo "" >> ${PREFIX}agg_solo
ip route show table 101
ip route show table 102
ip route show table 103
echo "./vtrunkd/vtrunkd -f /etc/vtrunkd.conf $SKY $SRVIP -P $PORT" | tee -a ${PREFIX}agg_solo
./vtrunkd/vtrunkd -f /etc/vtrunkd.conf $SKY $SRVIP -P $PORT
sleep 8s

echo "PPP0 - time_total %{time_total} size_download %{size_download} speed_download %{speed_download}\n" | curl -m 120 --connect-timeout 4 http://$TUNNELIP/u100 -o /dev/null -w @- >> ${PREFIX}agg_solo
echo "" >> ${PREFIX}agg_solo

killall -9 vtrunkd ; ipcrm -M 567888 ; ipcrm -M 567889 ; sleep 5s

echo "multi"
touch ${PREFIX}agg_multi
echo "" > ${PREFIX}agg_multi
ip route show table 101
ip route show table 102
ip route show table 103
echo "./vtrunkd/vtrunkd -f /etc/vtrunkd.conf $SKY $SRVIP -P $PORT" | tee -a ${PREFIX}agg_multi
./vtrunkd/vtrunkd -f /etc/vtrunkd.conf $SKY $SRVIP -P $PORT
sleep 8s
echo "./vtrunkd/vtrunkd -f /etc/vtrunkd.conf $YOTA $SRVIP -P $PORT" | tee -a ${PREFIX}agg_multi
./vtrunkd/vtrunkd -f /etc/vtrunkd.conf $YOTA $SRVIP -P $PORT
sleep 8s
echo "./vtrunkd/vtrunkd -f /etc/vtrunkd.conf $GSM $SRVIP -P $PORT" | tee -a ${PREFIX}agg_multi
./vtrunkd/vtrunkd -f /etc/vtrunkd.conf $GSM $SRVIP -P $PORT
sleep 8s
route del -host $TESTIP dev tun1
route add -host $TESTIP dev tun1

echo "AGG - time_total %{time_total} size_download %{size_download} speed_download %{speed_download}\n" | curl -m 120 --connect-timeout 4 http://$TUNNELIP/u100 -o /dev/null -w @- >> ${PREFIX}agg_multi

echo "" >> ${PREFIX}agg_multi
