// Copyright 2017-2021 Electric Imp
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


const GOOGLE_MAPS_API_KEY = "@{GOOGLE_MAPS_API_KEY}";

class BasicTestCase extends ImpTestCase {

    // Results of a wifi scan
    static wifis = [
        {
            "bssid": "4448c1a6f3d0",
            "channel": 11,
            "ssid": "net1",
            "open": false,
            "rssi": -54
        },
        {
            "bssid": "9c1c12b045f1",
            "channel": 11,
            "ssid": "net2",
            "open": false,
            "rssi": -43
        },
        {
            "bssid": "20a6cd336cf4",
            "channel": 8,
            "ssid": "net3",
            "open": false,
            "rssi": -32
        }
    ];

    static cellTowers = [
        {
          "cellId": 61291,
          "mobileCountryCode": 310,
          "mobileNetworkCode": 260,
          "locationAreaCode": 83,
          "signalStrength": -50
        },
        {
          "cellId": 60391,
          "mobileCountryCode": 310,
          "mobileNetworkCode": 260,
          "locationAreaCode": 83,
          "signalStrength": -50
        },
        {
          "cellId": 30332,
          "mobileCountryCode": 310,
          "mobileNetworkCode": 260,
          "locationAreaCode": 83,
          "signalStrength": -40
        }
    ];

    // Initialize sensor
    function setUp() {
        return "Hi from #{__FILE__}!";
    }

    function testGetGeolocation() {
        local data = {
            "wifiAccessPoints": wifis,
            "cellTowers": cellTowers,
            "radioType": "gsm"
        };

        return _testGetGeolocation(data);
    }

    function testGetGeolocationOnlyWifi() {
        local data = {
            "wifiAccessPoints": wifis
        };

        return _testGetGeolocation(data);
    }

    function testGetGeolocationOnlyWifiArray() {
        return _testGetGeolocation(wifis);
    }

    function testGetGeolocationOnlyCell() {
        local data = {
            "cellTowers": cellTowers,
            "radioType": "gsm"
        };

        return _testGetGeolocation(data);
    }

    function testGetGeolocationNoCallback() {
        local gmaps = GoogleMaps(GOOGLE_MAPS_API_KEY);

        local data = {
            "wifiAccessPoints": wifis,
            "cellTowers": cellTowers,
            "radioType": "gsm"
        };

        return gmaps.getGeolocation(data)
        .then(function(res) {
            assertTrue("location" in res, "Response missing location");
            assertTrue("accuracy" in res, "Response missing accuracy");
            assertTrue("lat" in res.location && "lng" in res.location, "lat and lng not in location");
        }.bindenv(this));
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
                        if (error != null) {
                            return reject("Error in response of getTimezone(): " + error);
                        }

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

    function testGetTimezoneNoCallback() {
        local gmaps = GoogleMaps(GOOGLE_MAPS_API_KEY);

        return gmaps.getGeolocation(wifis)
        .then(function(res) {
            return gmaps.getTimezone(res.location);
        }.bindenv(this))
        .then(function(res) {
            assertTrue(res.status == "OK", "Unexpected response");
            assertTrue("timeZoneId" in res, "Unexpected response");
            assertTrue("timeZoneName" in res, "Unexpected response");
            assertTrue("gmtOffsetStr" in res, "Unexpected response");
            assertTrue("rawOffset" in res, "Unexpected response");
            assertTrue("dstOffset" in res, "Unexpected response");
            assertTrue("gmtOffset" in res, "Unexpected response");
            assertTrue("time" in res, "Unexpected response");
            assertTrue("date" in res, "Unexpected response");
            assertTrue("dateStr" in res, "Unexpected response");
        }.bindenv(this));
    }

    function tearDown() {
        return "Test finished";
    }

    function _testGetGeolocation(data) {
        local gmaps = GoogleMaps(GOOGLE_MAPS_API_KEY);

        return Promise(function(resolve, reject) {
            gmaps.getGeolocation(data, function(err, res) {
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
}
