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

    static SCAN_REQUEST = "google.maps.scan";
    static WIFI_NETWORKS_RESPONSE = "google.maps.wifi.networks";

    static LOCATION_URL = "https://www.googleapis.com/geolocation/v1/geolocate?key=";
    static TIMEZONE_URL = "https://maps.googleapis.com/maps/api/timezone/json?";

    static TIMEOUT_ERROR = "Timeout waiting for wifi scan";
    static WIFI_SIGNALS_ERROR = "Insufficient wifi signals found";
    static MISSING_REQ_PARAMS_ERROR = "Location table must have keys: 'lat' and 'lng'";
    static REQUEST_IN_PROGRESS = "Request already in progress";
    static GOOGLE_REQ_ERROR = "Unexpected response from Google";
    static GOOGLE_REQ_LIMIT_EXCEEDED_ERROR  = "You have exceeded your daily limit";
    static GOOGLE_REQ_INVALID_KEY_ERROR  = "Your Google Maps Geolocation API key is not valid or the request body is not valid JSON";
    static GOOGLE_REQ_LOCATION_NOT_FOUND_ERROR  = "Your API request was valid, but no results were returned";

    static WIFI_SCAN_TIMEOUT_SEC = 30;
    static START_UP_DELAY = 0.5;

    _apiKey = null;
    _locationCB = null;
    _timezoneCB = null;
    _wifis = null;
    _scanTimer = null;

    constructor(apiKey) {
        _apiKey = apiKey;
        device.on(WIFI_NETWORKS_RESPONSE, _getLocation.bindenv(this));

        // Ugly hack to make sure the partner has registered
        // handler before location request is processed
        imp.sleep(START_UP_DELAY);
    }

    function getGeolocation(cb) {
        // Only process one request at a time
        if (_locationCB != null) {
            cb(REQUEST_IN_PROGRESS, null);
            return;
        }
        
        _locationCB = cb;

        device.send(SCAN_REQUEST, null);
        
        // Return a timeout error if we do not hear from the device
        _scanTimer = imp.wakeup(WIFI_SCAN_TIMEOUT_SEC, function() {
            _locationCB(TIMEOUT_ERROR, null);
            _locationCB = null;
        }.bindenv(this));
    }

    function getTimezone(location, cb) {
        if (_timezoneCB != null) {
            // Only process one request at a time
            cb(REQUEST_IN_PROGRESS, null);
            return;
        } else if (!("lat" in location && "lng" in location)) {
            // Make sure we have the parameters we need to make request
            cb(MISSING_REQ_PARAMS_ERROR, null);
        }
        
        _timezoneCB = cb;
        local url = format("%slocation=%f,%f&timestamp=%d&key=%s", TIMEZONE_URL, location.lat, location.lng, time(), _apiKey);
        local req = http.get(url, {})
        req.sendasync(_timezoneResHandler.bindenv(this));
    }

    function _timezoneResHandler(res) {
        local body;
        local err = null;

        try {
            body = http.jsondecode(res.body);
        } catch(e) {
            imp.wakeup(0, function() {
                _timezoneCB(e, res);
                _timezoneCB = null;
            }.bindenv(this))
        }

        if ("status" in body) {
            if (body.status == "OK") {
                // Success
                local t = time() + body.rawOffset + body.dstOffset;
                local d = date(t);
                body.time <- t;
                body.date <- d;
                body.dateStr <- format("%04d-%02d-%02d %02d:%02d:%02d", d.year, d.month+1, d.day, d.hour, d.min, d.sec)
                body.gmtOffset <- body.rawOffset + body.dstOffset;
                body.gmtOffsetStr <- format("GMT%s%d", body.gmtOffset < 0 ? "-" : "+", math.abs(body.gmtOffset / 3600));
    
                res = body;
            } else {
                if ("errorMessage" in body) {
                    err = body.status + ": " + body.errorMessage;
                } else {
                    err = body.status;
                }
            }
        } else {
            err = res.statuscode + ": " + GOOGLE_REQ_ERROR;
        }
        
        // Pass err/response to callback
        imp.wakeup(0, function() {
            _timezoneCB(err, res);
            _timezoneCB = null;
        }.bindenv(this));
    }

    // Process location HTTP response
    function _locationRespHandler(res) {
        local body; 
        local err = null;

        try {
            body = http.jsondecode(res.body);
        } catch(e) {
            imp.wakeup(0, function() {
                _locationCB(e, res);
                _locationCB = null;
                _wifis = null;   
            }.bindenv(this))
        }
        
        local statuscode = res.statuscode;
        switch(statuscode) {
            case 200:
                if ("location" in body) {
                    res = body;
                } else {
                    err = GOOGLE_REQ_LOCATION_NOT_FOUND_ERROR;
                }
                break;
            case 400:
                err = GOOGLE_REQ_INVALID_KEY_ERROR;
                break;
            case 403:
                err = GOOGLE_REQ_LIMIT_EXCEEDED_ERROR;
                break;
            case 404:
                err = GOOGLE_REQ_LOCATION_NOT_FOUND_ERROR;
                break;
            case 429:
                // Too many requests try again in a second
                imp.wakeup(1, function() {
                    _getLocation(_wifis);
                }.bindenv(this));
                return;
            default:
                if ("message" in body) {
                    // Return Google's error message
                    err = body.message;
                } else {
                    // Pass generic error and response so user can handle error
                    err = GOOGLE_REQ_ERROR;
                }
        }
        
        imp.wakeup(0, function() {
            _locationCB(err, res);
            _locationCB = null;
            _wifis = null;   
        }.bindenv(this));
    }

    // Handle Wifi scan from device
    function _getLocation(wifis) {
        if (_scanTimer) {
            imp.cancelwakeup(_scanTimer);
            _scanTimer = null;
        }

        if (wifis.len() < 2) {
            imp.wakeup(0, function() {
                _locationCB(WIFI_SIGNALS_ERROR, null);
                _locationCB = null;
            }.bindenv(this))
            return;
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