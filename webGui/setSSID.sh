#!/bin/bash
MODEM_IP='192.168.1.1'
SSID=$1
CHANNEL=0 # 0 is auto
WIFI_ENABLE=1
COUNTRY=RU
HIDE=0
WIFI_RESTART=1
wget --header='X-Requested-With:XMLHttpRequest' --header='Accept-Language:ru;q=0.7,en;q=0.3' \
--header='Content-Type:application/x-www-form-urlencoded; charset=UTF-8' \
--header="Referer:http://$MODEM_IP/html/wlanbasicsettings.html" \
--post-data "<?xml version="1.0" encoding=UTF-8 ?><request><WifiSsid>$SSID</WifiSsid><WifiChannel>$CHANNEL</WifiChannel><WifiHide>$HIDE</WifiHide><WifiCountry>$COUNTRY</WifiCountry><WifiMode>b/g/n</WifiMode><WifiRate>0</WifiRate><WifiTxPwrPcnt>100</WifiTxPwrPcnt><WifiMaxAssoc>5</WifiMaxAssoc><WifiEnable>$WIFI_ENABLE</WifiEnable><WifiFrgThrshld>2346</WifiFrgThrshld><WifiRtsThrshld>2347</WifiRtsThrshld><WifiDtmIntvl>2</WifiDtmIntvl><WifiBcnIntvl>1</WifiBcnIntvl><WifiWme>0</WifiWme><WifiPamode>1</WifiPamode><WifiIsolate>1</WifiIsolate><WifiProtectionmode>0</WifiProtectionmode><Wifioffenable>0</Wifioffenable><Wifiofftime>1800</Wifiofftime><WifiRestart>$WIFI_RESTART</WifiRestart></request>" \
http://$MODEM_IP/api/wlan/basic-settings -O /dev/null -q
