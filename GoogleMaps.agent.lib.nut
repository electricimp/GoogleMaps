// MIT License
//
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

const GOOGLE_MAPS_WIFI_SIGNALS_ERROR        = "Insufficient wifi signals found";
const GOOGLE_MAPS_MISSING_REQ_PARAMS_ERROR  = "Location table must have keys: 'lat' and 'lng'";
const GOOGLE_MAPS_UNEXPECTED_RESP_ERROR     = "Unexpected response from Google";
const GOOGLE_MAPS_LIMIT_EXCEEDED_ERROR      = "You have exceeded your daily limit";
const GOOGLE_MAPS_INVALID_KEY_ERROR         = "Your Google Maps Geolocation API key is not valid or the request body is not valid JSON";
const GOOGLE_MAPS_LOCATION_NOT_FOUND_ERROR  = "Your API request was valid, but no results were returned";
const GOOGLE_MAPS_NO_PROMISE_LIB_ERROR      = "If no callback passed, the Promise library is required";

class GoogleMaps {

    static VERSION = "1.1.0";

    static LOCATION_URL = "https://www.googleapis.com/geolocation/v1/geolocate?key=";
    static TIMEZONE_URL = "https://maps.googleapis.com/maps/api/timezone/json?";

    _apiKey = null;

    constructor(apiKey) {
        _apiKey = apiKey;
    }

    function getGeolocation(data, cb = null) {
        // We assume that if data is an array, then it contains WiFi networks.
        // NOTE: This is for the backward compatibility with v1.0.x
        if (typeof data == "array") {
            data = {
                "wifiAccessPoints": data
            };
        }

        local body = clone data;

        if (!("considerIp" in body)) {
            body.considerIp <- false;
        }

        if ("wifiAccessPoints" in data) {
            if (!("cellTowers" in data) && data.wifiAccessPoints.len() < 2) {
                if (cb) {
                    imp.wakeup(0, @() cb(GOOGLE_MAPS_WIFI_SIGNALS_ERROR, null));
                    return;
                } else {
                    return Promise.reject(GOOGLE_MAPS_WIFI_SIGNALS_ERROR);
                }
            }

            local wifis = [];

            foreach (wifi in data.wifiAccessPoints) {
                wifis.append({
                    "macAddress": _addColons(wifi.bssid),
                    "signalStrength": wifi.rssi,
                    "channel" : wifi.channel
                });
            }

            body.wifiAccessPoints <- wifis;
        }

        // Build request
        local url = format("%s%s", LOCATION_URL, _apiKey);
        local headers = {"Content-Type" : "application/json"};
        local request = http.post(url, headers, http.jsonencode(body));

        return _processRequest(request, _locationRespHandler, cb, data);
    }

    function getTimezone(location, cb = null) {
        // Make sure we have the parameters we need to make request
        if (!("lat" in location && "lng" in location)) {
            if (cb) {
                cb(GOOGLE_MAPS_MISSING_REQ_PARAMS_ERROR, null);
                return;
            } else {
                return Promise.reject(GOOGLE_MAPS_MISSING_REQ_PARAMS_ERROR);
            }
        }

        local url = format("%slocation=%f,%f&timestamp=%d&key=%s", TIMEZONE_URL, location.lat, location.lng, time(), _apiKey);
        local request = http.get(url, {});

        return _processRequest(request, _timezoneRespHandler, cb);
    }

    // additionalData - an optional parameter which will be passed to respHandler once the response has been received
    function _processRequest(request, respHandler, cb, additionalData = null) {
        if (!cb) {
            if (!("Promise" in getroottable())) {
                throw GOOGLE_MAPS_NO_PROMISE_LIB_ERROR;
            }

            return Promise(function(resolve, reject) {
                cb = function(err, resp) {
                    err ? reject(err) : resolve(resp);
                }.bindenv(this);

                request.sendasync(function(res) {
                    respHandler(res, cb, additionalData);
                }.bindenv(this));
            }.bindenv(this));
        }

        request.sendasync(function(res) {
            respHandler(res, cb, additionalData);
        }.bindenv(this));
    }

    // _ - unused parameter. Declared only for unification with the other response handler
    function _timezoneRespHandler(res, cb, _ = null) {
        local body;
        local err = null;

        try {
            body = http.jsondecode(res.body);
        } catch(e) {
            imp.wakeup(0, function() { cb(e, res); }.bindenv(this));
            return;
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
    function _locationRespHandler(res, cb, reqData) {
        local body;
        local err = null;

        try {
            body = http.jsondecode(res.body);
        } catch(e) {
            imp.wakeup(0, function() { cb(e, res); }.bindenv(this));
            return;
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
                imp.wakeup(1, function() { getGeolocation(reqData, cb); }.bindenv(this));
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