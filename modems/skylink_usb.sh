#!/bin/sh
sleep 15

MODEM=ttyUSB0

          MODEM_INIT='"AT+CRM=1;&C2" ""'
	  MODEM_INIT2='"AT+CRM=1;&C2"'
          IH_IP=" ipcp-accept-local ipcp-accept-remote noipdefault
          debug usepeerdns user mobile mtu 1300 mru 1300
          novj nobsdcomp novjccomp nopcomp noaccomp"
          LOGSCRIPT="CONNECT"
          PHONE="#777"
          SPEED=921600

 
#iptables -P FORWARD ACCEPT
#iptables -t nat -I POSTROUTING -o ppp0 -j MASQUERADE
#iptables -F
#iptables -t mangle -A FORWARD -p tcp --tcp-flags SYN,RST SYN -j TCPMSS --clamp-mss-to-pmtu

echo "1" > /proc/sys/net/ipv4/ip_no_pmtu_disc
          

while true; do

              pppd \
              unit 0\
              noauth \
              lcp-echo-interval 10\
              name ppps \
              /dev/$MODEM $SPEED $NASH_IP:$IH_IP \
connect 'chat -v ABORT "NO DIALTONE" ABORT "NO CARRIER" ABORT BUSY "" '"$MODEM_INIT"' ATDP'$PHONE' '' ;' \
              crtscts modem -detach mru 1400 mtu 1400 \

              sleep 2
done

