#!/bin/bash
MODEM_IP='192.168.1.1'
iptables -t mangle -D OUTPUT -p tcp --dport 80 -d $MODEM_IP -j MARK --set-mark $1
