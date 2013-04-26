#!/usr/bin/python
import os,commands 
import tempfile
os.environ['MPLCONFIGDIR'] = tempfile.mkdtemp()
import cgi
import cgitb
cgitb.enable()
import matplotlib
# Force matplotlib to not use any Xwindows backend.
matplotlib.use('Agg')
import sys, json
import sys, time, glob, os, numpy, datetime
import matplotlib.pyplot as plt
import colorsys,time



def parse_str(ss):
    l_json = []
    for l in ss.split("\n"):
        dl = l.split();
        if len(l) < 5: continue
        try:
            sdtime = dl[2];
            dt = time.strptime("14/09/12 %s000" % sdtime, '%d/%m/%y %H:%M:%S.%f');
        except:
            raise ValueError("Could not parse date: \n%s\nwith:\n%s" % (l, repr(l.split(" "))))
            sys.exit()
        ms = int(sdtime.split(".")[1])
        t = int(time.mktime(dt))*1000+ms
        data = json.loads('{' + l.split('{')[1])
        data["ts"] = t
        l_json.append(data)
    return l_json


def main():
    """
    form = cgi.FieldStorage()
    if not "session" in form:
        print "Content-type: text/html\n"
        print "<html><body>No input session given</body></html>"
        sys.exit()

    session=toilet(form["session"].value)

    if session != "123":
        print "Content-type: text/html\n"
        print "<html><body>Session error</body></html>"
        sys.exit()
    """
    names = []
    try:
        jsons=commands.getoutput("tail -n 10000 /var/log/syslog | grep '{\"name'")
        data_srv = parse_str(jsons)
        for j in data_srv:
            if not j["name"].split("_")[0] in names:
                names.append(j["name"].split("_")[0])
    except:
        pass
    print "Content-type: text/html\n"
    print "<html><head><title>A</title><meta http-equiv=\"refresh\" content=\"30;URL=/cgi-bin/drawallr.py\" ></head><body style=\"background: #aaaaaa\">"

    
    for n in names:
        print '<img src="/cgi-bin/drawall.py?session=%s&length=%s&dummy=%s" width=667 height=160/>' % (n,700,int(time.time()))
    
    print "</body></html>"
    
if __name__ == '__main__':
    main()
