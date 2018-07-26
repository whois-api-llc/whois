<?php

$username = 'Your whois api username';
$apiKey = 'Your whois api key';
$secret = 'Your whois api secret key';

$url = 'https://whoisxmlapi.com/whoisserver/WhoisService';

$timestamp = null;

$domains = array(
    'google.com',
    'example.com',
    'whoisxmlapi.com',
    'twitter.com',
);

$digest = null;

generate_params($timestamp, $digest, $username, $apiKey, $secret);

foreach ($domains as $domain) {
    $response = request($url, $username, $timestamp, $digest, $domain);

    if (strpos($response, 'Request timeout') !== false) {
        generate_params($timestamp, $digest, $username, $apiKey, $secret);
        $response = request($url, $username, $timestamp, $digest, $domain);
    }

    print_response($response);
    echo '----------------------------' . "\n";
}

function generate_params(&$timestamp, &$digest, $username, $apiKey, $secret)
{
    $timestamp = round(microtime(true) * 1000);
    $digest = generate_digest($username, $timestamp, $apiKey, $secret);
}

function request($url, $username, $timestamp, $digest, $domain)
{
    $requestString = build_request($username, $timestamp, $digest, $domain);

    return file_get_contents($url . $requestString);
}

function print_response($response)
{
    $responseArray = json_decode($response, true);

    if (! empty($responseArray['WhoisRecord']['createdDate'])) {
        echo 'Created Date: '
             . $responseArray['WhoisRecord']['createdDate']
             . PHP_EOL;
    }

    if (! empty($responseArray['WhoisRecord']['expiresDate'])) {
        echo 'Expires Date: '
             . $responseArray['WhoisRecord']['expiresDate']
             . PHP_EOL;
    }

    if (! empty($responseArray['WhoisRecord']['registrant']['rawText'])) {
        echo $responseArray['WhoisRecord']['registrant']['rawText'] . PHP_EOL;
    }
}

function generate_digest($username, $timestamp, $apiKey, $secretKey)
{
    $digest = $username . $timestamp . $apiKey;
    $hash = hash_hmac('md5', $digest, $secretKey);

    return urlencode($hash);
}

function build_request($username, $timestamp, $digest, $domain)
{
    $request = array(
        'u' => $username,
        't' => $timestamp
    );

    $requestJson = json_encode($request);
    $requestBase64 = base64_encode($requestJson);

    $requestString = '?requestObject=' . urlencode($requestBase64)
                   . '&digest=' . $digest
                   . '&domainName=' . urlencode($domain)
                   . '&outputFormat=json';

    return $requestString;
}