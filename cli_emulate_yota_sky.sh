#!/bin/sh

# eth1
echo "eth1 - good yota:"
tc qdisc del dev eth1 root
tc qdisc add dev eth1 root handle 1: htb default 12
tc class add dev eth1 parent 1:1 classid 1:12 htb rate 300kbit ceil 300kbit
tc qdisc add dev eth1 parent 1:12 netem delay 30ms
tc -s qdisc ls dev eth1
tc -s class ls dev eth1

# eth2
echo "eth2 : good 3g/cdma"
tc qdisc del dev eth2 root
tc qdisc add dev eth2 root handle 1: htb default 12
tc class add dev eth2 parent 1:1 classid 1:12 htb rate 100kbit ceil 100kbit
tc qdisc add dev eth2 parent 1:12 netem delay 30ms
tc -s qdisc ls dev eth2
tc -s class ls dev eth2

# eth3
echo "eth3 : goog 3g/cdma"
tc qdisc del dev eth3 root
tc qdisc add dev eth3 root handle 1: htb default 12
tc class add dev eth3 parent 1:1 classid 1:12 htb rate 200kbit ceil 200kbit
tc qdisc add dev eth3 parent 1:12 netem delay 20ms
tc -s qdisc ls dev eth3
tc -s class ls dev eth3
