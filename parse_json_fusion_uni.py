#!/bin/env python
import matplotlib
# Force matplotlib to not use any Xwindows backend.
matplotlib.use('Agg')
import sys, json
import sys, time, glob, os, numpy, datetime
import matplotlib.pyplot as plt
import colorsys

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
    plotAX3.set_yscale('log')
    plt.title("ACK coming speed")
    i=0
    for someLine in data_srv_arr:
        plt.plot(zipj(data_srv_arr[i], "ts"), zipj(data_srv_arr[i], "ACS"), "-", label="ACK_coming_speed "+data_srv_arr[i][0]['name'])
        plt.legend()
        i= i+1

    plotAX3 = plt.subplot(512)
#    plotAX3.set_yscale('log')
    plt.title("speed ")
    i=0
    for someLine in data_srv_arr:
        plt.plot(zipj(data_srv_arr[i], "ts"), zipj(data_srv_arr[i], "s_r_m"), "-", label='speed_garbage '+data_srv_arr[i][0]['name'],c=tohex(*(colorsys.hsv_to_rgb((1./6)*(i),1,1))))
        plt.plot(zipj(data_srv_arr[i], "ts"), zipj(data_srv_arr[i], "s_r"), "-", label='speed_resend '+data_srv_arr[i][0]['name'],c=tohex(*(colorsys.hsv_to_rgb((1./6)*(i),1,0.8))))
        plt.plot(zipj(data_srv_arr[i], "ts"), zipj(data_srv_arr[i], "s_e"), "-", label='speed_effecient '+data_srv_arr[i][0]['name'],c=tohex(*(colorsys.hsv_to_rgb((1./6)*(i),1,0.6))))
#        plt.plot(zipj(data_srv_arr[i], "ts"), zipj(data_srv_arr[i], "upload"), "-", label='upload '+data_srv_arr[i][0]['name'])
        plt.legend()
        i= i+1
    
    DNAME='send_q'
    plotAX3 = plt.subplot(513)
    plt.title(DNAME + " (server)")
    i=0
    for someLine in data_srv_arr:
        plt.plot(zipj(data_srv_arr[i], "ts"), zipj(data_srv_arr[i], "s_q_lim"), "-", label="send_q_limit "+data_srv_arr[i][0]['name'],marker='*',c=tohex(*(colorsys.hsv_to_rgb((1./6)*(i),1,0.6))))
        if data_srv_arr[i][2]['s_q_min'] != 120000 :
            plt.plot(zipj(data_srv_arr[i], "ts"), zipj(data_srv_arr[i], "s_q_min"), "-", label="max_send_q_min "+data_srv_arr[i][0]['name'],c=tohex(*(colorsys.hsv_to_rgb((1./6)*(i),1,0.8))))
            plt.plot(zipj(data_srv_arr[i], "ts"), zipj(data_srv_arr[i], "s_q_max"), "-", label="max_send_q_max "+data_srv_arr[i][0]['name'],c=tohex(*(colorsys.hsv_to_rgb((1./6)*(i),1,1))))
            plt.plot(zipj(data_srv_arr[i], "ts"), zipj(data_srv_arr[i], "s_q"), "-", label="max_send_q_avg "+data_srv_arr[i][0]['name'], linestyle='--',c=tohex(*(colorsys.hsv_to_rgb((1./6)*(i),1,1))))
        else:
            plt.plot(zipj(data_srv_arr[i], "ts"), zipj(data_srv_arr[i], "s_q"), "-", label="max_send_q "+data_srv_arr[i][0]['name'],c=tohex(*(colorsys.hsv_to_rgb((1./6)*(i),1,1))))
        plt.legend()
        i= i+1
    
    DNAME='rtt'
    plotAX3 = plt.subplot(514)
    plt.title("rtt (server)")
    i=0
    for someLine in data_srv_arr:
        plt.plot(zipj(data_srv_arr[i], "ts"), zipj(data_srv_arr[i], 'my_rtt'), "-", label="my_rtt "+data_srv_arr[i][0]['name'])
        plt.plot(zipj(data_srv_arr[i], "ts"), zipj(data_srv_arr[i], 'rtt'), "-", label="magic_rtt "+data_srv_arr[i][0]['name'])
        plt.legend()
        i= i+1

    DNAME="buf_len"    
    plotAX1 = plt.subplot(515)
    plt.title(DNAME+ " (client)")
    i=0
    plt.plot(zipj(data_srv_arr[0], "ts"), zipj(data_srv_arr[0], 'buf_len'), "-")
#    plt.plot(zipj(data_cli_arr[0], "ts"), zipj(data_cli_arr[0], 'r_buf_len'), "-")
    for someLine in data_srv_arr:
        plt.plot(zipj(data_srv_arr[i], "ts"), numpy.array(zipj(data_srv_arr[i], "hold_mode"))*((i*10)+90), ".", label="hold_mode "+data_srv_arr[i][0]['name'])
        plt.plot(zipj(data_srv_arr[i], "ts"), numpy.array(zipj(data_srv_arr[i], "R_MODE"))*((i*10)+30), ".", label="R_MODE "+data_srv_arr[i][0]['name'])
        plt.legend()
        i=i+1
    
    figurePlot.savefig(fn+".png", dpi=100)
    
def zipj(l_json, name):
    d = []
    for j in l_json:
        d.append(j[name])
    return d

def zip_sum(l_json, name):
    d = []
    summ = 0
    for i in l_json[0]:
        q = 0
        summ = 0
        for j in l_json:
            summ = summ + j[q][name]
            q = q+1
        d.append(summ)
    return d

def tohex(r,g,b):
	hexchars = "0123456789ABCDEF"
	r = int(r * 255)
	g = int(g * 255)
	b = int(b * 255)
	return "#" + hexchars[r / 16] + hexchars[r % 16] + hexchars[g / 16] + hexchars[g % 16] + hexchars[b / 16] + hexchars[b % 16]

if __name__ == '__main__':
    main()
