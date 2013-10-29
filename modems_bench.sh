#!/bin/bash

IP1='195.93.181.86'
IP2='195.93.181.85'
IP3='195.93.181.123'
#IP3=`dig +short bond2.wfst.co`

SRVIP='195.93.181.123'
#SRVIP=`dig +short bond2.wfst.co`

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

touch direct_solo
echo 'PPP0' > direct_solo
echo "time_starttransfer %{time_starttransfer} time_total %{time_total} speed_download %{speed_download}" | curl -m 120 --connect-timeout 4 http://$IP1/u100 -o /dev/null -w @- >> direct_solo
echo 'PPP1' >> direct_solo
echo "time_starttransfer %{time_starttransfer} time_total %{time_total} speed_download %{speed_download}" | curl -m 120 --connect-timeout 4 http://$IP2/u100 -o /dev/null -w @- >> direct_solo
echo 'PPP2' >> direct_solo
echo "time_starttransfer %{time_starttransfer} time_total %{time_total} speed_download %{speed_download}" | curl -m 120 --connect-timeout 4 http://$IP3/u100 -o /dev/null -w @- >> direct_solo

touch direct_multi
echo 'PPP0' > direct_multi
echo "time_starttransfer %{time_starttransfer} time_total %{time_total} speed_download %{speed_download}" | curl -m 120 --connect-timeout 4 http://$IP3/u100 -o /dev/null -w @- >> direct_multi 
echo 'PPP1' >> direct_multi
echo "time_starttransfer %{time_starttransfer} time_total %{time_total} speed_download %{speed_download}" | curl -m 120 --connect-timeout 4 http://$IP3/u100 -o /dev/null -w @- >> direct_multi
echo 'PPP2' >> direct_multi
echo "time_starttransfer %{time_starttransfer} time_total %{time_total} speed_download %{speed_download}" | curl -m 120 --connect-timeout 4 http://$IP3/u100 -o /dev/null -w @- >> direct_multi

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

touch agg_solo
echo 'PPP2' > agg_solo
./vtrunkd/vtrunkd -f /etc/vtrunkd.conf $YOTA $SRVIP -P $PORT
sleep 5s
TUNNELIP=`ifconfig tun1 | grep 'inet addr' | awk -F: {'print$2'} | awk  {'print$1'}`
echo "Tunnel ip is $TUNNELIP"
echo "time_starttransfer %{time_starttransfer} time_total %{time_total} speed_download %{speed_download}" | curl -m 120 --connect-timeout 4 http://$TUNNELIP/u100 -o /dev/null -w @- >> agg_solo

killall -9 vtrunkd ; ipcrm -M 567888 ; ipcrm -M 567889 ; sleep 5s

echo 'PPP1' > agg_solo
./vtrunkd/vtrunkd -f /etc/vtrunkd.conf $GSM $SRVIP -P $PORT
sleep 5s
echo "time_starttransfer %{time_starttransfer} time_total %{time_total} speed_download %{speed_download}" | curl -m 120 --connect-timeout 4 http://$TUNNELIP/u100 -o /dev/null -w @- >> agg_solo

killall -9 vtrunkd ; ipcrm -M 567888 ; ipcrm -M 567889 ; sleep 5s

touch agg_solo
echo 'PPP0' > agg_solo
./vtrunkd/vtrunkd -f /etc/vtrunkd.conf $SKY $SRVIP -P $PORT
sleep 5s
echo "time_starttransfer %{time_starttransfer} time_total %{time_total} speed_download %{speed_download}" | curl -m 120 --connect-timeout 4 http://$TUNNELIP/u100 -o /dev/null -w @- >> agg_solo

killall -9 vtrunkd ; ipcrm -M 567888 ; ipcrm -M 567889 ; sleep 5s

touch agg_multi
echo "" > agg_multi
./vtrunkd/vtrunkd -f /etc/vtrunkd.conf $SKY $SRVIP -P $PORT
sleep 5s
./vtrunkd/vtrunkd -f /etc/vtrunkd.conf $YOTA $SRVIP -P $PORT
sleep 5s
./vtrunkd/vtrunkd -f /etc/vtrunkd.conf $GSM $SRVIP -P $PORT
sleep 5s
echo "time_starttransfer %{time_starttransfer} time_total %{time_total} speed_download %{speed_download}" | curl -m 120 --connect-timeout 4 http://$TUNNELIP/u100 -o /dev/null -w @- >> agg_multi

