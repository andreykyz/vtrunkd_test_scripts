#!/bin/bash
MODEM_IP='192.168.1.1'
LOGIN='admin'
PASSWORD=`echo admin | base64 - | sed 's/.$//'` #encoded
wget -q --header='X-Requested-With: XMLHttpRequest' --header='Accept-Language: ru,en-gb;q=0.7,en;q=0.3' \
--post-data "<?xml version="1.0" encoding=UTF-8 ?><request><Username>$LOGIN</Username><Password>$PASSWORD=</Password></request>" \
--header="Referer:http://$MODEM_IP/html/home.html" http://$MODEM_IP/api/user/login -O /dev/null
