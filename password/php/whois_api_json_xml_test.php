<?php

//////////////////////////
// Fill in your details //
//////////////////////////
$username = 'Your whois api username';
$password = 'Your whois api password';
$domain = 'google.com';
$format = 'JSON'; // or XML

$url = 'https://www.whoisxmlapi.com/whoisserver/WhoisService';

$apiUrl = $url
        . '?domainName=' . urlencode($domain)
        . '&username=' . urlencode($username)
        . '&password=' . urlencode($password)
        . '&outputFormat=' . urlencode($format);

///////////////////////////
// Use the JSON resource //
///////////////////////////

if ($format == 'JSON') {

    // Get and build the JSON object
    $result = json_decode(file_get_contents($apiUrl));

    // Print out a nice informative string
    print ('JSON: ' . PHP_EOL . recursive_pretty_print($result) . PHP_EOL);
}

//////////////////////////
// Use the XML resource //
//////////////////////////
else {

    // Get and build the XML associative array
    $parser = new XmlToArr();
    $result = array('WhoisRecord' => $parser->parseXML($apiUrl));

    // Print out a nice informative string
    print ('XML: ' . PHP_EOL . recursive_pretty_print($result) . PHP_EOL);
}

// Function to recursively print all properties of an object and their values
function recursive_pretty_print($obj)
{
    $str = '';

    foreach ((array)$obj as $key => $value) {

        // XML parsing leaves a little to be desired as it fills our obj with
        // key/values with just whitespace, ignore that whitespace at the cost
        // of losing hostNames and ips in the final printed result.

        if (!is_string($key))
            continue;

        $str .= $key . ': ';

        if (is_string($value))
            $str .= $value;
        else
            $str .= recursive_pretty_print($value);
    }

    return $str;
}

// Class that simply turns an XML tree into a multilevel associative array
class XmlToArr
{
    private $root;
    private $stack;

    public function __construct()
    {
        $this->root = null;
        $this->stack = array();
    }

    public function characterData($parser, $data)
    {
        $data = trim($data);

        $current = &$this->stack[count($this->stack) - 1];

        if (is_array($current))
            $current[] = $data;
        else
            $current = $data;
    }

    public function endElement($parser, $tagName)
    {
        array_pop($this->stack);
    }

    public function parseXML($feed_url)
    {
        $xml_parser = xml_parser_create();

        xml_parser_set_option($xml_parser, XML_OPTION_CASE_FOLDING, 0);
        xml_parser_set_option($xml_parser, XML_OPTION_SKIP_WHITE, 1);
        xml_set_object($xml_parser, $this);
        xml_set_element_handler($xml_parser, 'startElement', 'endElement');
        xml_set_character_data_handler($xml_parser, 'characterData');

        $fp = fopen($feed_url, 'r');

        while ($data = fread($fp, 4096))
            xml_parse($xml_parser, $data, feof($fp));

        fclose($fp);

        xml_parser_free($xml_parser);

        return $this->root;
    }

    public function startElement($parser, $tagName, $attrs)
    {
        if ($this->root == null) {
            $this->root = array();
            $this->stack[] = &$this->root;
        }
        else {
            $parent = &$this->stack[count($this->stack) - 1];
            if (!is_array($parent))
                $parent = array($parent);
            if (isset($parent[$tagName])) {
                if (!is_array($parent[$tagName]))
                    $parent[$tagName] = array($parent[$tagName]);
            }
            else
                $parent[$tagName] = null;

            $this->stack[] = &$parent[$tagName];
        }
    }
}