from Crypto.Cipher import AES
import base64
import json
import sys
import getopt
import os
from pkcs7 import PKCS7Encoder

encoder = PKCS7Encoder()


def encrypt(plaintext, key, iv):
    global encoder
    aes = AES.new(key.encode('utf-8'), AES.MODE_CBC,iv.encode('utf-8') )
    pad_text = encoder.encode(plaintext)
    return base64.b64encode(aes.encrypt(pad_text))
 
def usage():
    print """usage:
python private_key_enc.py -p  private.key 
or
python private_key_enc.py -p  /opt/jxwaf/nginx/conf/private.key
"""
 
def main(argv):
    try:
        opts, args = getopt.getopt(sys.argv[1:], 'p:h', ['path', 'help'])
    except getopt.GetoptError:
        usage()
        sys.exit()
     
    for opt, arg in opts:
        if opt in ['-h', '--help']:
            usage()
            sys.exit()
        elif opt in ['-p', '--path']:
            path = arg
            if os.path.exists(path)==False:
                print "Error: file is not exist"
                sys.exit()
            with open('/opt/jxwaf/nginx/conf/jxwaf/jxwaf_config.json', 'r') as f:
                json_data = json.loads(f.read())
                aes_enc_key = json_data['aes_enc_key']
                aes_enc_iv = json_data['aes_enc_iv']
            with open(path, 'r') as f:
                data = f.read()
                result = encrypt(data,aes_enc_key,aes_enc_iv)
                print "aes_enc_key is %s"%(aes_enc_key)
                print "aes_enc_iv is %s"%(aes_enc_iv)
                print "private key is "
                print(result)
                sys.exit()
        else:
            print "Error: invalid parameters"
            usage()
            sys.exit()
    print "Error: invalid parameters"
    usage()
    sys.exit()

if __name__ == '__main__':
    if len(sys.argv) == 1:
        usage()
        sys.exit()
    main(sys.argv)