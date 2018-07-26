$url = 'https://www.whoisxmlapi.com/whoisserver/WhoisService'

$username = 'Your whois api username'
$password = 'Your whois api password'
$domain = 'whoisxmlapi.com'

$uri = $url `
     + '?domainName=' + [uri]::EscapeDataString($domain) `
     + '&username=' + [uri]::EscapeDataString($username) `
     + '&password=' + [uri]::EscapeDataString($password) `
     + '&outputFormat=json'

#########################
# Use the JSON resource #
#########################

$j = Invoke-WebRequest -Uri $uri -UseBasicParsing | ConvertFrom-Json

if ([bool]($j.PSObject.Properties.name -match 'WhoisRecord')) {
    echo "Domain Name: $($j.WhoisRecord.domainName)"
    echo "Contact Email: $($j.WhoisRecord.contactEmail)"
} else {
    echo $j
}