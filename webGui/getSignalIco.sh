#!/bin/bash
MODEM_IP='192.168.1.1'
ICON_NUM=`wget --header="X-Requested-With:XMLHttpRequest" --header="Accept-Language:ru;q=0.7,en;q=0.3" http://$MODEM_IP/api/monitoring/status -O - -q | xml2 | grep SignalIcon | awk -F= '{ print$2 }'`
echo http\:\/\/$MODEM_IP\/res\/signal_$ICON_NUM.gif
