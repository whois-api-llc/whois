#!/usr/bin/perl

use Data::Dumper;

use JSON qw( decode_json );       # From CPAN
use LWP::Protocol::https;         # From CPAN
use LWP::Simple;                  # From CPAN
use URI::Escape qw( uri_escape ); # From CPAN

use strict;
use warnings;

my $base_url = 'https://www.whoisxmlapi.com/whoisserver/WhoisService';
my $domain_name = 'google.com';
my $format = 'json';
my $user_name = 'Your whois api username';
my $password = 'Your whois api password';

# 'get' is exported by LWP::Simple;
my $url = $base_url
        . '?domainName=' . uri_escape($domain_name)
        . '&outputFormat=' . uri_escape($format)
        . '&userName=' . uri_escape($user_name)
        . '&password=' . uri_escape($password);

print "Get data by URL: $url\n";
my $json = get($url);
die "Could not get $base_url!" unless defined $json;

# Decode the entire JSON
my $decoded_json = decode_json($json);

# Dump all data if need
#print Dumper $decoded_json;

# Print fetched attribute
print 'Domain Name: ', $decoded_json->{'WhoisRecord'}->{'domainName'}, "\n";
print 'Contact Email: ',$decoded_json->{'WhoisRecord'}->{'contactEmail'},"\n";