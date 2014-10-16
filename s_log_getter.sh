#!/bin/bash

# 1. name server VM $SRV_MACHINE
# 2. name client VM $CLI_MACHINE
# 3. set up 3 net cards eth1...eth3 for each VM 
# 4. add frac_digits(3) to syslog-ng options

DBOXHOST=grandrew@alternet.homelinux.net # host to upload JSON logs to and parse them on
DBOXHOST_PORT=10023
LOGS_FOLDER=~/sandbox/alarm_logs
VTRUNKD_L_ROOT=/home/andrey/workspace-cpp/vtrunkd
VTRUNKD_V_ROOT=/home/user/sandbox/test_folder
LCNT=~/log_getter.counter

VSRV_ETH1_IP=192.168.57.101
VSRV_ETH2_IP=192.168.58.101
VSRV_ETH3_IP=192.168.59.101

VCLI_ETH1_IP=192.168.57.100
VCLI_ETH2_IP=192.168.58.100
VCLI_ETH3_IP=192.168.59.100

#SRV_MACHINE="user@srv-32"
CLI_MACHINE="user@cli-32"
SRV_MACHINE="user@srv"
#CLI_MACHINE="user@cli"
VTR_PORT=5003

NTP_SERVER="0.ubuntu.pool.ntp.org"
#NTP_SERVER="192.168.0.101"

if [ ! -f $LCNT ]; then
    RND=`$(($RANDOM % 99))`
    echo -n "$RND"00 > $LCNT
fi

TEST="0"
EXEC="0"

COUNT=$((`cat $LCNT`+1));
echo -n $COUNT > $LCNT

PREFIX="$COUNT"_
TITLE=""
ONE=""
RULE=""
while getopts :oetpT: OPTION
do
 case $OPTION in
 o) echo "One thread"
  ONE="1111"
  TITLE="$TITLE One_thread"
  ;;
 e) echo "Execute vtrunkd only"
  EXEC="1"
  ;;
 t) echo "Full speed test"
  TEST="1"
  ;;
 T) echo "Set title"
  TITLE="$OPTARG"
  ;;
 p) echo "Prefix set $OPTARG"
  PREFIX="$OPTARG""_$PREFIX"
  ;;
 :)
  echo "Option -$OPTARG requires an argument." >&2
  exit 1
 ;;
 esac
done

echo "Doing with prefix $PREFIX"
if [ "$TITLE" ]; then
    echo "Title is $TITLE"
fi

if [ "$RULE" ]; then
    echo "$RULE"
fi

echo "Starting..."
echo "NTP sync..."
ssh $CLI_MACHINE "sudo ntpdate $NTP_SERVER" &
ssh $SRV_MACHINE "sudo ntpdate $NTP_SERVER" &
echo "killall vtrunkd ... "
ssh $SRV_MACHINE "sudo killall -9 vtrunkd ; sudo ipcrm -M 567888 ; sudo ipcrm -M 567889"
ssh $CLI_MACHINE "sudo killall -9 vtrunkd ; sudo ipcrm -M 567888 ; sudo ipcrm -M 567889"
echo "Clear syslog"
ssh $CLI_MACHINE "cat /dev/null | sudo tee /var/log/syslog"
ssh $SRV_MACHINE "cat /dev/null | sudo tee /var/log/syslog"
echo "Copying vtrunkd sources ..."

ssh $SRV_MACHINE "rm -r -f $VTRUNKD_V_ROOT 2> /dev/null"
ssh $SRV_MACHINE "mkdir -p $VTRUNKD_V_ROOT" && echo 'mkdir  server OK'

ssh $SRV_MACHINE "sync"
scp -r $VTRUNKD_L_ROOT/* $SRV_MACHINE:$VTRUNKD_V_ROOT/ > /dev/null
echo "Compiling vtrunkd server ..."
sh $SRV_MACHINE "cd $VTRUNKD_V_ROOT; make distclean"
#ssh $SRV_MACHINE "cd $VTRUNKD_V_ROOT; CFLAGS=$CFLAGS\ -O3\ -g ./configure --prefix= --disable-o3 --enable-json"  2>/dev/null 1>/dev/null && echo 'configure server OK'
ssh $SRV_MACHINE "cd $VTRUNKD_V_ROOT; CFLAGS=$CFLAGS\ -O3\ -g ./configure --prefix= --disable-o3"  2>/dev/null 1>/dev/null && echo 'configure server OK'
ssh $SRV_MACHINE "cd $VTRUNKD_V_ROOT; make" 2>/dev/null 1>/dev/null  && echo 'make server OK'

ssh $CLI_MACHINE "rm -r -f $VTRUNKD_V_ROOT 2> /dev/null"
ssh $CLI_MACHINE "sync"
ssh $CLI_MACHINE "mkdir -p $VTRUNKD_V_ROOT 2> /dev/null"
scp -r $VTRUNKD_L_ROOT/* $CLI_MACHINE:$VTRUNKD_V_ROOT/ > /dev/null

echo "Compiling client..."
    ssh $CLI_MACHINE "cd $VTRUNKD_V_ROOT; make distclean"
#    ssh $CLI_MACHINE "cd $VTRUNKD_V_ROOT; CFLAGS=$CFLAGS\ -O0\ -g\ -gdwarf-4\ -fvar-tracking-assignments ./configure --prefix= --disable-o3 --enable-client-only"  2>/dev/null 1>/dev/null
    ssh $CLI_MACHINE "cd $VTRUNKD_V_ROOT; CFLAGS=$CFLAGS\ -O3\ -g ./configure --prefix= --disable-o3 --enable-client-only"  2>/dev/null 1>/dev/null
#    ssh $CLI_MACHINE "cd $VTRUNKD_V_ROOT; ./configure --prefix= --enable-json"  2>/dev/null 1>/dev/null
    ssh $CLI_MACHINE "cd $VTRUNKD_V_ROOT; make"  2>/dev/null 1>/dev/null
#    ssh $CLI_MACHINE "cd $VTRUNKD_V_ROOT; strip vtrunkd"  2>/dev/null 1>/dev/null
#    echo "Compile Error!"
#    exit 0;

echo "Setting IP addresses..."
if ssh $SRV_MACHINE "sudo ifconfig eth1 $VSRV_ETH1_IP && sudo ifconfig eth2 $VSRV_ETH2_IP && sudo ifconfig eth3 $VSRV_ETH3_IP"; then
    echo "OK"
else 
    echo "IP setup error"
    exit 0
fi
if ssh $CLI_MACHINE "sudo ifconfig eth1 $VCLI_ETH1_IP && sudo ifconfig eth2 $VCLI_ETH2_IP && sudo ifconfig eth3 $VCLI_ETH3_IP"; then
    echo "OK"
else 
    echo "IP setup error"
    exit 0
fi
echo "Applying emulation TC rules"

#ssh $SRV_MACHINE "sudo $VTRUNKD_V_ROOT/test/srv_emulate_2.sh > /dev/null"
#ssh $SRV_MACHINE "sudo $VTRUNKD_V_ROOT/test/srv_emulate_yota_sky.sh > /dev/null"
#ssh $CLI_MACHINE "sudo $VTRUNKD_V_ROOT/test/cli_emulate_yota_sky.sh > /dev/null"

#echo "TCP dump..."
#ssh $SRV_MACHINE "sudo rm -f /home/user/virtual*cap"
#ssh $CLI_MACHINE "sudo rm -f /home/user/virtual*cap"
#ssh $SRV_MACHINE "sudo tcpdump -i eth1 -s 65535 -w /home/user/virtual_eth1.cap" &
#ssh $CLI_MACHINE "sudo tcpdump -i eth1 -s 65535 -w /home/user/virtual_eth1.cap" &

echo "Starting server..."
#ssh $SRV_MACHINE "sudo valgrind --tool=callgrind --trace-children=yes $VTRUNKD_V_ROOT/vtrunkd -s -f $VTRUNKD_V_ROOT/test/vtrunkd-srv.test.conf -P $VTR_PORT"
#ssh $SRV_MACHINE "G_SLICE=always-malloc G_DEBUG=gc-friendly sudo valgrind -v --tool=memcheck --leak-check=full --num-callers=40 --log-file=valgrind_memckeck.log  --trace-children=yes $VTRUNKD_V_ROOT/vtrunkd -s -f /home/user/sandbox/test_folder/vtrunkd/test/vtrunkd.conf -P $VTR_PORT"
#ssh $SRV_MACHINE "sudo $VTRUNKD_V_ROOT/vtrunkd -s -R 39997-41000 -f $VTRUNKD_V_ROOT/test/vtrunkd-srv.test.conf -P $VTR_PORT"
ssh $SRV_MACHINE "sudo $VTRUNKD_V_ROOT/vtrunkd -s -f $VTRUNKD_V_ROOT/test/vtrunkd-srv.test.conf -P $VTR_PORT"
echo "Starting client 1..."
sleep 2s
LEAK_CHECK='definite,indirect,possible'
#ssh $CLI_MACHINE "sudo valgrind -v --tool=memcheck --trace-children=yes --leak-resolution=high --leak-check=full --show-leak-kinds=$LEAK_CHECK --num-callers=60 --log-file=valgrind_memckeck_${PREFIX}01.log  $VTRUNKD_V_ROOT/vtrunkd -f $VTRUNKD_V_ROOT/test/vtrunkd-cli.test.conf eth1 $VSRV_ETH1_IP -P $VTR_PORT"
#ssh $CLI_MACHINE "sudo valgrind -v --tool=helgrind --log-file=helgrind_${PREFIX}01.log  $VTRUNKD_V_ROOT/vtrunkd -f $VTRUNKD_V_ROOT/test/vtrunkd-cli.test.conf eth1 $VSRV_ETH1_IP -P $VTR_PORT"
#ssh $CLI_MACHINE "sudo valgrind -v --tool=exp-sgcheck --trace-children=yes --log-file=sgcheck_${PREFIX}01.log  $VTRUNKD_V_ROOT/vtrunkd -f $VTRUNKD_V_ROOT/test/vtrunkd-cli.test.conf eth1 $VSRV_ETH1_IP -P $VTR_PORT"
#ssh $CLI_MACHINE "sudo valgrind -v --vgdb-prefix=/tmp/valgrind_pipe  --vgdb=full --log-file=valgrind_${PREFIX}01.log $VTRUNKD_V_ROOT/vtrunkd -f $VTRUNKD_V_ROOT/test/vtrunkd-cli.test.conf eth1 $VSRV_ETH1_IP -P $VTR_PORT"
#ssh $CLI_MACHINE "sudo valgrind --tool=massif --pages-as-heap=yes --log-file=massif_${PREFIX}01.log $VTRUNKD_V_ROOT/vtrunkd -f $VTRUNKD_V_ROOT/test/vtrunkd-cli.test.conf eth1 $VSRV_ETH1_IP -P $VTR_PORT"
#ssh $CLI_MACHINE "cd ~/sandbox ; screen -d -m -A -S eth1 sudo python gdb_auto_attach.py 1"
#ssh $CLI_MACHINE "cd ~/sandbox ; screen -d -m -A -S eth2 sudo python gdb_auto_attach.py 2"
#ssh $CLI_MACHINE "cd ~/sandbox ; screen -d -m -A -S eth3 sudo python gdb_auto_attach.py 3"
ssh $CLI_MACHINE "sudo $VTRUNKD_V_ROOT/vtrunkd -f $VTRUNKD_V_ROOT/test/vtrunkd-cli.test.conf eth1 $VSRV_ETH1_IP -P $VTR_PORT"
if [ -z $ONE ]; then
    sleep 1
    echo "Starting client 2..."
    ssh $CLI_MACHINE "sudo $VTRUNKD_V_ROOT/vtrunkd -f $VTRUNKD_V_ROOT/test/vtrunkd-cli.test.conf eth2 $VSRV_ETH2_IP -P $VTR_PORT"
#ssh $CLI_MACHINE "sudo valgrind -v --tool=exp-sgcheck --trace-children=yes --log-file=sgcheck_${PREFIX}02.log  $VTRUNKD_V_ROOT/vtrunkd -f $VTRUNKD_V_ROOT/test/vtrunkd-cli.test.conf eth2 $VSRV_ETH1_IP -P $VTR_PORT"
#    ssh $CLI_MACHINE "sudo valgrind -v --vgdb-prefix=/tmp/valgrind_pipe  --vgdb=full --log-file=valgrind_${PREFIX}02.log $VTRUNKD_V_ROOT/vtrunkd -f $VTRUNKD_V_ROOT/test/vtrunkd-cli.test.conf eth2 $VSRV_ETH2_IP -P $VTR_PORT"
#     ssh $CLI_MACHINE "sudo valgrind --tool=massif --pages-as-heap=yes --log-file=massif_${PREFIX}02.log $VTRUNKD_V_ROOT/vtrunkd -f $VTRUNKD_V_ROOT/test/vtrunkd-cli.test.conf eth2 $VSRV_ETH2_IP -P $VTR_PORT"
#    ssh $CLI_MACHINE "sudo valgrind -v --tool=memcheck --trace-children=yes --leak-resolution=high --leak-check=full --num-callers=60 --show-leak-kinds=$LEAK_CHECK --log-file=valgrind_memckeck_${PREFIX}02.log  $VTRUNKD_V_ROOT/vtrunkd -f $VTRUNKD_V_ROOT/test/vtrunkd-cli.test.conf eth2 $VSRV_ETH2_IP -P $VTR_PORT"
#    ssh $CLI_MACHINE "sudo valgrind --tool=helgrind --log-file=helgrind_${PREFIX}02.log  $VTRUNKD_V_ROOT/vtrunkd -f $VTRUNKD_V_ROOT/test/vtrunkd-cli.test.conf eth2 $VSRV_ETH2_IP -P $VTR_PORT"
#    echo "Starting client 3..."
    ssh $CLI_MACHINE "sudo $VTRUNKD_V_ROOT/vtrunkd -f $VTRUNKD_V_ROOT/test/vtrunkd-cli.test.conf eth3 $VSRV_ETH3_IP -P $VTR_PORT"
#     ssh $CLI_MACHINE "sudo valgrind --tool=massif --pages-as-heap=yes --log-file=massif_${PREFIX}03.log $VTRUNKD_V_ROOT/vtrunkd -f $VTRUNKD_V_ROOT/test/vtrunkd-cli.test.conf eth2 $VSRV_ETH2_IP -P $VTR_PORT"
#    ssh $CLI_MACHINE "sudo valgrind -v --tool=memcheck --trace-children=yes --leak-resolution=high --leak-check=full --num-callers=60 --show-leak-kinds=$LEAK_CHECK --log-file=valgrind_memckeck_${PREFIX}03.log $VTRUNKD_V_ROOT/vtrunkd -f $VTRUNKD_V_ROOT/test/vtrunkd-cli.test.conf eth3 $VSRV_ETH3_IP -P $VTR_PORT"
#    ssh $CLI_MACHINE "sudo valgrind --tool=helgrind --log-file=helgrind_${PREFIX}03.log $VTRUNKD_V_ROOT/vtrunkd -f $VTRUNKD_V_ROOT/test/vtrunkd-cli.test.conf eth3 $VSRV_ETH3_IP -P $VTR_PORT"
fi
sleep 2

#ssh $SRV_MACHINE "sudo tcpdump -i tun100 -s 65535 -w /home/user/virtual.cap" &
#ssh $CLI_MACHINE "sudo tcpdump -i tun1 -s 65535 -w /home/user/virtual.cap" &

echo "Full started"
if [ $EXEC = "1" ]; then
    "Execute only!"
    exit 0;
fi
if [ $TITLE ]; then
    echo "$TITLE" > /tmp/${PREFIX}speed
fi
git branch -a | grep \*  | tr -d '\n' >> /tmp/${PREFIX}speed
git log --oneline -1 >> /tmp/${PREFIX}speed
echo "Worcking..."
#exit
#ssh $SRV_MACHINE "sudo ping -c 39  -W 0.1 -i 0.02  10.200.1.32"
echo "time_starttransfer %{time_starttransfer} time_total %{time_total} speed_download %{speed_download}" | ssh $CLI_MACHINE curl -m 300 --connect-timeout 4 http://10.200.1.31/u -o /dev/null -w @- > /tmp/${PREFIX}speed
#echo "" >>  /tmp/${PREFIX}ping
#ssh $SRV_MACHINE "sudo ping -c 100 -i 0.1  10.200.1.32"
#ssh $SRV_MACHINE "sudo ping -c 1000 -i 0.001 10.200.1.32"
#ssh $SRV_MACHINE sudo ping -c 100 -i 1 10.200.1.32
#cat /tmp/${PREFIX}ping
#ssh $SRV_MACHINE sudo ping -f -c 20000 10.200.1.32
#ssh $SRV_MACHINE  "ps aux | grep valgr | awk '{ print$2 }' | xargs sudo kill"
#ssh $SRV_MACHINE 'echo "time_starttransfer %{time_starttransfer} time_total %{time_total} speed_download %{speed_download}" | curl -m 400 --connect-timeout 4 http://10.200.1.32/u -o /dev/null -w @-' >> /tmp/${PREFIX}speed
echo "" >>  /tmp/${PREFIX}speed
ssh $CLI_MACHINE "ping -c 10 -q -a 10.200.1.31" | tail -1 >> /tmp/${PREFIX}speed
cat ./test/srv_emulate_2.sh | grep ceil | awk {'print$12" "'} | tr -d '\n' >> /tmp/${PREFIX}speed
echo "" >> /tmp/${PREFIX}speed
cat ./test/srv_emulate_2.sh | grep delay | grep -v "#" | awk {'print$10" "$11" "$12";"'} | tr -d '\n' >> /tmp/${PREFIX}speed
echo "" >> /tmp/${PREFIX}speed
#echo "killall vtrunkd"
#ssh $SRV_MACHINE "sudo killall -9 vtrunkd"
#ssh $CLI_MACHINE "sudo killall -9 vtrunkd"
# NOT WORKING CODE -->>>>>>>>>>>>>>>
if [ $TEST = "1" ]; then
 echo "Speed testing..."
 echo "time_starttransfer %{time_starttransfer} time_total %{time_total} speed_download %{speed_download}" | ssh $CLI_MACHINE curl -m 30 --connect-timeout 4 http://192.168.57.101/u -o /dev/null -w @- > /tmp/${PREFIX}speed_eth1
 echo "time_starttransfer %{time_starttransfer} time_total %{time_total} speed_download %{speed_download}" | ssh $CLI_MACHINE curl -m 30 --connect-timeout 4 http://192.168.58.101/u -o /dev/null -w @- > /tmp/${PREFIX}speed_eth2
 echo "" >> /tmp/${PREFIX}speed_eth1
 echo "" >> /tmp/${PREFIX}speed_eth2
 SPEED_ETH1=`cat /tmp/${PREFIX}speed_eth1 | awk {'print $6'} | awk -F. {'print $1'}`
 SPEED_ETH2=`cat /tmp/${PREFIX}speed_eth2 | awk {'print $6'} | awk -F. {'print $1'}`
 SPEED_AG=`cat /tmp/${PREFIX}speed | head -1 | awk {'print $6'} | awk -F. {'print $1'}`
 if [ ${SPEED_ETH1} -gt ${SPEED_ETH2} ]; then
  AG_EFF=`python -c "print (${SPEED_AG} - ${SPEED_ETH1}) * 100 / ${SPEED_ETH2}"`
  C_GROW=`python -c "print (${SPEED_AG} *100) / ${SPEED_ETH1}"`
  fdsfsdf=`python -c "print (${SPEED_AG} * 100) / (${SPEED_ETH1} + ${SPEED_ETH2})"`
 else
  AG_EFF=`python -c "print (${SPEED_AG} - ${SPEED_ETH2}) * 100 / ${SPEED_ETH1}"`
  C_GROW=`python -c "print (${SPEED_AG} *100) / ${SPEED_ETH2}"`
  fdsfsdf=`python -c "print (${SPEED_AG} * 100) / ($SPEED_ETH2 + $SPEED_ETH1)"`
 fi
 ping -c 10 -q -a 192.168.57.101 | tail -3 >> /tmp/${PREFIX}speed_eth1
 ping -c 10 -q -a 192.168.58.101 | tail -3 >> /tmp/${PREFIX}speed_eth2
echo "efficiency factor - ${AG_EFF}% C_grow - ${C_GROW}% C_use - ${fdsfsdf}%" >> /tmp/${PREFIX}speed
fi
# <<<<<<<<<<<<<<-- END NOT WORKING CODE
echo "Transfer syslogs"
scp $CLI_MACHINE:/var/log/syslog /tmp/${PREFIX}syslog-cli
scp $SRV_MACHINE:/var/log/syslog /tmp/${PREFIX}syslog-srv
#scp $CLI_MACHINE:/home/user/virtual.cap $LOGS_FOLDER/${PREFIX}_cli.cap
#scp $SRV_MACHINE:/home/user/virtual.cap $LOGS_FOLDER/${PREFIX}_srv.cap
#scp $CLI_MACHINE:/home/user/virtual_eth1.cap $LOGS_FOLDER/${PREFIX}_eth1_cli.cap
#scp $SRV_MACHINE:/home/user/virtual_eth1.cap $LOGS_FOLDER/${PREFIX}_eth1_srv.cap
#grep "\"name\"\:" /tmp/${PREFIX}syslog-srv > /tmp/${PREFIX}syslog-srv_json
#grep "\"name\"\:" /tmp/${PREFIX}syslog-cli > /tmp/${PREFIX}syslog-cli_json
grep "cubic_info" /tmp/${PREFIX}syslog-srv > /tmp/${PREFIX}syslog-srv_json
grep "cubic_info" /tmp/${PREFIX}syslog-cli > /tmp/${PREFIX}syslog-cli_json
cd $VTRUNKD_L_ROOT ; git log -n 1 | head -1 >> /tmp/"$PREFIX".nojson
cd $VTRUNKD_L_ROOT ; git log -n 1 | tail -1 >> /tmp/"$PREFIX".nojson
grep speed /tmp/${PREFIX}speed >> /tmp/"$PREFIX".nojson
echo "Uploading logs..."
cp /tmp/${PREFIX}* $LOGS_FOLDER
#cp $VTRUNKD_L_ROOT/speed_parse_json_fusion.py $LOGS_FOLDER
#cd $LOGS_FOLDER; python ./speed_parse_json_fusion.py $COUNT
echo "Drawing graphs"
#cp $VTRUNKD_L_ROOT/test/parse_json_fusion_cli_uni.py $LOGS_FOLDER
#cd $LOGS_FOLDER; python ./parse_json_fusion_cli_uni.py $COUNT
#cp $VTRUNKD_L_ROOT/test/parse_json_fusion_uni.py $LOGS_FOLDER
#cd $LOGS_FOLDER; python ./parse_json_fusion_uni.py $COUNT
cp $VTRUNKD_L_ROOT/test/parse_udp_cubic.py $LOGS_FOLDER
cd $LOGS_FOLDER; python ./parse_udp_cubic.py $COUNT
#ssh -p $DBOXHOST_PORT $DBOXHOST "cd ~/Dropbox/alarm_logs/; python ./parse_json_fusion.py $COUNT"
echo "Compressing logs in background"
#sh $VTRUNKD_L_ROOT/test/files_thread_compress.sh -d $LOGS_FOLDER &
echo "Clear syslog"
rm /tmp/${PREFIX}*
#ssh $CLI_MACHINE "cat /dev/null | sudo tee /var/log/syslog"
#ssh $SRV_MACHINE "cat /dev/null | sudo tee /var/log/syslog"
echo "Complete!!!"
