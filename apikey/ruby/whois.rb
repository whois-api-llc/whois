require 'base64'
require 'erb'
require 'json'
require 'net/https'
require 'openssl'
require 'uri'
require 'yaml'

domains = %w[
  google.com
  example.com
  whoisxmlapi.com
  twitter.com
]

url = 'https://whoisxmlapi.com/whoisserver/WhoisService'

username = 'Your whois api username'
api_key = 'Your whois api key'
secret = 'Your whois api secret key'

def generate_digest(username, timestamp, api_key, secret)
  digest = username + timestamp.to_s + api_key
  OpenSSL::HMAC.hexdigest(OpenSSL::Digest::MD5.new, secret, digest)
end

def build_request(username, timestamp, digest, domain)
  data = {
    u: username,
    t: timestamp
  }

  '?requestObject=' + ERB::Util.url_encode(Base64.encode64(data.to_json)) +
    '&digest=' + ERB::Util.url_encode(digest) +
    '&domainName=' + ERB::Util.url_encode(domain) +
    '&outputFormat=json'
end

def print_response(response)
  hash = JSON.parse(response).fetch('WhoisRecord', {})

  puts 'Contact Email: ' + hash.fetch('contactEmail', '')
  puts 'Created Date: ' + hash.fetch('createdDate', '')
  puts 'Expiry Date: ' + hash.fetch('expiresDate', '')
end

timestamp = (Time.now.to_f * 1000).to_i
digest = generate_digest(username, timestamp, api_key, secret)

domains.each do |domain|
  request_string = build_request(username, timestamp, digest, domain)
  response = Net::HTTP.get(URI.parse(url + request_string))

  if response.include? 'Request timeout'
    timestamp = (Time.now.to_f * 1000).to_i
    digest = generate_digest(username, timestamp, api_key, secret)
    request_string = build_request(username, timestamp, digest, domain)
    response = Net::HTTP.get(URI.parse(url + request_string))
  end

  print_response(response)
  puts "--------------------------------\n"
end