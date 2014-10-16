#!/usr/bin/python

from commands import getoutput as go
import time
import numpy

stat = []
prev_max = 0
try:
    while True:
        x = go("ss -i | grep cwnd");
        a=[]
        sst = []
        for l in x.split("\n"):
            if "cwnd" in l:
                cwnd = int(l.split("cwnd:")[1].split()[0])
                a.append(cwnd)
            if "ssthresh" in l:
                cwnd = int(l.split("ssthresh:")[1].split()[0])
                sst.append(cwnd)

        print max(a), "*"*max(a)
        #print max(sst), "-"*max(sst)
        if max(a) < prev_max:
            stat.append(float(prev_max))
        prev_max = max(a)
        time.sleep(0.1)
except KeyboardInterrupt:
    print stat
    print "Total drops:", len(stat), "at", numpy.mean(stat), "+-", numpy.std(stat)
    
