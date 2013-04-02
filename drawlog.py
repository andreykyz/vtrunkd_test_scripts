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


def parse_str(ss):
    l_json = []
    for l in ss.split("\n"):
        dl = l.split();
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

def toilet(filename):
    import string
    valid_chars = "-_.() %s%s" % (string.ascii_letters, string.digits)
    return ''.join(c for c in filename if c in valid_chars)


def main():
    form = cgi.FieldStorage()
    if not "session" in form:
        print "Content-type: text/html\n"
        print """<html><body>No input session given</body></html>"""
        sys.exit()
    session=toilet(form["session"].value)
    l=int(form["length"].value)
    if len(session) < 5 or len(session) > 16:
        sys.exit()
    # now prepare logfile
    jsons=commands.getoutput("grep '%s' /var/log/syslog | grep '{' | tail -n %s" % (session, str(l)))
    #data_cli = parse_file(sys.argv[1]+'_syslog-cli_json')
    data_srv = parse_str(jsons)
    # now plot
    plot_data("/tmp/plot_%s.png" % session, None, data_srv)

def unused():
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
    DNAME='incomplete_seq_len'
    plotAX2 = plt.subplot(515)
    plt.title(DNAME + " (client)")
    plt.plot(zipj(data_cli_arr[0], "ts"), zipj(data_cli_arr[0], 'isl'), "-")



# name send_q_limit send_q rtt my_rtt cwnd isl buf_len upload hold_mode ACS R_MODE
def plot_data(fn, data_cli, data_srv):
    
    data_srv_arr=[]
    someName = ""    
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
    figurePlot.text(.5, .95, "Real-time", horizontalalignment='center')

    plotAX3 = plt.subplot(511)
    plotAX3.set_yscale('log')
    plt.title("ACK coming speed")
    i=0
    for someLine in data_srv_arr:
        plt.plot(zipj(data_srv_arr[i], "ts"), zipj(data_srv_arr[i], "ACS"), "-", label="ACK_coming_speed "+data_srv_arr[i][0]['name'])
	plt.legend(bbox_to_anchor=(0, 1), loc=2, borderaxespad=0.)
        i= i+1
        
    plotAX3 = plt.subplot(512)
    plotAX3.set_yscale('log')
    plt.title("speed ")
    i=0
    for someLine in data_srv_arr:
        try:
            plt.plot(zipj(data_srv_arr[i], "ts"), zipj(data_srv_arr[i], "upload"), "-", label='upload '+data_srv_arr[i][0]['name'])
        except ValueError:
            plotAX3.set_yscale('linear')
        plt.plot(zipj(data_srv_arr[i], "ts"), zipj(data_srv_arr[i], "s_r_m"), "-", label='speed_garbage '+data_srv_arr[i][0]['name'])
        plt.plot(zipj(data_srv_arr[i], "ts"), zipj(data_srv_arr[i], "s_r"), "-", label='speed_resend '+data_srv_arr[i][0]['name'])
        plt.plot(zipj(data_srv_arr[i], "ts"), zipj(data_srv_arr[i], "s_e"), "-", label='speed_effecient '+data_srv_arr[i][0]['name'], linestyle='--')
        plt.legend()
        i= i+1
    
    DNAME='send_q'
    plotAX3 = plt.subplot(513)
    plt.title(DNAME + " (server)")
    i=0
    for someLine in data_srv_arr:
        plt.plot(zipj(data_srv_arr[i], "ts"), zipj(data_srv_arr[i], "s_q_lim"), "-", label="send_q_limit "+data_srv_arr[i][0]['name'])
        if data_srv_arr[i][2]['s_q_min'] != 120000 :
            plt.plot(zipj(data_srv_arr[i], "ts"), zipj(data_srv_arr[i], "s_q_min"), "-", label="max_send_q_min "+data_srv_arr[i][0]['name'])
            plt.plot(zipj(data_srv_arr[i], "ts"), zipj(data_srv_arr[i], "s_q_max"), "-", label="max_send_q_max "+data_srv_arr[i][0]['name'])
            plt.plot(zipj(data_srv_arr[i], "ts"), zipj(data_srv_arr[i], "s_q"), "-", label="max_send_q_avg "+data_srv_arr[i][0]['name'], linestyle='--')
        else:
            plt.plot(zipj(data_srv_arr[i], "ts"), zipj(data_srv_arr[i], "s_q"), "-", label="max_send_q "+data_srv_arr[i][0]['name'])
   	plt.legend(bbox_to_anchor=(0, 1), loc=2, borderaxespad=0.)
        i= i+1
    
    DNAME='rtt'
    plotAX3 = plt.subplot(514)
    plt.title("rtt (server)")
    i=0
    for someLine in data_srv_arr:
        plt.plot(zipj(data_srv_arr[i], "ts"), zipj(data_srv_arr[i], 'my_rtt'), "-", label="my_rtt "+data_srv_arr[i][0]['name'])
        plt.plot(zipj(data_srv_arr[i], "ts"), zipj(data_srv_arr[i], 'rtt'), "-", label="magic_rtt "+data_srv_arr[i][0]['name'])
	plt.legend(bbox_to_anchor=(0, 1), loc=2, borderaxespad=0.)
        i= i+1

    DNAME="buf_len"    
    plotAX1 = plt.subplot(515)
    plt.title(DNAME+ " (client)")
    i=0
    plt.plot(zipj(data_cli_arr[0], "ts"), zipj(data_cli_arr[0], 'buf_len'), "-")
#    plt.plot(zipj(data_cli_arr[0], "ts"), zipj(data_cli_arr[0], 'r_buf_len'), "-")
    for someLine in data_srv_arr:
        plt.plot(zipj(data_srv_arr[i], "ts"), numpy.array(zipj(data_srv_arr[i], "hold_mode"))*((i*10)+90), ".", label="hold_mode "+data_srv_arr[i][0]['name'])
        plt.plot(zipj(data_srv_arr[i], "ts"), numpy.array(zipj(data_srv_arr[i], "R_MODE"))*((i*10)+30), ".", label="R_MODE "+data_srv_arr[i][0]['name'])
	plt.legend(bbox_to_anchor=(0, 1), loc=2, borderaxespad=0.)
        i=i+1
    
    
    figurePlot.savefig(fn, dpi=100)
    print "Content-type: image/png\n"
    print file(fn).read()
    
def zipj(l_json, name):
    d = []
    for j in l_json:
        d.append(j[name])
    return d

if __name__ == '__main__':
    main()
