import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.net.URLEncoder;
import java.util.logging.Level;
import java.util.logging.Logger;

import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;

import org.apache.commons.codec.binary.Base64;
import org.apache.commons.codec.binary.Hex;
import org.apache.commons.httpclient.HttpClient;
import org.apache.commons.httpclient.HttpMethod;
import org.apache.commons.httpclient.methods.GetMethod;

import org.json.JSONException;
import org.json.JSONObject;

public class WhoisApiKeySample
{
    private Logger logger=Logger.getLogger(WhoisApiKeySample.class.getName());

    public static void main(String[]args)
    {
        new WhoisApiKeySample().getSimpleDomainUsingApiKey();
    }

    private void getSimpleDomainUsingApiKey()
    {
        String domainName = "test.com";

        String username = "Your whois api username";
        String apiKey = "Your whois api key";
        String secretKey = "Your whois api secret key";

        getDomainNameUsingApiKey(domainName, username, apiKey, secretKey);
    }

    private String executeURL(String url)
    {
        HttpClient c = new HttpClient();

        System.out.println(url);

        HttpMethod m = new GetMethod(url);
        String res = null;

        try {
            c.executeMethod(m);

            BufferedReader reader =
                    new BufferedReader(
                          new InputStreamReader(m.getResponseBodyAsStream()));

            StringBuilder stringBuffer = new StringBuilder();
            String str;

            while((str = reader.readLine())!=null){
                stringBuffer.append(str);
                stringBuffer.append("\n");
            }

            res = stringBuffer.toString();
        } catch (Exception e) {
            logger.log(Level.SEVERE, "Cannot get url", e);
        } finally {
            m.releaseConnection();
        }
        return res;
    }

    public void getDomainNameUsingApiKey(
        String domainName,
        String username,
        String apiKey,
        String secretKey
    )
    {
        String apiKeyAuthenticationRequest =
            generateApiKeyAuthRequest(username, apiKey, secretKey);

        if (apiKeyAuthenticationRequest == null) {
            return;
        }

        StringBuilder sb = new StringBuilder();
        sb.append("https://www.whoisxmlapi.com/whoisserver/WhoisService?");
        sb.append(apiKeyAuthenticationRequest);
        sb.append("&domainName=");
        try {
            sb.append(URLEncoder.encode(domainName, "UTF-8"));
        }
        catch (Exception e) {
            logger.log(Level.SEVERE, "an error occurred", e);
        }

        String url = sb.toString();

        String result = executeURL(url);
        if (result != null) {
            logger.log(Level.INFO, "result: " + result);
        }
    }

    private String generateApiKeyAuthRequest(
        String username,
        String apiKey,
        String secretKey
    )
    {
        try {
            long timestamp = System.currentTimeMillis();

            String request = generateRequest(username, timestamp);

            String digest =
                generateDigest(username, apiKey, secretKey, timestamp);

            String requestURL = URLEncoder.encode(request, "UTF-8");
            String digestURL = URLEncoder.encode(digest, "UTF-8");

            return "requestObject=" + requestURL
                   + "&digest=" + digestURL;
        } catch (Exception e) {
            logger.log(Level.SEVERE, "an error occurred", e);
        }
        return null;
    }

    private String generateRequest(String username, long timestamp)
        throws JSONException
    {
        JSONObject json = new JSONObject();

        json.put("u", username);
        json.put("t", timestamp);

        String jsonStr = json.toString();
        byte[] json64 = Base64.encodeBase64(jsonStr.getBytes());

        return new String(json64);
    }

    private String generateDigest(
        String username,
        String apiKey,
        String secretKey,
        long timestamp
    )
        throws Exception
    {
        String sb = username + timestamp + apiKey;

        SecretKeySpec secretKeySpec =
            new SecretKeySpec(secretKey.getBytes("UTF-8"), "HmacMD5");

        Mac mac = Mac.getInstance(secretKeySpec.getAlgorithm());
        mac.init(secretKeySpec);

        byte[] digestBytes = mac.doFinal(sb.getBytes("UTF-8"));

        return new String(Hex.encodeHex(digestBytes));
    }
}