#!/bin/env python
import matplotlib
# Force matplotlib to not use any Xwindows backend.
matplotlib.use('Agg')
import sys, json
import sys, time, glob, os, numpy, datetime
import matplotlib.pyplot as plt


def parse_file(fn):
    l_json = []
    f = open(fn)
    for l in f:
        dl = l.split(" ");
        try:
            sdtime = dl[3];
            dt = time.strptime("14/09/12 %s000" % sdtime, '%d/%m/%y %H:%M:%S.%f');
        except:
            try:
                sdtime = dl[2];
                dt = time.strptime("14/09/12 %s000" % sdtime, '%d/%m/%y %H:%M:%S.%f');
            except:
                print "Could not parse date: \n%s\nwith:\n%s" % (l, repr(l.split(" ")))
                sys.exit()
        ms = int(sdtime.split(".")[1])
        t = int(time.mktime(dt))*1000+ms
        if "incomplete" in l:
            #print "Parsing", l, ":"
            #print l.split('{')
            data = json.loads('{' + l.split('{')[1])
            data["ts"] = t
            l_json.append(data)
    return l_json

def main():
    data_c1 = parse_file(sys.argv[1]+'_syslog-1_cli_json')
    data_c2 = parse_file(sys.argv[1]+'_syslog-2_cli_json')
    data_s1 = parse_file(sys.argv[1]+'_syslog-1_srv_json')
    data_s2 = parse_file(sys.argv[1]+'_syslog-2_srv_json')
    # now plot
    plot_data(sys.argv[1], data_c1, data_c2, data_s1, data_s2)

def plot_data(fn, data_c1, data_c2, data_s1,  data_s2):
    figurePlot = plt.figure(figsize=(23.5, 4.5 * 5))
    
    figurePlot.text(.5, .95, "SERVER\n"+open(fn+"_.nojson").read(), horizontalalignment='center')

    plotAX3 = plt.subplot(511)
    plotAX3.set_yscale('log')
    plt.title("speed (upload, server)")

    plt.plot(zipj(data_s1, "ts"), numpy.array(zipj(data_s1, "upload")), "-", label='upload1')
    plt.plot( zipj(data_s2, "ts"), numpy.array(zipj(data_s2, "upload")), "-", label="upload2")
    plt.plot(  zipj(data_s1, "ts"), numpy.array(zipj(data_s1, "magic_upload"))/1000.0, "-", label="magic_upload1")
    plt.plot( zipj(data_s2, "ts"), numpy.array(zipj(data_s2, "magic_upload"))/1000.0, "-", label="magic_upload2")
    plt.plot(  zipj(data_s1, "ts"), zipj(data_s1, "ACK_coming_speed"), "-", label="ACK_coming_speed1")
    plt.plot( zipj(data_s2, "ts"), zipj(data_s2, "ACK_coming_speed"), "-", label="ACK_coming_speed2")
    plt.legend()
    
    DNAME='my_max_send_q'
    plotAX3 = plt.subplot(512)
    plt.title(DNAME + " (server)")
    plt.plot(zipj(data_s1, "ts"), zipj(data_s1, DNAME), "-", label="my_max_send_q1", color="b")
    plt.plot(zipj(data_s2, "ts"), zipj(data_s2, DNAME), "-", label="my_max_send_q2", color="g")
    plt.plot(zipj(data_s1, "ts"), zipj(data_s1, "send_q_limit"), "-", label="send_q_limit1", color="r")
    plt.plot(zipj(data_s2, "ts"), zipj(data_s2, "send_q_limit"), "-", label="send_q_limit2", color="k")
    plt.legend()
    
    DNAME='rtt'
    plotAX3 = plt.subplot(513)
    plt.title("rtt (server)")
    plt.plot(zipj(data_s1, "ts"), zipj(data_s1, DNAME), "-", label="rtt1", color="b")
    plt.plot(zipj(data_s2, "ts"), zipj(data_s2, DNAME), "-", label="rtt2", color="g")
    plt.plot(zipj(data_s1, "ts"), zipj(data_s1, 'my_rtt'), "-", label="my_rtt1", color="r")
    plt.plot(zipj(data_s2, "ts"), zipj(data_s2, 'my_rtt'), "-", label="my_rtt2", color="k")
    plt.plot(zipj(data_s1, "ts"), zipj(data_s1, 'magic_rtt'), "-", label="magic_rtt_1", c="m")
    plt.plot(zipj(data_s2, "ts"), zipj(data_s2, 'magic_rtt'), "-", label="magic_rtt_2", c="y")
    plt.legend()

    DNAME="buf_len"    
    plotAX1 = plt.subplot(514)
    plt.title(DNAME+ " (client)")
    plt.plot(zipj(data_c1, "ts"), zipj(data_c1, DNAME), "-")
    plt.plot(zipj(data_s1, "ts"), numpy.array(zipj(data_s1, "hold_mode"))*90, ".", label="hold_mode1")
    plt.plot(zipj(data_s2, "ts"), numpy.array(zipj(data_s2, "hold_mode"))*100, ".", label="hold_mode2")
    try:
        plt.plot(zipj(data_s1, "ts"), numpy.array(zipj(data_s1, "R_MODE"))*50, ".", label="R_MODE1")
        plt.plot(zipj(data_s2, "ts"), numpy.array(zipj(data_s2, "R_MODE"))*45, ".", label="R_MODE2")
    except KeyError:
        print "WARNING: OLD json detected"
    plt.legend()
    
    DNAME='incomplete_seq_len'
    plotAX2 = plt.subplot(515)
    plt.title(DNAME + " (client)")
    plt.plot(zipj(data_c1, "ts"), zipj(data_c1, DNAME), "-")
    

#    DNAME='download'
#    plotAX2 = plt.subplot(415)
#    plt.title(DNAME)
#    plt.plot(zipj(data_c1, "ts"), zipj(data_c1, DNAME), "-", zipj(data_c2, "ts"), zipj(data_c2, DNAME), "-")    
    
    figurePlot.savefig(fn+".png", dpi=100)
    
def zipj(l_json, name):
    d = []
    for j in l_json:
        d.append(j[name])
    return d

if __name__ == '__main__':
    main()
