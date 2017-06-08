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

const GOOGLE_MAPS_API_KEY = "#{env:GOOGLE_MAPS_API_KEY}";

class BasicTestCase extends ImpTestCase {

    // Initialize sensor
    function setUp() {
        return "Hi from #{__FILE__}!";
    }

    function testGetGeolocation() {
        local gmaps = GoogleMaps(GOOGLE_MAPS_API_KEY);
        return Promise(function(resolve, reject) {
            gmaps.getGeolocation(function(err, res) {
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
            gmaps_bad_key.getGeolocation(function(err, res) {
                assertTrue(err != null, "Error not returned");
                resolve("Bad key request failed as expected");
            }.bindenv(this))
        }.bindenv(this))
    }

    function testGetGeolocationDoubleRequest() {
        local gmaps = GoogleMaps(GOOGLE_MAPS_API_KEY);
        return Promise(function(resolve, reject) {
            gmaps.getGeolocation(function(err, res) {
                assertTrue(err == null, "Error in response");
                assertTrue("location" in res, "Response missing location"); 
                resolve("Double request test done");
            }.bindenv(this))
            gmaps.getGeolocation(function(err, res) {
                assertTrue(err != null, "Error not returned");
            }.bindenv(this))
        }.bindenv(this))
    }

    function testGetTimezone() {
        local gmaps = GoogleMaps(GOOGLE_MAPS_API_KEY);
        return Promise(function(resolve, reject) {
            gmaps.getGeolocation(function(err, res) {
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