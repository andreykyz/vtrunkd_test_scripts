#!/bin/bash
MODEM_IP='192.168.1.1'
wget --header="X-Requested-With:XMLHttpRequest" --header="Accept-Language:ru;q=0.7,en;q=0.3" http://$MODEM_IP/api/wlan/basic-settings -O - -q | xml2 | grep WifiSsid | awk -F= '{ print$2 }'
