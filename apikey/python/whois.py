try:
    # For Python v.3 and later
    from urllib.parse import quote
    from urllib.request import urlopen, pathname2url
except ImportError:
    # For Python v.2
    from urllib import pathname2url
    from urllib2 import urlopen, quote

import base64
import hashlib
import hmac
import json
import time

username = 'Your whois api username'
api_key = 'Your whois api key'
secret = 'Your whois api secret key'

domains = [
    'google.com',
    'example.com',
    'whoisxmlapi.com',
    'twitter.com'
]

url = 'https://whoisxmlapi.com/whoisserver/WhoisService'


def build_request(req_username, req_timestamp, req_digest, req_domain):

    data = {
        'u': req_username,
        't': req_timestamp
    }

    json_data = json.dumps(data)
    js_64 = base64.b64encode(bytearray(json_data.encode('utf-8')))

    return '?requestObject=' + pathname2url(js_64.decode('utf-8')) \
           + '&digest=' + pathname2url(req_digest) \
           + '&domainName=' + pathname2url(req_domain) \
           + '&outputFormat=json'


def generate_digest(req_username, req_timestamp, req_key, req_secret):

    res_digest = req_username + str(req_timestamp) + req_key

    res_hash = hmac.new(bytearray(req_secret.encode('utf-8')),
                        bytearray(res_digest.encode('utf-8')),
                        hashlib.md5)

    return quote(str(res_hash.hexdigest()))


def generate_params(req_username, req_key, req_secret):

    res_timestamp = int(round(time.time() * 1000))
    res_digest = generate_digest(req_username, res_timestamp,
                                 req_key, req_secret)

    return res_timestamp, res_digest


def print_response(req_response):

    response_json = json.loads(req_response)

    if 'WhoisRecord' in response_json:
        if 'contactEmail' in response_json['WhoisRecord']:
            print('Contact Email: ')
            print(response_json['WhoisRecord']['contactEmail'])

        if 'createdDate' in response_json['WhoisRecord']:
            print('Created date: ')
            print(response_json['WhoisRecord']['createdDate'])

        if 'expiresDate' in response_json['WhoisRecord']:
            print('Expires date: ')
            print(response_json['WhoisRecord']['expiresDate'])


def request(req_url, req_username, req_timestamp, req_digest, req_domain):
    req = build_request(req_username, req_timestamp, req_digest, req_domain)

    return urlopen(req_url + req).read().decode('utf8')


timestamp, digest = generate_params(username, api_key, secret)

for domain in domains:

    response = request(url, username, timestamp, digest, domain)

    if 'Request timeout' in response:
        timestamp, digest = generate_params(username, api_key, secret)
        response = request(url, username, timestamp, digest, domain)

    print_response(response)
    print('---------------------------\n')
