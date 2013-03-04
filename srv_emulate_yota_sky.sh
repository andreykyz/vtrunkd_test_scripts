#!/bin/sh

# eth1
echo "eth1 - good yota:"
tc qdisc del dev eth1 root
tc qdisc add dev eth1 root handle 1: htb default 12
tc class add dev eth1 parent 1:1 classid 1:12 htb rate 10mbit ceil 10mbit
tc qdisc add dev eth1 parent 1:12 netem delay 30ms 100ms 5%
tc -s qdisc ls dev eth1
tc -s class ls dev eth1

# eth2
echo "eth2 : good 3g/cdma"
tc qdisc del dev eth2 root
tc qdisc add dev eth2 root handle 1: htb default 12
tc class add dev eth2 parent 1:1 classid 1:12 htb rate 500kbit ceil 500kbit
tc qdisc add dev eth2 parent 1:12 netem delay 60ms 150ms 10%
tc -s qdisc ls dev eth2
tc -s class ls dev eth2

# eth3
echo "eth3 : goog 3g/cdma"
tc qdisc del dev eth3 root
tc qdisc add dev eth3 root handle 1: htb default 12
tc class add dev eth3 parent 1:1 classid 1:12 htb rate 7mbit ceil 7mbit
tc qdisc add dev eth3 parent 1:12 netem delay 35ms 110ms 5%
tc -s qdisc ls dev eth3
tc -s class ls dev eth3
