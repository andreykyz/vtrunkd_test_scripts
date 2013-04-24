#!/bin/bash
MODEM_IP='192.168.1.1'
wget --header='X-Requested-With:XMLHttpRequest' --header='Accept-Language:ru;q=0.7,en;q=0.3' \
--header='Content-Type:application/x-www-form-urlencoded; charset=UTF-8' \
--header="Referer:http://$MODEM_IP/html/reboot.html" \
--post-data "<?xml version=\"1.0\" encoding=\"UTF-8\"?><request><Control>1</Control></request>" \
http://$MODEM_IP/api/device/control -O /dev/null -q
