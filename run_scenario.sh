#!/bin/bash

# 1. name server VM srv-32
# 2. name client VM cli-32
# 3. set up 3 net cards eth1...eth3 for each VM 
# 4. add frac_digits(3); keep_timestamp(no); to syslog-ng options

# TODO: load script options from external config file
DBOXHOST=grandrew@alternet.homelinux.net # host to upload JSON logs to and parse them on
DBOXHOST_PORT=10023
VTRUNKD_L_ROOT=~/sandbox/vtrunkd
VTRUNKD_V_ROOT=/home/user/sandbox/vtrunkd_test1
LCNT=~/log_getter.counter

VSRV_ETH1_IP=192.168.57.101
VSRV_ETH2_IP=192.168.58.101
VSRV_ETH3_IP=192.168.59.101

VCLI_ETH1_IP=192.168.57.100
VCLI_ETH2_IP=192.168.58.100
VCLI_ETH3_IP=192.168.59.100

NTP_SERVER="0.ubuntu.pool.ntp.org"

if [ ! -f $LCNT ]; then i
    RND=$(($RANDOM % 99))
    echo -n "$RND"00 > $LCNT
fi

TEST="0"
EXEC="0"

# CFILE is used by stats collector and is fixed
CFILE=/tmp/log_getter.cnt
SFILE=/tmp/log_getter.spd

COUNT=$((`cat $LCNT`+1));
echo -n $COUNT > $LCNT
echo -n $COUNT > $CFILE

PREFIX="$COUNT"_

while getopts :tp:nf OPTION
do
 case $OPTION in
 e) echo "Execute vtrunkd only"
  EXEC="1"
  ;;
 t) echo "Full speed test"
  TEST="1"
  ;;
 n) echo "No compile mode"
  NOCOMPILE=true
  ;;
 f) echo "Fast test mode"
  FASTT=true
  ;;
 p) echo "Prefix set $OPTARG"
  PREFIX=$OPTARG
  ;;
 :)
  echo "Option -$OPTARG requires an argument." >&2
  exit 1
 ;;
 esac
done

echo $NOCOMPILE $FASTT

if [[ ! -v NOCOMPILE ]]
then
  NOCOMPILE=false   # Initialize it to zero!
fi

if [[ ! -v FASTT ]]
then
  FASTT=false   # Initialize it to zero!
fi


TCRULES=/tmp/tcrules.sh
echo $NOCOMPILE $FASTT

if $NOCOMPILE; then
    SPD=`cat $TCRULES | grep ceil | awk {'print$12" "'} | tr -d '\n'`
    DELAY=`cat $TCRULES | grep delay | grep -v "#" | awk {'print$10" "$11" "$12";"'} | tr -d '\n'`
else
    SPD=`cat ./srv_emulate_2.sh | grep ceil | awk {'print$12" "'} | tr -d '\n'`
    DELAY=`cat ./srv_emulate_2.sh | grep delay | grep -v "#" | awk {'print$10" "$11" "$12";"'} | tr -d '\n'`
fi

DOCS="$COUNT `git branch -a | grep \*` `git log --oneline -1` \n $SPD \n $DELAY"
echo "Creating stat docstring... $DOCS"
echo -e "$DOCS" > /tmp/"$PREFIX".nojson

echo "Doing with prefix $PREFIX"
echo "Starting..."
echo "killall vtrunkd ... "
ssh user@srv-32 "sudo killall -9 vtrunkd && sudo ipcrm -M 567888"
ssh user@cli-32 "sudo killall -9 vtrunkd && sudo ipcrm -M 567888"
echo "Clear syslog"
ssh user@cli-32 "cat /dev/null | sudo tee /var/log/syslog"
ssh user@srv-32 "cat /dev/null | sudo tee /var/log/syslog"


if $NOCOMPILE; then
        echo "-- Not compiling sources!!"
        echo "Copying TC rules from $TCRULES"
        scp $TCRULES user@srv-32:$VTRUNKD_V_ROOT/test/srv_emulate_2.sh
        ssh user@srv-32 "sync"
else
        echo "Copying vtrunkd sources ..."
        ssh user@cli-32 "mkdir -p $VTRUNKD_V_ROOT"
        ssh user@srv-32 "mkdir -p $VTRUNKD_V_ROOT"
        scp -r $VTRUNKD_L_ROOT/* user@srv-32:$VTRUNKD_V_ROOT/
        scp -r $VTRUNKD_L_ROOT/* user@cli-32:$VTRUNKD_V_ROOT/
        ssh user@srv-32 "sync"
        ssh user@cli-32 "sync"
        echo "Compiling vtrunkd ..."
        if ssh user@srv-32 "cd $VTRUNKD_V_ROOT; make clean; make"; then 
            echo "OK"
        else
            echo "Compile Error!"
            exit 0;
        fi
        echo "Compiling ..."
        if ssh user@cli-32 "cd $VTRUNKD_V_ROOT; make clean; make"; then
            echo "OK"
        else
            echo "Compile Error!"
            exit 0;
        fi
fi



echo "NTP sync..."
ssh user@cli-32 "sudo ntpdate $NTP_SERVER" &
sleep 1
ssh user@srv-32 "sudo ntpdate $NTP_SERVER"
echo "Setting IP addresses..."
if ssh user@srv-32 "sudo ifconfig eth1 $VSRV_ETH1_IP && sudo ifconfig eth2 $VSRV_ETH2_IP && sudo ifconfig eth3 $VSRV_ETH3_IP"; then
    echo "OK"
else 
    echo "IP setup error"
    exit 0
fi
if ssh user@cli-32 "sudo ifconfig eth1 $VCLI_ETH1_IP && sudo ifconfig eth2 $VCLI_ETH2_IP && sudo ifconfig eth3 $VCLI_ETH3_IP"; then
    echo "OK"
else 
    echo "IP setup error"
    exit 0
fi
echo "Applying emulation TC rules"
ssh user@srv-32 "sudo $VTRUNKD_V_ROOT/test/srv_emulate_2.sh"

echo "Starting server..."
ssh user@srv-32 "sudo $VTRUNKD_V_ROOT/vtrunkd -s -f $VTRUNKD_V_ROOT/test/vtrunkd-srv.test.conf -P 5003"
sleep 5
echo "Starting client 1..."
ssh user@cli-32 "sudo $VTRUNKD_V_ROOT/vtrunkd -f $VTRUNKD_V_ROOT/test/vtrunkd-cli.test.conf atest1 $VSRV_ETH1_IP -P 5003"
echo "Starting client 2..."
ssh user@cli-32 "sudo $VTRUNKD_V_ROOT/vtrunkd -f $VTRUNKD_V_ROOT/test/vtrunkd-cli.test.conf atest2 $VSRV_ETH2_IP -P 5003"
sleep 8
echo "Full started"
if [ $EXEC = "1" ]; then
    "Execute only!"
    exit 0;
fi
#RATE1    DELAY1 JITTR1 PERCENT1      RATE2 ...
MAT='
./set_tc.sh 100kbit 200ms 50ms 50%    100kbit 200ms 50ms 50%    100kbit 200ms 50ms 50%
./set_tc.sh 100kbit 200ms 50ms 50%    200kbit 200ms 50ms 50%    100kbit 200ms 50ms 50%
./set_tc.sh 100kbit 200ms 50ms 50%    300kbit 150ms 50ms 50%    100kbit 200ms 50ms 50%
./set_tc.sh 100kbit 200ms 50ms 50%    600kbit 100ms 50ms 50%    100kbit 200ms 50ms 50%
./set_tc.sh 100kbit 200ms 50ms 50%    800kbit 100ms 50ms 50%    100kbit 200ms 50ms 50%
./set_tc.sh 100kbit 200ms 50ms 50%   1200kbit  80ms 50ms 50%    100kbit 200ms 50ms 50%
ssh user@srv "sudo ifconfig eth1 down"
./set_tc.sh  200kbit 200ms 50ms 50%    1kbit 500ms 50ms 50%    100kbit 200ms 50ms 50%
sleep 0.1
sleep 0.1
./set_tc.sh  200kbit 200ms 50ms 50%    300kbit 200ms 50ms 50%    100kbit 200ms 50ms 50%
./set_tc.sh  200kbit 200ms 50ms 50%    600kbit 100ms 50ms 50%    100kbit 200ms 50ms 50%
./set_tc.sh  200kbit 200ms 50ms 50%    800kbit 100ms 50ms 50%    100kbit 200ms 50ms 50%
./set_tc.sh  200kbit 200ms 50ms 50%   1200kbit  80ms 50ms 50%    100kbit 200ms 50ms 50%
./set_tc.sh  200kbit 200ms 50ms 50%   5000kbit  10ms 10ms 50%    100kbit 200ms 50ms 50%
./set_tc.sh  300kbit 150ms 50ms 50%    300kbit 200ms 50ms 50%    100kbit 200ms 50ms 50%
ssh user@srv "sudo ifconfig eth1 up"
./set_tc.sh  300kbit 150ms 50ms 50%    600kbit 100ms 50ms 50%    100kbit 200ms 50ms 50%
./set_tc.sh  300kbit 150ms 50ms 50%    800kbit 100ms 50ms 50%    100kbit 200ms 50ms 50%
./set_tc.sh  300kbit 150ms 50ms 50%   1200kbit  80ms 50ms 50%    100kbit 200ms 50ms 50%
./set_tc.sh  300kbit 150ms 50ms 50%   5000kbit  10ms 10ms 50%    100kbit 200ms 50ms 50%
./set_tc.sh  600kbit 100ms 50ms 50%    600kbit 100ms 50ms 50%    100kbit 200ms 50ms 50%
ssh user@srv "sudo ifconfig eth2 down"
./set_tc.sh  600kbit 100ms 50ms 50%    800kbit 100ms 50ms 50%    100kbit 200ms 50ms 50%
./set_tc.sh  600kbit 100ms 50ms 50%   1200kbit  80ms 50ms 50%    100kbit 200ms 50ms 50%
ssh user@srv "sudo ifconfig eth2 up"
./set_tc.sh  600kbit 100ms 50ms 50%   5000kbit  10ms 10ms 50%    100kbit 200ms 50ms 50%
./set_tc.sh  800kbit 100ms 50ms 50%    800kbit 100ms 50ms 50%    100kbit 200ms 50ms 50%
./set_tc.sh  800kbit 100ms 50ms 50%   1200kbit  80ms 50ms 50%    100kbit 200ms 50ms 50%
./set_tc.sh  800kbit 100ms 50ms 50%   5000kbit  10ms 10ms 50%    100kbit 200ms 50ms 50%
./set_tc.sh 1200kbit  80ms 50ms 50%   1200kbit  80ms 50ms 50%    100kbit 200ms 50ms 50%
./set_tc.sh 1200kbit  80ms 50ms 50%   5000kbit  10ms 10ms 50%    100kbit 200ms 50ms 50%
./set_tc.sh 5000kbit  20ms 10ms 50%   5000kbit  10ms 10ms 50%    100kbit 200ms 50ms 50%
';

DELAY=5 # delay=5 sec sleep + 2 sec tc apply
PLEN=$(echo "$MAT" | wc -l)
TOTALTIME=$(($DELAY*$PLEN))
echo "Total test time is $TOTALTIME seconds, in $PLEN events of $DELAY sec. each"

echo "Worcking..."
echo "time_starttransfer %{time_starttransfer} time_total %{time_total} speed_download %{speed_download}" | ssh user@cli-32 "curl -m $TOTALTIME -s --connect-timeout 4 http://10.200.1.31/u -o /dev/null -w @- > /tmp/${PREFIX}speed" &

echo "Now applying scenario..."

date1=$(date +"%s")
IFS=$'\n'
CNT=0
for PARM in $MAT; do
    CNT=$((CNT+1))
    eval $PARM
    date2=$(date +"%s")
    diff=$(($date2-$date1))
    echo "Doing test $CNT of $PLEN Total test time is $TOTALTIME seconds; $diff seconds passed"
    sleep 5
done



sleep 1
ssh user@cli-32 "sync"
ssh user@cli-32 "cat /tmp/${PREFIX}speed | grep speed" >> /tmp/"$PREFIX".nojson
ssh user@cli-32 'echo "" >>  /tmp/${PREFIX}speed'
ssh user@cli-32 "ping -c 10 -q -a 10.200.1.31 | tail -3 >> /tmp/${PREFIX}speed"
echo "killall vtrunkd"
ssh user@srv-32 "sudo killall -9 vtrunkd && sudo ipcrm -M 567888"
ssh user@cli-32 "sudo killall -9 vtrunkd && sudo ipcrm -M 567888"
echo "Transfer syslogs"
scp user@cli-32:/var/log/syslog /tmp/${PREFIX}syslog-cli
scp user@srv-32:/var/log/syslog /tmp/${PREFIX}syslog-srv
grep `grep " Session " /tmp/${PREFIX}syslog-cli | awk -F[ {'print $2'} | awk -F] {'print $1'} | head -1` /tmp/${PREFIX}syslog-cli > /tmp/${PREFIX}syslog-1_cli
grep `grep " Session " /tmp/${PREFIX}syslog-cli | awk -F[ {'print $2'} | awk -F] {'print $1'} | tail -1` /tmp/${PREFIX}syslog-cli > /tmp/${PREFIX}syslog-2_cli
grep `grep " Session " /tmp/${PREFIX}syslog-srv | awk -F[ {'print $2'} | awk -F] {'print $1'} | head -1` /tmp/${PREFIX}syslog-srv > /tmp/${PREFIX}syslog-1_srv  
grep `grep " Session " /tmp/${PREFIX}syslog-srv | awk -F[ {'print $2'} | awk -F] {'print $1'} | tail -1` /tmp/${PREFIX}syslog-srv > /tmp/${PREFIX}syslog-2_srv
grep "First select time" /tmp/${PREFIX}syslog-cli > /tmp/${PREFIX}syslog-1_cli_select_time
grep "{\"p_" /tmp/${PREFIX}syslog-srv > /tmp/${PREFIX}syslog-srv_json
grep "{\"p_" /tmp/${PREFIX}syslog-cli > /tmp/${PREFIX}syslog-cli_json
grep "{\"p_" /tmp/${PREFIX}syslog-1_srv > /tmp/${PREFIX}syslog-1_srv_json
grep "{\"p_" /tmp/${PREFIX}syslog-1_cli > /tmp/${PREFIX}syslog-1_cli_json
grep "{\"p_" /tmp/${PREFIX}syslog-2_srv > /tmp/${PREFIX}syslog-2_srv_json
grep "{\"p_" /tmp/${PREFIX}syslog-2_cli > /tmp/${PREFIX}syslog-2_cli_json
#tar cvfj /tmp/${COUNT}.tbz /tmp/${PREFIX}*
tar cvf /tmp/${COUNT}.tbz --use-compress-prog=pbzip2 /tmp/${PREFIX}*
echo "Uploading logs..."
scp -P $DBOXHOST_PORT /tmp/${PREFIX}syslog-1_cli_json $DBOXHOST:~/Dropbox/alarm_logs/
scp -P $DBOXHOST_PORT /tmp/${PREFIX}syslog-2_cli_json $DBOXHOST:~/Dropbox/alarm_logs/
scp -P $DBOXHOST_PORT /tmp/${PREFIX}syslog-1_srv_json $DBOXHOST:~/Dropbox/alarm_logs/
scp -P $DBOXHOST_PORT /tmp/${PREFIX}syslog-2_srv_json $DBOXHOST:~/Dropbox/alarm_logs/
scp -P $DBOXHOST_PORT /tmp/${PREFIX}.nojson $DBOXHOST:~/Dropbox/alarm_logs/
echo "Uploading tbz..."
scp -P $DBOXHOST_PORT /tmp/${COUNT}.tbz $DBOXHOST:~/Dropbox/alarm_logs/
rm /tmp/${PREFIX}syslog*
echo "Drawing graphs"
ssh -p $DBOXHOST_PORT $DBOXHOST "cd ~/Dropbox/alarm_logs/; python ./parse_json_fusion.py $COUNT"
echo "Drawing graphs client"
ssh -p $DBOXHOST_PORT $DBOXHOST "cd ~/Dropbox/alarm_logs/; python ./parse_json_fusion_cli.py $COUNT"
echo "Clear alarm_logs..."
ssh -p $DBOXHOST_PORT $DBOXHOST "cd ~/Dropbox/alarm_logs/; rm *json"
echo "Clear syslog"
ssh user@cli-32 "cat /dev/null | sudo tee /var/log/syslog"
ssh user@srv-32 "cat /dev/null | sudo tee /var/log/syslog"
echo "Complete!!!"
