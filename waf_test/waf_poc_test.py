# -*- coding: utf-8 -*-
from __future__ import print_function

try:
    import urllib.request as urllib2
    import urllib.parse as urllib
except ImportError:
    import urllib2
    import urllib

import optparse


def bypass_waf(url, payload, test_type='query_string'):
    encoded_payload = ''
    headers = {}

    if test_type == 'query_string':
        encoded_payload = urllib.quote(payload)
        full_url = url + '?' + encoded_payload
        request = urllib2.Request(full_url)
    elif test_type == 'body':
        headers = {'Content-Type': 'application/x-www-form-urlencoded'}
        data = urllib.urlencode({'data': payload})
        request = urllib2.Request(url, data=data.encode('utf-8'), headers=headers)
    elif test_type == 'header':
        headers = {'User-Agent': payload}
        request = urllib2.Request(url, headers=headers)

    try:
        response = urllib2.urlopen(request)
        if response.getcode() == 403:
            print('[-] WAF successfully blocked {0} payload: {1}'.format(test_type, payload))
            return 'blocked'
        else:
            print('[+] Possible bypass with {0} payload: {1}, received status code: {2}'.format(test_type, payload,
                                                                                                response.getcode()))
            return 'bypassed'
    except urllib2.HTTPError as e:
        if e.code == 403:
            print('[-] WAF successfully blocked {0} payload: {1}'.format(test_type, payload))
            return 'blocked'
        else:
            print('[-] Failed to bypass WAF with {0} payload: {1}, received status code: {2}'.format(test_type, payload,
                                                                                                     e.code))
            return 'failed'
    except urllib2.URLError as e:
        print('[-] Failed to bypass WAF with {0} payload: {1}'.format(test_type, payload))
        print('    Reason: {0}'.format(e.reason))
        return 'failed'


def read_poc_file(file_path):
    try:
        with open(file_path, 'r') as file:
            poc_list = file.readlines()
        return [poc.strip() for poc in poc_list if poc.strip() and not poc.startswith('#')]
    except IOError:
        print('[-] File {0} not found.'.format(file_path))
        return []



parser = optparse.OptionParser()
parser.add_option('-u', '--url', dest='url', help='The URL to test')
(options, args) = parser.parse_args()

if not options.url:
    parser.error('URL is required. -u or --url. demo: python waf_tester.py -u http://127.0.0.1')

waf_test_poc_file = 'test_poc.txt'
test_payloads = read_poc_file(waf_test_poc_file)
bypassed_count = 0
blocked_count = 0

for payload in test_payloads:
    for test_type in ['query_string', 'body', 'header']:
        result = bypass_waf(options.url, payload, test_type)
        if result == 'bypassed':
            bypassed_count += 1
        else:
            blocked_count += 1

total_count = len(test_payloads) * 3
bypassed_ratio = float(bypassed_count) / total_count * 100
blocked_ratio = float(blocked_count) / total_count * 100

print('Total POC count: {0}'.format(total_count))
print('Bypassed count: {0} ({1:.2f}%)'.format(bypassed_count, bypassed_ratio))
print('Blocked count: {0} ({1:.2f}%)'.format(blocked_count, blocked_ratio))
