// MIT License
//
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

class GoogleMaps {

    static VERSION = "1.0.0";

    static LOCATION_URL = "https://www.googleapis.com/geolocation/v1/geolocate?key=";
    static TIMEZONE_URL = "https://maps.googleapis.com/maps/api/timezone/json?location=%f,%f&timestamp=%d";

    static TIMEOUT_ERROR = "Timeout waiting for wifi scan";
    static DEVICE_NOT_CONNECTED = "Device not connected";
    static WIFI_SIGNALS_ERROR = "Insufficient wifi signals found";
    static GOOGLE_REQ_ERROR = "Unexpected response from Google";

    static WIFI_SCAN_TIMEOUT = 30;
    static START_UP_DELAY = 0.5;

    _apiKey = null;
    _locationCB = null;
    _timezoneCB = null;
    _wifis = null;
    _scanTimer - null;

    constructor(apiKey) {
        _apiKey = apiKey;
        device.on("wifi.networks", _getLocation.bindenv(this));

        // Ugly hack to make sure the partner has registered
        // handler before location request is processed
        imp.sleep(START_UP_DELAY);
    }

    function getLocation(cb) {
        _locationCB = cb;

        if (device.isconnected()) {
            device.send("scan", null);
            _scanTimer = imp.wakeup(WIFI_SCAN_TIMEOUT, function() {
                _locationCB(TIMEOUT_ERROR, null);
            }.bindenv(this))
        } else {
            _locationCB(DEVICE_NOT_CONNECTED, null);
        }
    }

    function getTimezone(location, cb) {
        assert("lat" in location && "lng" in location);
        _timezoneCB = cb;

        local url = format("%s%s", TIMEZONE_URL, _apiKey);
        local req = http.get(url, {})
        req.sendasync(_timezoneResHandler.bindenv(this));
    }

    function _timezoneResHandler(res) {
        local body;

        try {
            body = http.jsondecode(res.body);
        } catch(e) {
            _timezoneCB(e, res);
            return;
        }

        if ("status" in body && body.status == "OK") {
            // Success
            local t = time() + body.rawOffset + body.dstOffset;
            local d = date(t);
            body.time <- t;
            body.date <- d;
            body.dateStr <- format("%04d-%02d-%02d %02d:%02d:%02d", d.year, d.month+1, d.day, d.hour, d.min, d.sec)
            body.gmtOffset <- body.rawOffset + body.dstOffset;
            body.gmtOffsetStr <- format("GMT%s%d", body.gmtOffset < 0 ? "-" : "+", math.abs(body.gmtOffset / 3600));

            _timezoneCB(null, body);
        } else {
            _timezoneCB(GOOGLE_REQ_ERROR, res);
        }

    }

    // Process location HTTP response
    function _locationRespHandler(res) {
        local body;
        local statuscode = res.statuscode;

        try {
            body = http.jsondecode(res.body);
        } catch(e) {
            _locationCB(e, res);
            _wifis = null;
            return;
        }

        if (statuscode == 200 && "location" in body) {
            _locationCB(null, body.location);
            _wifis = null;
        } else if (statuscode == 429) {
            // Too many requests try again in a second
            imp.wakeup(1, function() {
                _getLocation(_wifis);
            }.bindenv(this));
        } else if ("message" in body) {
            // Return Google's error message
            _locationCB(body.message, res);
            _wifis = null;
        } else {
            // Pass generic error and response so user can handle error
            _locationCB(GOOGLE_REQ_ERROR, res);
            _wifis = null;
        }
    }

    // Handle Wifi scan from device
    function _getLocation(wifis) {
        if (_scanTimer) {
            imp.cancelwakeup(_scanTimer);
            _scanTimer = null;
        }

        if (wifis.len() < 2) {
            _locationCB(WIFI_SIGNALS_ERROR, null);
            return
        }

        // Store wifi scan result to use if we need to retry request
        _wifis = wifis;

        // Build request
        local url = format("%s%s", LOCATION_URL, _apiKey);
        local headers = {"Content-Type" : "application/json"};
        local body = { "wifiAccessPoints": [] };

        foreach (network in wifis) {
            body.wifiAccessPoints.append({ "macAddress": _addColons(network.bssid),
                                           "signalStrength": network.rssi
                                           "channel" : network.channel });
        }

        local request = http.post(url, headers, http.jsonencode(body));
        request.sendasync(_locationRespHandler.bindenv(this));
    }

    // Format bssids for Google
    function _addColons(bssid) {
        // Format a WLAN basestation MAC for transmission to Google
        local result = bssid.slice(0, 2);
        for (local i = 2 ; i < 12 ; i += 2) {
            result = result + ":" + bssid.slice(i, i + 2)
        }
        return result.toupper();
    }
}