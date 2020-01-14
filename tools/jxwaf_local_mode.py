import json
import sys
import getopt
import os
import requests
import shutil
import time

def usage():
    print """usage:
python jxwaf_local_mode.py --init 
python jxwaf_local_mode.py --update 
python jxwaf_local_mode.py --cancel
"""
file_path = "/opt/jxwaf/nginx/conf/jxwaf/jxwaf_config.json"
local_config_path = "/opt/jxwaf/nginx/conf/jxwaf/jxwaf_local_config.json"

def main(argv):
    try:
        opts, args = getopt.getopt(sys.argv[1:], 'h', ['help','init','update','cancel'])
    except getopt.GetoptError:
        usage()
        sys.exit()
    if os.path.exists(file_path)==False:
        print "Error: /opt/jxwaf/nginx/conf/jxwaf/jxwaf_config.json is not exist"
        sys.exit()
    for opt, arg in opts:
        if opt in ['-h', '--help']:
            usage()
            sys.exit()
        elif opt in ['--init']:
            json_data = ""
            f = open(file_path,'r')
            json_data = json.loads(f.read())
            json_data['waf_local'] = "true"
            f.close()
            ff = open(file_path,'w')
            ff.write(json.dumps(json_data))
            ff.close()
            f = open(file_path,'r')
            json_data = json.loads(f.read())
            f.close()
            print "config file:  "+file_path
            print "config result:"
            print "waf_local  is %s "%(json_data['waf_local'])
            sys.exit()
        elif opt in ['--cancel']:
            json_data = ""
            f = open(file_path,'r')
            json_data = json.loads(f.read())
            json_data['waf_local'] = "false"
            f.close()
            ff = open(file_path,'w')
            ff.write(json.dumps(json_data))
            ff.close()
            f = open(file_path,'r')
            json_data = json.loads(f.read())
            f.close()
            print "config file:  "+file_path
            print "config result:"
            print "waf_local  is %s "%(json_data['waf_local'])
            sys.exit()
        elif opt in ['--update']:
            json_data = ""
            f = open(file_path,'r')
            json_data = json.loads(f.read())
            result_api_key = json_data['waf_api_key']
            result_api_password = json_data['waf_api_password']
            waf_update_website = json_data['waf_update_website']
            f.close()
            data = {"md5":"","api_key":result_api_key,"api_password":result_api_password}
            response = requests.post(waf_update_website, data=data)
            req_result = response.text
            if os.path.exists(local_config_path)==True:
                back_file = '/opt/jxwaf/nginx/conf/jxwaf/jxwaf_local_config.json.'+time.strftime("%Y-%m-%d-%H-%M-%S", time.localtime())
                shutil.move(local_config_path,back_file)
                print "backup file path: " + back_file
            ff = open(local_config_path,'w')
            ff.write(req_result)
            ff.close()
            print "config file path:  "+local_config_path
            print "update success!"
            sys.exit()
        else:
            print "Error: invalid parameters"
            usage()
            sys.exit()
    
if __name__ == '__main__':
    if len(sys.argv) == 1:
        usage()
        sys.exit()
    main(sys.argv)