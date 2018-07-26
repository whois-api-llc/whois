$url = 'https://www.whoisxmlapi.com/whoisserver/WhoisService'

$username = 'your whois api username'
$key = 'your whois api key'
$secret = 'your whois api secret key'

$domain = 'example.com'

$time = [DateTimeOffset]::Now.ToUnixTimeMilliseconds()

$json = @{
    t = $time
    u = $username
} | ConvertTo-Json

$req = [Text.Encoding]::UTF8.GetBytes($json)
$req = [Convert]::ToBase64String($req)

$data = $username + $time + $key

$hmac = New-Object System.Security.Cryptography.HMACMD5
$hmac.key = [Text.Encoding]::UTF8.GetBytes($secret)
$hash = $hmac.ComputeHash([Text.Encoding]::UTF8.GetBytes($data))

$digest = [BitConverter]::ToString($hash).Replace('-', '').ToLower()

$uri = $url `
     + '?requestObject=' + [uri]::EscapeDataString($req) `
     + '&digest=' + [uri]::EscapeDataString($digest) `
     + '&domainName=' + [uri]::EscapeDataString($domain) `
     + '&outputFormat=json'

$response = Invoke-WebRequest -Uri $uri
echo $response.Content | convertfrom-json | convertto-json -depth 10