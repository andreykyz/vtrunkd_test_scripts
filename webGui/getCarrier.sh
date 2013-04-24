#!/bin/bash
MODEM_IP='192.168.1.1'
wget --header="X-Requested-With:XMLHttpRequest" --header="Accept-Language:ru;q=0.7,en;q=0.3" http://$MODEM_IP/api/net/current-plmn -O - -q | xml2 | grep FullName | awk -F= '{ print$2 }'

