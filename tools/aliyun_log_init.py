import json
import sys
import getopt
import os

def usage():
    print """usage:
python aliyun_log_init.py --access_id=LTAIE0dgXu7OJadW --access_secret=8uQjQP8mtRAHAiQWGNZFs9dsaqweff
"""
file_path = "/opt/jxwaf/nginx/conf/jxwaf/jxwaf_config.json"
 
def main(argv):
    try:
        opts, args = getopt.getopt(sys.argv[1:], 'h', ['help','access_id=','access_secret='])
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
        elif opt in ['--access_id']:
            access_id = arg
            json_data = ""
            f = open(file_path,'r')
            json_data = json.loads(f.read())
            json_data['aliyun_access_id'] = access_id
            f.close()
            ff = open(file_path,'w')
            ff.write(json.dumps(json_data))
            ff.close()
        elif opt in ['--access_secret']:
            access_secret = arg
            json_data = ""
            f = open(file_path,'r')
            json_data = json.loads(f.read())
            json_data['aliyun_access_secret'] = access_secret
            f.close()
            ff = open(file_path,'w')
            ff.write(json.dumps(json_data))
            ff.close()
        else:
            print "Error: invalid parameters"
            usage()
            sys.exit()
    f = open(file_path,'r')
    json_data = json.loads(f.read())
    result_access_id = json_data['aliyun_access_id']
    result_access_secret = json_data['aliyun_access_secret']
    f.close()
    print "config file:  "+file_path
    print "result:"
    print "init success,access_id is %s,access_secret is %s "%(result_access_id,result_access_secret)
    #print  json.dumps(json_data)

if __name__ == '__main__':
    if len(sys.argv) == 1:
        usage()
        sys.exit()
    main(sys.argv)