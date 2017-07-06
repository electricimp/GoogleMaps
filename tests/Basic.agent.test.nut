// Copyright 2017 Electric Imp
//
// SPDX-License-Identifier: MIT
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be
// included in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO
// EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES
// OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
// ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
// OTHER DEALINGS IN THE SOFTWARE.


// Test must include both agent and device library files, however
// BasicTestCase runs only on the agent.

const GOOGLE_MAPS_API_KEY = "@{GOOGLE_MAPS_API_KEY}";

class BasicTestCase extends ImpTestCase {

    // Results of a wifi scan
    static wifis = [
                    {
                        "bssid": "0418d672c280",
                        "channel": 11,
                        "ssid": "Electric Imp Guest",
                        "open": false,
                        "rssi": -50
                    },
                    {
                        "bssid": "0418d672c281",
                        "channel": 11,
                        "ssid": "",
                        "open": false,
                        "rssi": -49
                    },
                    {
                        "bssid": "0418d61d9aa0",
                        "channel": 11,
                        "ssid": "Electric Imp Guest",
                        "open": false,
                        "rssi": -35
                    },
                    {
                        "bssid": "1005b1230e00",
                        "channel": 1,
                        "ssid": "ATTP4RRCI2",
                        "open": false,
                        "rssi": -62
                    },
                    {
                        "bssid": "be1544ab9a44",
                        "channel": 11,
                        "ssid": "PAU_5150_Bonjour",
                        "open": false,
                        "rssi": -50
                    },
                    {
                        "bssid": "a61544ab9a44",
                        "channel": 11,
                        "ssid": "PAU_5150_Student",
                        "open": true,
                        "rssi": -51
                    },
                    {
                        "bssid": "0418d61d9ee1",
                        "channel": 11,
                        "ssid": "impair",
                        "open": false,
                        "rssi": -50
                    },
                    {
                        "bssid": "0418d61d9ee0",
                        "channel": 11,
                        "ssid": "Electric Imp Guest",
                        "open": false,
                        "rssi": -52
                    },
                    {
                        "bssid": "0418d61d9ee2",
                        "channel": 11,
                        "ssid": "impervious",
                        "open": false,
                        "rssi": -51
                    },
                    {
                        "bssid": "881544ab9a44",
                        "channel": 11,
                        "ssid": "PAU_5150_Desktops",
                        "open": false,
                        "rssi": -50
                    },
                    {
                        "bssid": "ba1544ab9a44",
                        "channel": 11,
                        "ssid": "PAU_5150_Guest",
                        "open": false,
                        "rssi": -51
                    },
                    {
                        "bssid": "861544ab9a44",
                        "channel": 11,
                        "ssid": "Gronowski-WIFI",
                        "open": false,
                        "rssi": -50
                    },
                    {
                        "bssid": "c07cd1d72e23",
                        "channel": 11,
                        "ssid": "XFINITY",
                        "open": false,
                        "rssi": -81
                    },
                    {
                        "bssid": "9ed36d9c1150",
                        "channel": 8,
                        "ssid": "AISense-Guest",
                        "open": false,
                        "rssi": -48
                    },
                    {
                        "bssid": "9cd36d9c115f",
                        "channel": 8,
                        "ssid": "AISense-2.4-NG",
                        "open": false,
                        "rssi": -47
                    },
                    {
                        "bssid": "0418d61d9aa2",
                        "channel": 11,
                        "ssid": "impervious",
                        "open": false,
                        "rssi": -41
                    },
                    {
                        "bssid": "0418d672c282",
                        "channel": 11,
                        "ssid": "impair",
                        "open": false,
                        "rssi": -49
                    },
                    {
                        "bssid": "0418d672c283",
                        "channel": 11,
                        "ssid": "impervious",
                        "open": false,
                        "rssi": -50
                    },
                    {
                        "bssid": "14d64d35bd24",
                        "channel": 11,
                        "ssid": "dlink",
                        "open": false,
                        "rssi": -55
                    }
                ];

    // Initialize sensor
    function setUp() {
        return "Hi from #{__FILE__}!";
    }

    function testGetGeolocation() {
        local gmaps = GoogleMaps(GOOGLE_MAPS_API_KEY);
        return Promise(function(resolve, reject) {
            gmaps.getGeolocation(wifis, function(err, res) {
                if (err) {
                    reject("Get Geolocation error: " + err);
                } else {
                    assertTrue("location" in res, "Response missing location");
                    assertTrue("accuracy" in res, "Response missing accuracy");
                    assertTrue("lat" in res.location && "lng" in res.location, "lat and lng not in location");
                    resolve("Received geolocation from Google");
                }
            }.bindenv(this))
        }.bindenv(this))
    }

    function testGetGeolocationBadKey() {
        local gmaps_bad_key = GoogleMaps("123");
        return Promise(function(resolve, reject) {
            gmaps_bad_key.getGeolocation(wifis, function(err, res) {
                assertTrue(err != null, "Error not returned");
                resolve("Bad key request failed as expected");
            }.bindenv(this))
        }.bindenv(this))
    }

    function testGetTimezone() {
        local gmaps = GoogleMaps(GOOGLE_MAPS_API_KEY);
        return Promise(function(resolve, reject) {
            gmaps.getGeolocation(wifis, function(err, res) {
                if (err) {
                    reject("Get Geolocation error: " + err);
                } else {
                    gmaps.getTimezone(res.location, function(error, resp) {
                        assertTrue(err == null, "Error in response");
                        assertTrue(resp.status == "OK", "Unexpected response");
                        assertTrue("timeZoneId" in resp, "Unexpected response");
                        assertTrue("timeZoneName" in resp, "Unexpected response");
                        assertTrue("gmtOffsetStr" in resp, "Unexpected response");
                        assertTrue("rawOffset" in resp, "Unexpected response");
                        assertTrue("dstOffset" in resp, "Unexpected response");
                        assertTrue("gmtOffset" in resp, "Unexpected response");
                        assertTrue("time" in resp, "Unexpected response");
                        assertTrue("date" in resp, "Unexpected response");
                        assertTrue("dateStr" in resp, "Unexpected response");
                        resolve("Timezone request has expected keys in the response")
                    }.bindenv(this));
                }
            }.bindenv(this))
        }.bindenv(this))
    }

    function tearDown() {
        return "Test finished";
    }

}