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
import colorsys

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
    try:
        plot_data("/tmp/plot_%s.png" % session, None, data_srv)
    except ValueError:
        plot_data("/tmp/plot_%s.png" % session, None, data_srv, False)

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
def plot_data(fn, data_cli, data_srv, logax=True):
    
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
    if logax: plotAX3.set_yscale('log')
    plt.title("ACK coming speed")
    i=0
    for someLine in data_srv_arr:
        plt.plot(zipj(data_srv_arr[i], "ts"), zipj(data_srv_arr[i], "ACS"), "-", label="ACK_coming_speed "+data_srv_arr[i][0]['name'])
	plt.legend(bbox_to_anchor=(0, 1), loc=2, borderaxespad=0.)
        i= i+1
        

    plotAX3 = plt.subplot(512)
    if logax: plotAX3.set_yscale('log')
    plt.title("speed ")
    i=0
    for someLine in data_srv_arr:
#        try:
#            plt.plot(zipj(data_srv_arr[i], "ts"), zipj(data_srv_arr[i], "upload"), "-", label='upload '+data_srv_arr[i][0]['name'])
#        except ValueError:
#            plotAX3.set_yscale('linear')
        plt.plot(zipj(data_srv_arr[i], "ts"), zipj(data_srv_arr[i], "s_r_m"), "--", label='speed_garbage '+data_srv_arr[i][0]['name'],c=tohex(*(colorsys.hsv_to_rgb((1./6)*(i),1,1))))
        plt.plot(zipj(data_srv_arr[i], "ts"), zipj(data_srv_arr[i], "s_r"), "*", label='speed_resend '+data_srv_arr[i][0]['name'],c=tohex(*(colorsys.hsv_to_rgb((1./6)*(i),1,0.8))))
        plt.plot(zipj(data_srv_arr[i], "ts"), zipj(data_srv_arr[i], "s_e"), "-", label='speed_eff '+data_srv_arr[i][0]['name'],c=tohex(*(colorsys.hsv_to_rgb((1./6)*(i),1,0.6))))
        plt.legend(bbox_to_anchor=(0, 1), loc=2, borderaxespad=0.)
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
            plt.plot(zipj(data_srv_arr[i], "ts"), zipj(data_srv_arr[i], "b_sel"), "-",label="bad_selects "+data_srv_arr[i][0]['name'], linestyle=':',c=tohex(*(colorsys.hsv_to_rgb((1./6)*(i),1,0.7))))
            plt.plot(zipj(data_srv_arr[i], "ts"), zipj(data_srv_arr[i], "g_sel"), "-",label="good_selects "+data_srv_arr[i][0]['name'], linestyle=':',c=tohex(*(colorsys.hsv_to_rgb((1./6)*(i),1,0.3))))
        else:
            plt.plot(zipj(data_srv_arr[i], "ts"), zipj(data_srv_arr[i], "s_q"), "-", label="max_send_q "+data_srv_arr[i][0]['name'],c=tohex(*(colorsys.hsv_to_rgb((1./6)*(i),1,1))))
   	plt.legend(bbox_to_anchor=(0, 1), loc=2, borderaxespad=0.)
        i= i+1
    

    for data_arr in data_srv_arr:
        for json in data_arr:
            if json["R_MODE"] == 2:
                plt.annotate(json['name'], xy=(int(json['ts']), int(90000)),  xycoords='data', xytext=(int(json['ts']), int(135000)), textcoords='data', arrowprops=dict(facecolor='red', shrink=0.05),  horizontalalignment='right', verticalalignment='top')
            if json["R_MODE"] == 3:
                plt.annotate(json['name'], xy=(int(json['ts']), int(90000)),  xycoords='data', xytext=(int(json['ts']), int(135000)), textcoords='data', arrowprops=dict(facecolor='green', shrink=0.05),  horizontalalignment='right', verticalalignment='top')


    DNAME='rtt'
    plotAX3 = plt.subplot(514)
    if logax: plotAX3.set_yscale('log')
    plt.title("rtt (server)")
    i=0
    for someLine in data_srv_arr:
        plt.plot(zipj(data_srv_arr[i], "ts"), zipj(data_srv_arr[i], 'my_rtt'), "-", label="my_rtt "+data_srv_arr[i][0]['name'])
        plt.plot(zipj(data_srv_arr[i], "ts"), zipj(data_srv_arr[i], 'rtt'), "-", label="magic_rtt "+data_srv_arr[i][0]['name'])
	plt.legend(bbox_to_anchor=(0, 1), loc=2, borderaxespad=0.)
        i= i+1

    DNAME="buf_len"    
    plotAX1 = plt.subplot(515)
    plt.title(DNAME)
    i=0
    try:
        plt.plot(zipj(data_srv_arr[0], "ts"), zipj(data_srv_arr[0], 'buf_len'), "-")
        plt.plot(zipj(data_srv_arr[0], "ts"), numpy.array(zipj(data_srv_arr[0], 'a_r_f'))*20, ".", label="ag ready flag" )
    except IndexError:
        pass
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


# NOT FINISHED
def zip_sum(ll_json, name):
    # create main grid
    # get minimal ts,maximum ts from all jsons
    # TODO: finish this!:
    ts_start = ll_json[0][0]["ts"]
    ts_end = ll_json[0][-1]["ts"]
    # generate even grid
    mgrid = np.mgrid[1:0.9:201j]
    
    # now interpolate to grid for each json
    for ld in ll_json[1:]:
        l_data = zipj(ld, name)
        l_ts = zipj(ld, "ts")
        for d in ld:
            z2 = scipy.interpolate.griddata((x.ravel(), y.ravel()), z.ravel(), (x2, y2), method='linear')

def tohex(r,g,b):
	hexchars = "0123456789ABCDEF"
	r = int(r * 255)
	g = int(g * 255)
	b = int(b * 255)
	return "#" + hexchars[r / 16] + hexchars[r % 16] + hexchars[g / 16] + hexchars[g % 16] + hexchars[b / 16] + hexchars[b % 16]


if __name__ == '__main__':
    main()
