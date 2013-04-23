#!/bin/bash
MODEM_IP='192.168.1.1'
PSK_PASSWORD=$1
CRYPT_MODE='MIX' # AES,TKIP,MIX(AES+TKIP) 
AUTH_MODE='WPA/WPA2-PSK' # WPA-PSK,WPA2-PSK,WPA/WPA2-PSK
wget --header='X-Requested-With:XMLHttpRequest' --header='Accept-Language:ru;q=0.7,en;q=0.3' \
--header='Content-Type:application/x-www-form-urlencoded; charset=UTF-8' \
--header="Referer:http://$MODEM_IP/html/wlanbasicsettings.html" \
--post-data "<?xml version="1.0" encoding=UTF-8 ?><request><WifiAuthmode>$AUTH_MODE</WifiAuthmode><WifiBasicencryptionmodes>NONE</WifiBasicencryptionmodes><WifiWpaencryptionmodes>$CRYPT_MODE</WifiWpaencryptionmodes><WifiWepKey1>60606</WifiWepKey1><WifiWepKey2>12345</WifiWepKey2><WifiWepKey3>12345</WifiWepKey3><WifiWepKey4>12345</WifiWepKey4><WifiWepKeyIndex>1</WifiWepKeyIndex><WifiWpapsk>$PSK_PASSWORD</WifiWpapsk><WifiWpsenbl>1</WifiWpsenbl><WifiWpscfg>1</WifiWpscfg><WifiRestart>1</WifiRestart></request>" \
http://192.168.1.1/api/wlan/security-settings -O /dev/null -q
