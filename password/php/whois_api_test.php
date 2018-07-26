<?php

$username = 'Your whois api username';
$password = 'Your whois api password';
$domain = 'whoisxmlapi.com';

$url = 'https://www.whoisxmlapi.com//whoisserver/WhoisService';

$apiUrl = $url
        . '?domainName=' . urlencode($domain)
        . '&username=' . urlencode($username)
        . '&password=' . urlencode($password)
        . '&outputFormat=JSON';

$contents = file_get_contents($apiUrl);

$res = json_decode($contents);

if (empty($res)) {
    return;
}

if (! empty($res->ErrorMessage)) {
    echo $res->ErrorMessage->msg;
}

else {
    $whoisRecord = $res->WhoisRecord ?: new stdClass();

    if (empty($whoisRecord)) {
        return;
    }

    echo 'Domain name: '
         . print_r($whoisRecord->domainName, 1)
         . PHP_EOL;

    echo 'Created date: '
         . print_r($whoisRecord->createdDate, 1)
         . PHP_EOL;

    echo 'Updated date: '
         . print_r($whoisRecord->updatedDate, 1)
         . PHP_EOL;

    if ($whoisRecord->registrant)
        echo 'Registrant: '
             . print_r($whoisRecord->registrant->rawText, 1)
             . PHP_EOL;
}