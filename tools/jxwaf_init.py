import json
import sys
import getopt
import os
import urllib
import urllib2
import socket


def usage():
    print """usage:
python jxwaf_init.py --waf_auth=a2dde899-96a7-40s2-88ba-31f1f75f1552 --waf_server=http://192.168.1.1
"""


file_path = "/opt/jxwaf/nginx/conf/jxwaf/jxwaf_config.json"


def main(argv):
    try:
        opts, args = getopt.getopt(sys.argv[1:], 'h', ['help', 'waf_auth=', 'waf_server='])
    except getopt.GetoptError:
        usage()
        sys.exit()
    if os.path.exists(file_path) == False:
        print "Error: /opt/jxwaf/nginx/conf/jxwaf/jxwaf_config.json is not exist"
        sys.exit()
    for opt, arg in opts:
        if opt in ['-h', '--help']:
            usage()
            sys.exit()
        elif opt in ['--waf_auth']:
            waf_auth = arg
            f = open(file_path, 'r')
            json_data = json.loads(f.read())
            json_data['waf_auth'] = waf_auth
            f.close()
            ff = open(file_path, 'w')
            ff.write(json.dumps(json_data))
            ff.close()
        elif opt in ['--waf_server']:
            waf_server = arg
            if str(waf_server)[-1] == "/":
                print "Error: waf_server is contain uri path "
                sys.exit()
            waf_server_update = waf_server + "/waf_update"
            waf_server_monitor = waf_server + "/waf_monitor"
            waf_name_list_item_update_website = waf_server + "/waf_name_list_item_update"
            f = open(file_path, 'r')
            json_data = json.loads(f.read())
            json_data['waf_update_website'] = waf_server_update
            json_data['waf_monitor_website'] = waf_server_monitor
            json_data['waf_name_list_item_update_website'] = waf_name_list_item_update_website
            json_data['waf_node_hostname'] = socket.gethostname()
            f.close()
            ff = open(file_path, 'w')
            ff.write(json.dumps(json_data))
            ff.close()
        else:
            print "Error: invalid parameters"
            usage()
            sys.exit()
    f = open(file_path, 'r')
    json_data = json.loads(f.read())
    result_waf_auth = json_data['waf_auth']
    waf_update_website = json_data['waf_update_website']
    waf_monitor_website = json_data['waf_monitor_website']
    waf_name_list_item_update_website = json_data['waf_name_list_item_update_website']
    f.close()
    print "config file:  " + file_path
    print "config result:"
    print "waf_auth is %s" % (result_waf_auth)
    print "waf_update_website is %s " % (waf_update_website)
    print "waf_monitor_website is %s " % (waf_monitor_website)
    print "waf_name_list_item_update_website is %s " % (waf_name_list_item_update_website)
    # print  json.dumps(json_data)
    data = {"waf_auth": result_waf_auth}
    headers = {"Content-Type": "application/json"}
    request = urllib2.Request(waf_update_website, data=json.dumps(data), headers=headers)
    try:
        response = urllib2.urlopen(request, timeout=5)
        req_result = json.loads(response.read())['result']
    except urllib2.HTTPError as e:
        print e.read()
        sys.exit()
    except urllib2.URLError as e:
        print e.reason
        sys.exit()
    print "auth result:"
    print("try to connect jxwaf_server auth waf_auth,result is " + str(req_result))
    if req_result == False:
        print "error message:"
        print response.read()


if __name__ == '__main__':
    if len(sys.argv) == 1:
        usage()
        sys.exit()
    main(sys.argv)
