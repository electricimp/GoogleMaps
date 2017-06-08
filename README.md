# GoogleMaps

The Google Maps library uses the Goolge Maps API to get geolocation and time zone information.

Please note to use this library you must require and instantiate Google Maps on both the agent and the device.

**To add this library to your project, add `#require "GoogleMaps.agent.lib.nut:1.0.0"` to the top of your agent code, and `#require "GoogleMaps.device.lib.nut:1.0.0"` to the top of your device code.**

See [Google's API documentation](https://developers.google.com/maps/web-services/) for further information.

## Device Class Usage

To use just add this statement to the top of your device code. The constructor is called automatically when you require the library. 

```
#require "GoogleMaps.device.lib.nut:1.0.0"
```

### Constructor: GoogleMaps()

**Please Note:** The constructor is called automatically when you require the library. You do not need to call the constructor. 

The device-side library constructor takes no parameters.  It opens a listener for location requests from the agent. When a request is received, the device scans the WiFi networks and sends the result back to the agent. 

## Agent Class Usage

### Constructor(*apiKey*)

The agent-side library takes one parameter, your Google API key. Apply for an API key on the [Google Developer Console](https://console.developers.google.com/apis/credentials).

```
#require "GoogleMaps.agent.lib.nut:1.0.0"

const API_KEY = "<YOUR API KEY HERE>";
gmaps <- GoogleMaps(API_KEY);
```

## Agent Class Methods

### getGeolocation(*callback*)

This will request a wifi scan from the device by issuing a `device.send()` command. The device will respond with the wifi networks it can see and send them to the Google Maps geolocation API. This API will try to return a geolocation based on the wifi signals from the scan. The results will be passed to the *callback* function. The *callback* function takes two parameters: error, if an error occured while processing the request otherwise null, and a results table with the response from the Google API. The results table will contain the following fields:

| Field        | Meaning                                                    |
| ------------ | ---------------------------------------------------------- |
| location     | A table with keys `lat` and `lng`                          |
| accuracy     | The accuracy radius of the estimated location, in meters   |

#### Example:
```
gmaps.getGeolocation(function(error, resp) {
   if (error != null) {
        server.error(error);
   } else {
        server.log(format("Location latitude: %f, longitude: %f with accuracy: %f", resp.location.lat, resp.location.lng, resp.accuracy));
   }
});
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
gmaps.getGeolocation(function(error, resp) {
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