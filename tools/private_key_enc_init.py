import json
import sys
import getopt
import os
import requests

def usage():
    print """usage:
python private_key_enc_init.py --aes_enc_key=9d19112c4d6df749 --aes_enc_iv=6d095e23c863e616
"""
file_path = "/opt/jxwaf/nginx/conf/jxwaf/jxwaf_config.json"

def main(argv):
    try:
        opts, args = getopt.getopt(sys.argv[1:], 'h', ['help','aes_enc_key=','aes_enc_iv='])
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
        elif opt in ['--aes_enc_key']:
            aes_enc_key = arg
            if len(aes_enc_key) != 16:
                print "Error: invalid parameters"
                print "aes_enc_key length must 16"
                sys.exit()
            json_data = ""
            f = open(file_path,'r')
            json_data = json.loads(f.read())
            json_data['aes_enc_key'] = aes_enc_key
            f.close()
            ff = open(file_path,'w')
            ff.write(json.dumps(json_data))
            ff.close()
        elif opt in ['--aes_enc_iv']:
            aes_enc_iv = arg
            if len(aes_enc_iv) != 16:
                print "Error: invalid parameters"
                print "aes_enc_iv length must 16"
                sys.exit()
            json_data = ""
            f = open(file_path,'r')
            json_data = json.loads(f.read())
            json_data['aes_enc_iv'] = aes_enc_iv
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
    result_aes_enc_key = json_data['aes_enc_key']
    result_aes_enc_iv = json_data['aes_enc_iv']
    waf_update_website = json_data['waf_update_website']
    f.close()
    print "config file:  "+file_path
    print "config result:"
    print "init success,aes_enc_key is %s,aes_enc_iv is %s "%(result_aes_enc_key,result_aes_enc_iv)
            
if __name__ == '__main__':
    if len(sys.argv) == 1:
        usage()
        sys.exit()
    main(sys.argv)