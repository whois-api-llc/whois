﻿using System;
using System.Collections.Generic;
using System.IO;
using System.Net;
using System.Security.Cryptography;
using System.Text;

using Newtonsoft.Json;

/*
 * Target platform: .Net Framework 4.0
 * 
 * You need to install Newtonsoft JSON.NET
 *
 */

namespace WhoisApi
{
    internal static class WhoisApiKeyAuthSample
    {
        private static void Main()
        {
            const string username = "Your whois api username";
            const string apiKey = "Your whois api key";
            const string secretKey = "Your whois api secret key";
            
            string[] domains =
            {
                "google.com",
                "example.com",
                "whoisxmlapi.com",
                "twitter.com"
            };
            
            const string url =
                "https://whoisxmlapi.com/whoisserver/WhoisService";

            ApiSample.PerformRequest(username, apiKey, secretKey,url,domains);
        }
    }
    
    public static class ApiSample
    {

        public static void PerformRequest(
            string username,
            string apiKey,
            string secretKey,
            string url,
            IEnumerable<string> domains
        )
        {
            var timestamp = GetTimeStamp();
            var digest = GenerateDigest(username,apiKey,secretKey,timestamp);

            foreach (var domain in domains)
            {
                try
                {
                    var request = BuildRequest(
                                    username, timestamp, digest, domain);

                    var response = GetWhoisData(url + request);

                    if (response.Contains("Request timeout"))
                    {
                        timestamp = GetTimeStamp();
                        
                        digest = GenerateDigest(
                                    username, apiKey, secretKey, timestamp);
                        
                        request = BuildRequest(
                                    username, timestamp, digest, domain);
                        
                        response = GetWhoisData(url + request);
                    }
                    
                    PrintResponse(response);
                }
                catch (Exception)
                {
                    Console.WriteLine(
                        "Error occurred\r\nCannot get whois data for "
                        + domain
                    );
                }
            }
            
            Console.ReadLine();
        }

        private static string GenerateDigest(
            string username,
            string apiKey,
            string secretKey,
            long timestamp
        )
        {
            var data = username + timestamp + apiKey;
            var hmac = new HMACMD5(Encoding.UTF8.GetBytes(secretKey));
            
            var hex = BitConverter.ToString(
                        hmac.ComputeHash(Encoding.UTF8.GetBytes(data)));
            
            return hex.Replace("-", "").ToLower();
        }

        private static string BuildRequest(
            string username,
            long timestamp,
            string digest,
            string domain
        )
        {
            var ud = new UserData
            {
                u = username,
                t = timestamp
            };
            
            var userData = JsonConvert.SerializeObject(ud, Formatting.None);
            var userDataBytes = Encoding.UTF8.GetBytes(userData);
            var userDataBase64 = Convert.ToBase64String(userDataBytes);

            var requestString = new StringBuilder();

            requestString.Append("?requestObject=");
            requestString.Append(Uri.EscapeDataString(userDataBase64));
            requestString.Append("&digest=");
            requestString.Append(Uri.EscapeDataString(digest));
            requestString.Append("&domainName=");
            requestString.Append(Uri.EscapeDataString(domain));
            requestString.Append("&outputFormat=json");

            return requestString.ToString();
        }

        private static string GetWhoisData(string url)
        {
            var response = "";
            
            try
            {
                var wr = WebRequest.Create(url);
                var wp = wr.GetResponse();

                using (var data = wp.GetResponseStream())
                {
                    if (data == null)
                        return response;
                    
                    using (var reader = new StreamReader(data))
                    {
                        response = reader.ReadToEnd();
                    }
                }
                
                wp.Close();
            }
            catch (Exception e)
            {
                Console.WriteLine(e.Message);
                throw new Exception(e.Message);
            }
            
            return response;
        }

        private static void PrintResponse(string response)
        {
            dynamic responseObject = JsonConvert.DeserializeObject(response);

            if (responseObject.WhoisRecord != null)
            {
                var whois = responseObject.WhoisRecord;
                
                if (whois.createdDate != null)
                {
                    Console.WriteLine(
                        "Created date: " + whois.createdDate.ToString());
                }
                
                if (whois.expiresDate != null)
                {
                    Console.WriteLine(
                        "Expires date: " + whois.expiresDate.ToString());
                }
                
                if (whois.domainName != null)
                {
                    Console.WriteLine(
                        "Domain name: " + whois.domainName.ToString());
                }
                
                Console.WriteLine("--------------------------------");
                return;
            }

            Console.WriteLine(response);
        }

        private static long GetTimeStamp()
        {
            return (long)(DateTime.UtcNow.Subtract(new DateTime(1970, 1, 1))
                                         .TotalMilliseconds);
        }
    }

    internal class UserData
    {
        public string u { get; set; }
        public long t { get; set; }
    }
}