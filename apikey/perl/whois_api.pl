#!/usr/bin/perl

use Digest::HMAC_MD5 qw( hmac_md5_hex );    # From CPAN
use JSON qw( decode_json encode_json );     # From CPAN
use LWP::Protocol::https;                   # From CPAN
use LWP::Simple;                            # From CPAN
use MIME::Base64 qw( encode_base64 );
use Time::HiRes qw( time );                 # From CPAN
use URI::Escape qw( uri_escape );           # From CPAN

use strict;
use warnings;

my @domains = (
    'google.com',
    'example.com',
    'whoisxmlapi.com',
    'twitter.com'
);

my $username = 'Your whois api username';
my $apiKey = 'Your whois api key';
my $secret = 'Your whois api secret key';

my $url = 'https://whoisxmlapi.com/whoisserver/WhoisService';

my $timestamp = int((time * 1000 + 0.5));
my $digest = generateDigest($username, $timestamp, $apiKey, $secret);

foreach my $domain (@domains){
    my $requestString = buildRequest(
        $username,
        $timestamp,
        $digest,
        $domain
    );

    my $response = get($url . $requestString);

    if (index($response, 'Request timeout')){
        $timestamp = int((time * 1000 + 0.5));
        $digest = generateDigest($username, $timestamp, $apiKey, $secret);

        $requestString = buildRequest(
            $username,
            $timestamp,
            $digest,
            $domain
        );

        $response = get($url . $requestString);
    }

    printResponse($response);
    print "---------------------------------------\n";
}

sub generateDigest{
    my ($req_username, $req_timestamp, $req_apiKey, $req_secret) = @_;

    my $res_digest = $req_username . $req_timestamp . $req_apiKey;
    my $hash = hmac_md5_hex($res_digest, $req_secret);

    return uri_escape($hash);
}

sub buildRequest{
    my ($req_username, $req_timestamp, $req_digest, $req_domain) = @_;
    my $requestString = '?requestObject=';

    my %request =(
        'u' => $req_username,
        't' => $req_timestamp
    );

    my $requestJson = encode_json(\%request);
    my $requestBase64 = encode_base64($requestJson);

    $requestString .= uri_escape($requestBase64)
                   .  '&digest=' . $req_digest
                   . '&domainName=' . uri_escape($req_domain)
                   . '&outputFormat=json';

    return $requestString;
}

sub printResponse{
    my ($response) = @_;
    my $responseObject = decode_json($response);

    if (exists $responseObject->{'WhoisRecord'}->{'createdDate'}){
        print 'Created date: ',
              $responseObject->{'WhoisRecord'}->{'createdDate'},
              "\n";
    }

    if (exists $responseObject->{'WhoisRecord'}->{'expiresDate'}){
        print 'Expires date: ',
              $responseObject->{'WhoisRecord'}->{'expiresDate'},
              "\n";
    }

    if (exists $responseObject->{'WhoisRecord'}->{'contactEmail'}){
        print 'Contact email: ',
              $responseObject->{'WhoisRecord'}->{'contactEmail'},
              "\n";
    }
}