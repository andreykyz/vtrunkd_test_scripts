#!/bin/sh
#          DIALTIMEOUT=5
#if cat /tmp/ttyUSB2.out | grep HS > /dev/null; then
#          MODEM=ttyUSB2
#else
#          MODEM=ttyUSB5
#fi

MODEM=ttyUSB5

          IH_IP=" usepeerdns defaultroute usehostname modem crtscts"


          LOGSCRIPT="CONNECT"
          PHONE="*99#"

          while  true ; do
              pppd \
              unit 1\
              persist \
              noauth \
              linkname beeline \
              name pppb \
              /dev/$MODEM $SPEED $NASH_IP:$IH_IP \
              connect 'chat -v ABORT "NO DIALTONE" ABORT "NO CARRIER" ABORT BUSY TIMEOUT 5 "" "\\d" "" "\\d" "" AT OK "ATV1" OK "ATE0" OK "AT" OK "AT" OK "ATS0=0" TIMEOUT 10 "" ATZ OK "AT&f+CGDCONT=1,\"IP\",\"internet.beeline.ru\"" TIMEOUT 20 OK "ATDT*99#" CONNECT "" TIMEOUT 5 "~--" "" ;' \
              crtscts defaultroute modem -detach mru 1400 \

              #cat /etc/ppp/resolv.conf > /etc/resolv.conf
              sleep $DIALTIMEOUT
          done
