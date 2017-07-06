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

const GOOGLE_MAPS_WIFI_SIGNALS_ERROR        = "Insufficient wifi signals found";
const GOOGLE_MAPS_MISSING_REQ_PARAMS_ERROR  = "Location table must have keys: 'lat' and 'lng'";
const GOOGLE_MAPS_UNEXPECTED_RESP_ERROR     = "Unexpected response from Google";
const GOOGLE_MAPS_LIMIT_EXCEEDED_ERROR      = "You have exceeded your daily limit";
const GOOGLE_MAPS_INVALID_KEY_ERROR         = "Your Google Maps Geolocation API key is not valid or the request body is not valid JSON";
const GOOGLE_MAPS_LOCATION_NOT_FOUND_ERROR  = "Your API request was valid, but no results were returned";

class GoogleMaps {

    static VERSION = "1.0.0";

    static LOCATION_URL = "https://www.googleapis.com/geolocation/v1/geolocate?key=";
    static TIMEZONE_URL = "https://maps.googleapis.com/maps/api/timezone/json?";

    _apiKey = null;

    constructor(apiKey) {
        _apiKey = apiKey;
    }

    function getGeolocation(wifis, cb) {
        if (wifis.len() < 2) {
            imp.wakeup(0, function() { cb(WIFI_SIGNALS_ERROR, null); }.bindenv(this));
            return;
        }

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
        request.sendasync(function(res) {
            _locationRespHandler(wifis, res, cb);
        }.bindenv(this));
    }

    function getTimezone(location, cb) {
        if (!("lat" in location && "lng" in location)) {
            // Make sure we have the parameters we need to make request
            cb(GOOGLE_MAPS_MISSING_REQ_PARAMS_ERROR, null);
        }
        
        local url = format("%slocation=%f,%f&timestamp=%d&key=%s", TIMEZONE_URL, location.lat, location.lng, time(), _apiKey);
        local req = http.get(url, {})
        req.sendasync(function(res) {
            _timezoneResHandler(res, cb);
        }.bindenv(this));
    }

    function _timezoneResHandler(res, cb) {
        local body;
        local err = null;

        try {
            body = http.jsondecode(res.body);
        } catch(e) {
            imp.wakeup(0, function() { cb(e, res); }.bindenv(this));
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
            } else {
                if ("errorMessage" in body) {
                    err = body.status + ": " + body.errorMessage;
                } else {
                    err = body.status;
                }
            }
        } else {
            err = res.statuscode + ": " + GOOGLE_MAPS_UNEXPECTED_RESP_ERROR;
        }
        
        // Pass err/response to callback
        imp.wakeup(0, function() { 
            (err) ?  cb(err, res) : cb(err, body);
        }.bindenv(this));
    }

    // Process location HTTP response
    function _locationRespHandler(wifis, res, cb) {
        local body; 
        local err = null;

        try {
            body = http.jsondecode(res.body);
        } catch(e) {
            imp.wakeup(0, function() { cb(e, res); }.bindenv(this));
        }
        
        local statuscode = res.statuscode;
        switch(statuscode) {
            case 200:
                if ("location" in body) {
                    res = body;
                } else {
                    err = GOOGLE_MAPS_LOCATION_NOT_FOUND_ERROR;
                }
                break;
            case 400:
                err = GOOGLE_MAPS_INVALID_KEY_ERROR;
                break;
            case 403:
                err = GOOGLE_MAPS_LIMIT_EXCEEDED_ERROR;
                break;
            case 404:
                err = GOOGLE_MAPS_LOCATION_NOT_FOUND_ERROR;
                break;
            case 429:
                // Too many requests try again in a second
                imp.wakeup(1, function() { getLocation(wifis, cb); }.bindenv(this));
                return;
            default:
                if ("message" in body) {
                    // Return Google's error message
                    err = body.message;
                } else {
                    // Pass generic error and response so user can handle error
                    err = GOOGLE_MAPS_UNEXPECTED_RESP_ERROR;
                }
        }
        
        imp.wakeup(0, function() { cb(err, res); }.bindenv(this));
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