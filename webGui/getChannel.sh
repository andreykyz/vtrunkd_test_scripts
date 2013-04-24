#!/bin/bash
MODEM_IP='192.168.1.1'
CHANNEL=`wget --header="X-Requested-With:XMLHttpRequest" --header="Accept-Language:ru;q=0.7,en;q=0.3" http://$MODEM_IP/api/wlan/basic-settings -O - -q | xml2 | grep WifiChannel | awk -F= '{ print$2 }'`
if [ $CHANNEL = '0' ] ;
then
  CHANNEL=auto
fi
echo $CHANNEL
