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
        dl = l.split();
        try:
            sdtime = dl[2];
            dt = time.strptime("14/09/12 %s000" % sdtime, '%d/%m/%y %H:%M:%S.%f');
        except:
            print "Could not parse date: \n%s\nwith:\n%s" % (l, repr(l.split(" ")))
            sys.exit()
        ms = int(sdtime.split(".")[1])
        t = int(time.mktime(dt))*1000+ms
        data = json.loads('{' + l.split('{')[1])
        data["ts"] = t
        l_json.append(data)
    return l_json

def main():
    data_cli = parse_file(sys.argv[1]+'_syslog-cli_json')
    data_srv = parse_file(sys.argv[1]+'_syslog-srv_json')
    # now plot
    plot_data(sys.argv[1], data_cli, data_srv)

# name send_q_limit send_q rtt my_rtt cwnd isl buf_len upload hold_mode ACS R_MODE
def plot_data(fn, data_cli, data_srv):
    data_cli_arr=[]
    data_srv_arr=[]
    someName = ""
    for jsonLine in data_cli:
        if len(data_cli_arr) == 0:
            data_cli_arr_item = []
            data_cli_arr_item.append(jsonLine)
            data_cli_arr.append(data_cli_arr_item)
        else:
            succ=0
            for someArr in data_cli_arr:
                if someArr[0]['name'] == jsonLine['name']:
                    someArr.append(jsonLine)
                    succ = 1
                    break
            if succ == 1:
                continue
            data_cli_arr_item = []
            data_cli_arr_item.append(jsonLine)
            data_cli_arr.append(data_cli_arr_item)
        
    for jsonLine in data_srv:
        if len(data_srv_arr) == 0:
            data_srv_arr_item = []
            data_srv_arr_item.append(jsonLine)
            data_srv_arr.append(data_srv_arr_item)
        else:
            succ=0
            for someArr in data_srv_arr:
                if someArr[0]['name'] == jsonLine['name']:
                    someArr.append(jsonLine)
                    succ = 1
                    break
            if succ == 1:
                continue
            data_srv_arr_item = []
            data_srv_arr_item.append(jsonLine)
            data_srv_arr.append(data_srv_arr_item)
            
	figurePlot = plt.figure(figsize=(23.5, 4.5 * 5))
    figurePlot.text(.5, .95, "SERVER\n"+open(fn+"_.nojson").read(), horizontalalignment='center')

    plotAX3 = plt.subplot(511)
    plt.title("speed (upload, client)")
    i=0
    for someLine in data_cli_arr:
        plt.plot(zipj(data_cli_arr[i], "ts"), zipj(data_cli_arr[i], "upload"), "-", label='upload '+data_cli_arr[i][0]['name'])
        plt.plot(zipj(data_cli_arr[i], "ts"), zipj(data_cli_arr[i], "ACS"), "-", label="ACK_coming_speed "+data_cli_arr[i][0]['name'])
        plt.plot(zipj(data_cli_arr[i], "ts"), zipj(data_cli_arr[i], "cwnd"), "-", label="cwnd "+data_cli_arr[i][0]['name'])
        plt.legend()
        i= i+1
    
    DNAME='send_q'
    plotAX3 = plt.subplot(512)
    plt.title(DNAME + " (client)")
    i=0
    for someLine in data_cli_arr:
        plt.plot(zipj(data_cli_arr[i], "ts"), zipj(data_cli_arr[i], "s_q"), "-", label="my_max_send_q "+data_cli_arr[i][0]['name'])
        plt.plot(zipj(data_cli_arr[i], "ts"), zipj(data_cli_arr[i], "s_q_limit"), "-", label="send_q_limit "+data_cli_arr[i][0]['name'])
        plt.legend()
        i= i+1
    
    DNAME='rtt'
    plotAX3 = plt.subplot(513)
    plt.title("rtt (client)")
    i=0
    for someLine in data_cli_arr:
        plt.plot(zipj(data_cli_arr[i], "ts"), zipj(data_cli_arr[i], 'my_rtt'), "-", label="my_rtt "+data_cli_arr[i][0]['name'])
        plt.plot(zipj(data_cli_arr[i], "ts"), zipj(data_cli_arr[i], 'my_rtt'), "-", label="my_rtt "+data_cli_arr[i][0]['name'])
        plt.plot(zipj(data_cli_arr[i], "ts"), zipj(data_cli_arr[i], 'rtt'), "-", label="magic_rtt "+data_cli_arr[i][0]['name'])
        plt.plot(zipj(data_cli_arr[i], "ts"), zipj(data_cli_arr[i], 'rtt'), "-", label="magic_rtt "+data_cli_arr[i][0]['name'])
        plt.legend()
        i= i+1

    DNAME="buf_len"    
    plotAX1 = plt.subplot(514)
    plt.title(DNAME+ " (server)")
    i=0
    plt.plot(zipj(data_srv_arr[0], "ts"), zipj(data_srv_arr[0], 'buf_len'), "-")
    for someLine in data_cli_arr:
        plt.plot(zipj(data_cli_arr[i], "ts"), numpy.array(zipj(data_cli_arr[i], "hold_mode"))*((i*10)+90), ".", label="hold_mode "+data_cli_arr[i][0]['name'])
        plt.plot(zipj(data_cli_arr[i], "ts"), numpy.array(zipj(data_cli_arr[i], "R_MODE"))*((i*10)+30), ".", label="R_MODE "+data_cli_arr[i][0]['name'])
        plt.legend()
        i=i+1
    
    DNAME='incomplete_seq_len'
    plotAX2 = plt.subplot(515)
    plt.title(DNAME + " (server)")
    plt.plot(zipj(data_srv_arr[0], "ts"), zipj(data_srv_arr[0], 'isl'), "-")

    figurePlot.savefig(fn+"c.png", dpi=100)
    
def zipj(l_json, name):
    d = []
    for j in l_json:
        d.append(j[name])
    return d

if __name__ == '__main__':
    main()
