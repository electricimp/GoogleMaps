# GoogleMaps

The Google Maps library uses the Goolge Maps API to get geolocation and time zone information.

**To add this library to your project, add `#require "GoogleMaps.agent.lib.nut:1.0.0"` to the top of your agent code.**

See [Google's API documentation](https://developers.google.com/maps/web-services/) for further information.

[![Build Status](https://travis-ci.org/electricimp/GoogleMaps.svg?branch=master)](https://travis-ci.org/electricimp/GoogleMaps)
 
## Class Usage

### Constructor(*apiKey*)

The library takes one parameter, your Google API key. Apply for an API key on the [Google Developer Console](https://console.developers.google.com/apis/credentials).

```
#require "GoogleMaps.agent.lib.nut:1.0.0"

const API_KEY = "<YOUR API KEY HERE>";
gmaps <- GoogleMaps(API_KEY);
```

## Agent Class Methods

### getGeolocation(*wifis, callback*)

The *getGeolocation()* method will try to determine a geolocation based on the wifi signals from a device side wifi scan. The *wifis* parameter must be the results from the device side [imp.scanwifinetworks](https://electricimp.com/docs/api/imp/scanwifinetworks/) method. The *callback* parameter is a function that will be passed the results of the request to Google Maps API. The *callback* function takes two parameters: error, if an error occured while processing the request otherwise null, and a results table with the response from the Google API. The results table will contain the following fields:

| Field        | Meaning                                                    |
| ------------ | ---------------------------------------------------------- |
| location     | A table with keys `lat` and `lng`                          |
| accuracy     | The accuracy radius of the estimated location, in meters   |

#### Example:
```
// Device side code
agent.send("wifi.networks", imp.scanwifinetworks());
```

```
// Agent side code
const API_KEY = "<YOUR API KEY HERE>";
gmaps <- GoogleMaps(API_KEY);

device.on("wifi.networks", function(wifis) {
    gmaps.getGeolocation(wifis, function(error, resp) {
        if (error != null) {
            server.error(error);
        } else {
            server.log(format("Location latitude: %f, longitude: %f with accuracy: %f", resp.location.lat, resp.location.lng, resp.accuracy));
        }
    })
})
```

### getTimezone(*location, callback*)

This method takes two required parameters: a *location* table with keys `lat` and `lng` and a *callback* function.  This method will take the location data and send it to the Google Maps timezone API. This API will try to return timezone data based on the geolocation provided. The results will be passed to the *callback* function. The *callback* function takes two parameters: error, if an error occured while processing the request otherwise null, and a results table with the response from the Google API. The results table will contain the following fields:

| Field        | Meaning                                                                   |
| ------------ | ------------------------------------------------------------------------- |
| status       | Status of the API query. Either OK or FAIL.                               |
| timeZoneId   | The name of the time zone. Refer to time zone list.                       |
| timeZoneName | The long description of the time zone                                     |
| gmtOffsetStr | GMT Offset String such as GMT-7                                           |
| rawOffset    | The time zone's offset without DST changes                                |
| dstOffset    | The DST offset to be added to the rawOffset to get the current gmtOffset  |
| gmtOffset    | The time offset in seconds based on UTC time.                             |
| time         | Current local time in Unix timestamp.                                     |
| date         | Squirrel date() object                                                    |
| dateStr      | Date string formatted as YYYY-MM-DD HH-MM-SS                              |

#### Example:
```
gmaps.getGeolocation(wifis, function(error, resp) {
   if (error != null) {
        server.error(error);
   } else {
        gmaps.getTimezone(resp.location, function(err, res) {
            if (err != null) {
                server.error(err);
            } else {
                server.log(res.timeZoneName);
                server.log(res.dateStr);
            }
        });
   }
});
```

## Licence

The GoogleMaps library is licensed under the [MIT License](./LICENSE)