#!/usr/bin/python

from commands import getoutput as go
import time,math,sys,numpy
#from __future__ import print_function
import __future__
stat = []
prev_max = 0
counter=0
try:
    f = open("%scwnd" % (sys.argv[1]),'w')
except:
    f = open("cwnd",'w')
try:
    while True:
        x = go("ss -i | grep cwnd");
        a=[]
        for l in x.split("\n"):
            if "cwnd" in l:
                cwnd = int(l.split("cwnd:")[1].split()[0])
                a.append(cwnd)
        # TODO: shift logarithm by 50 points - we never have less than 10 pkt in cwnd
        print("%d %s" % (max(a), "*"*int(math.log(float(max(a)),1.035))))
        f.write("{\"cwnd\":%d,\"time\":%d}\n" % (max(a),counter))
        if max(a) < prev_max:
            stat.append(float(prev_max))
        prev_max = max(a)
        counter = counter + 1
        time.sleep(0.1)
except KeyboardInterrupt:
     f.close()
     print("ff")
#    print(stat)
#    print("Total drops: %d %s %d %s %d" % (len(stat), "at", numpy.mean(stat), "+-", numpy.std(stat)))
