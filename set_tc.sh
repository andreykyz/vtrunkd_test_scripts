#!/bin/bash

VALSET="$1 $2 $3 $4 $5 $6 $7 $8 $9 ${10} ${11} ${12}"

TCRULES=/tmp/tcrules.sh
VTRUNKD_V_ROOT=/home/user/sandbox/vtrunkd_test1

re="([A-Za-z0-9]+)\s+([a-z0-9]+)\s+([a-z0-9]+)\s+([a-z0-9\%]+)\s+([A-Za-z0-9]+)\s+([a-z0-9]+)\s+([a-z0-9]+)\s+([a-z0-9\%]+)\s+([A-Za-z0-9]+)\s+([a-z0-9]+)\s+([a-z0-9]+)\s+([a-z0-9\%]+)$"
echo "Doing $VALSET"
# IFS=" "; echo $VALSET | read rate1 delay1 jit1 percent1 rate2 delay2 jit2 percent2 rate3 delay3 jit3 percent3
[[ $VALSET =~ $re ]] && rate1="${BASH_REMATCH[1]}" && delay1="${BASH_REMATCH[2]}" && jit1="${BASH_REMATCH[3]}" && percent1="${BASH_REMATCH[4]}" && rate2="${BASH_REMATCH[5]}" && delay2="${BASH_REMATCH[6]}" && jit2="${BASH_REMATCH[7]}" && percent2="${BASH_REMATCH[8]}" && rate3="${BASH_REMATCH[9]}" && delay3="${BASH_REMATCH[10]}" && jit3="${BASH_REMATCH[11]}" && percent3="${BASH_REMATCH[12]}" 


cat > $TCRULES<<EOF
#!/bin/sh

# eth1
echo "eth1 - bad yota:"
tc qdisc del dev eth1 root
tc qdisc add dev eth1 root handle 1: htb default 12
tc class add dev eth1 parent 1:1 classid 1:12 htb rate $rate1 ceil $rate1
tc qdisc add dev eth1 parent 1:12 netem delay $delay1 $jit1 $percent1
tc -s qdisc ls dev eth1
tc -s class ls dev eth1

# eth2
echo "eth2 : good 3g/cdma"
tc qdisc del dev eth2 root
tc qdisc add dev eth2 root handle 1: htb default 12
tc class add dev eth2 parent 1:1 classid 1:12 htb rate $rate2 ceil $rate2
tc qdisc add dev eth2 parent 1:12 netem delay $delay2 $jit2 $percent2
tc -s qdisc ls dev eth2
tc -s class ls dev eth2

# eth3
echo "eth3 : goog 3g/cdma"
tc qdisc del dev eth3 root
tc qdisc add dev eth3 root handle 1: htb default 12
tc class add dev eth3 parent 1:1 classid 1:12 htb rate $rate3 ceil $rate3
tc qdisc add dev eth3 parent 1:12 netem delay $delay3 $jit3 $percent3
tc -s qdisc ls dev eth3
tc -s class ls dev eth3
EOF

echo "Copying TC rules from $TCRULES"
scp $TCRULES user@srv-32:$VTRUNKD_V_ROOT/test/srv_emulate_2.sh

echo "Applying emulation TC rules"

ssh user@srv-32 "sudo $VTRUNKD_V_ROOT/test/srv_emulate_2.sh"


