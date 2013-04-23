#!/bin/bash
MODEM_IP='192.168.1.1'
NEW_IP='192.168.1.2'
MASK='255.255.255.0'
DHCP_ENABLE='1'
START_DHCP='192.168.1.100'
END_DHCP='192.168.1.200'
LEASE_TIME='86400'
wget --header='X-Requested-With:XMLHttpRequest' --header='Accept-Language:ru;q=0.7,en;q=0.3' \
--header='Content-Type:application/x-www-form-urlencoded; charset=UTF-8' \
--header="Referer:http://$MODEM_IP/html/dhcp.html" \
--post-data "POSTDATA=<?xml version="1.0" encoding=UTF-8 ?><request><DhcpIPAddress>$NEW_IP</DhcpIPAddress><DhcpLanNetmask>$MASK</DhcpLanNetmask><DhcpStatus>$DHCP_ENABLE</DhcpStatus><DhcpStartIPAddress>$START_DHCP</DhcpStartIPAddress><DhcpEndIPAddress>$END_DHCP</DhcpEndIPAddress><DhcpLeaseTime>$LEASE_TIME</DhcpLeaseTime><DnsStatus>0</DnsStatus><PrimaryDns>0.0.0.0</PrimaryDns><SecondaryDns>0.0.0.0</SecondaryDns></request>" \
http://$MODEM_IP/api/dhcp/settings -O /dev/null -q
