import json
import sys
import getopt
import os
import requests


def usage():
    print """usage:
python jxwaf_errpr_domain_repair.py --api_key=a2dde899-96a7-40s2-88ba-31f1f75f1552 --api_password=653cbbde-1cac-11ea-978f-2e728ce88125 --waf_server=http://192.168.1.1 --operator=check
or:
python jxwaf_errpr_domain_repair.py --api_key=a2dde899-96a7-40s2-88ba-31f1f75f1552 --api_password=653cbbde-1cac-11ea-978f-2e728ce88125 --waf_server=http://192.168.1.1 --operator=repair
"""


def main(argv):
    api_key = False
    api_password = False
    operator = False
    waf_server = False
    try:
        opts, args = getopt.getopt(sys.argv[1:], 'h', ['help', 'api_key=', 'api_password=', 'waf_server=', 'operator='])
    except getopt.GetoptError:
        usage()
        sys.exit()
    for opt, arg in opts:
        if opt in ['-h', '--help']:
            usage()
            sys.exit()
        elif opt in ['--api_key']:
            api_key = arg
        elif opt in ['--api_password']:
            api_password = arg
        elif opt in ['--operator']:
            operator = arg
        elif opt in ['--waf_server']:
            waf_server = arg
        else:
            print "Error: invalid parameters"
            usage()
            sys.exit()
    if api_key == False or api_password == False or operator == False or waf_server == False:
        usage()
        sys.exit()
    result_api_key = api_key
    result_api_password = api_password
    result_operator = operator
    waf_update_website = waf_server
    print "access_id is %s,access_secret is %s " % (result_api_key, result_api_password)
    print "operator is %s,update_website is %s " % (result_operator, waf_update_website)
    # print  json.dumps(json_data)
    data = {}
    data['api_key'] = result_api_key
    data['api_password'] = result_api_password
    data['operator'] = result_operator
    response = requests.post(str(waf_update_website) + "/waf/waf_update_repair", data=data, timeout=60)
    req_result = response.json()['result']
    print "auth result:"
    print("try to connect jxwaf server auth api_key and api_password,result is " + str(req_result))
    try:
        error_domain = response.json()['error_domain']
        print response.json()['message']
        print error_domain
    except:
        pass
        print response.json()['message']

if __name__ == '__main__':
    if len(sys.argv) == 1:
        usage()
        sys.exit()
    main(sys.argv)
