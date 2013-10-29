#!/bin/bash

IP1='192.93.181.86'
IP2='192.93.181.85'
IP3=`dig +short bond2.wfst.co`

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

#./vtrunkd/vtrunkd -f /etc/vtrunkd.conf $YOTA $IP1 -P $PORT

