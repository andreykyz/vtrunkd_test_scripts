#!/bin/sh

# eth1
echo "eth1 - good yota:"
tc qdisc del dev eth1 root
tc qdisc add dev eth1 root handle 1: htb default 12
tc class add dev eth1 parent 1:1 classid 1:12 tbf rate 10mbit limit 20kb burst 10kb
tc qdisc add dev eth1 parent 1:12 netem delay 20ms 10ms 5%
tc -s qdisc ls dev eth1
tc -s class ls dev eth1

# eth2
echo "eth2 : good 3g/cdma"
tc qdisc del dev eth2 root
tc qdisc add dev eth2 root handle 1: htb default 12
tc class add dev eth2 parent 1:1 classid 1:12 tbf rate 500kbit limit 20kb burst 10kb
tc qdisc add dev eth2 parent 1:12 netem delay 35ms 20ms 10%
tc -s qdisc ls dev eth2
tc -s class ls dev eth2

# eth3
echo "eth3 : goog 3g/cdma"
tc qdisc del dev eth3 root
tc qdisc add dev eth3 root handle 1: htb default 12
tc class add dev eth3 parent 1:1 classid 1:12 tbf rate 7mbit limit 20kb burst 10kb
tc qdisc add dev eth3 parent 1:12 netem delay 25ms 10ms 5%
tc -s qdisc ls dev eth3
tc -s class ls dev eth3
