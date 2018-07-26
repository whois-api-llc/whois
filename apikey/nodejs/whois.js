var crypto = require('crypto');
var https = require('https');
var queryString = require('querystring');

var username = 'Your whois api username';
var apiKey = 'Your whois api key';
var secretKey = 'Your whois api secret key';

var url = 'https://whoisxmlapi.com/whoisserver/WhoisService';

var domains = [
    'google.com',
    'example.com',
    'whoisxmlapi.com',
    'twitter.com'
];

for(var i in domains) {
    getWhois(username, apiKey, secretKey, domains[i]);
}

function getWhois(username, apiKey, secretKey, domain)
{
    var timestamp = (new Date).getTime();

    var digest = generateDigest(username, timestamp, apiKey, secretKey);

    var requestString = buildRequest(username, timestamp, digest, domain);

    https.get(url + '?' + requestString, function (res) {
        var statusCode = res.statusCode;

        if (statusCode !== 200) {
            console.log('Request failed: ' + statusCode);
        }

        var rawData = '';

        res.on('data', function(chunk) {
            rawData += chunk;
        });

        res.on('end', function () {
            printResponse(rawData);
        })
    }).on('error', function(e) {
        console.log('Error: ' + e.message);
    });
}

function generateDigest(username, timestamp, apiKey, secretKey) {
    var data = username + timestamp + apiKey;
    var hmac = crypto.createHmac('md5', secretKey);

    hmac.update(data);

    return hmac.digest('hex');
}

function buildRequest(username, timestamp, digest, domain) {
    var data = {
        u: username,
        t: timestamp
    };

    var dataJson = JSON.stringify(data);
    var dataBase64 = Buffer.from(dataJson).toString('base64');

    var request = {
        requestObject: dataBase64,
        digest: digest,
        domainName: domain,
        outputFormat: 'json'
    };

    return queryString.stringify(request);
}

function printResponse(responseRaw) {
    var response = JSON.parse(responseRaw);

    if (response.WhoisRecord) {
        var output = 'Contact email: ';
        output += response.WhoisRecord.contactEmail;
        output += "\n";
        output += 'Created date: ';
        output += response.WhoisRecord.createdDate;
        output += "\n";
        output += 'Expires date: ';
        output += response.WhoisRecord.expiresDate;
        output += "\n-------------------------";
        console.log(output);
    } else {
        console.log(response);
    }
}