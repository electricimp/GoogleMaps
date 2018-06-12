# GoogleMaps

This library uses the Google Maps API to obtain geolocation and time zone information based on a scan of WiFi networks around the device. Please see [Google’s API documentation](https://developers.google.com/maps/web-services/) for further information.

To use the library, you will need a Google API key. You can apply for an API key on the [Google Developer Console](https://console.developers.google.com/apis/credentials).

**To add this library to your project, add** `#require "GoogleMaps.agent.lib.nut:1.0.0"` **to the top of your agent code.**

[![Build Status](https://travis-ci.org/electricimp/GoogleMaps.svg?branch=master)](https://travis-ci.org/electricimp/GoogleMaps)
 
## Class Usage

### Constructor(*apiKey*)

The library takes one parameter, your Google API key.

```
#require "GoogleMaps.agent.lib.nut:1.0.0"

const API_KEY = "<YOUR API KEY HERE>";
gmaps <- GoogleMaps(API_KEY);
```

## Class Methods

### getGeolocation(*networks, callback*)

The *getGeolocation()* method will try to determine the location of your device based on a device-side scan of nearby WiFi networks. The scan is made by an imp API [*imp.scanwifinetworks()*](https://developer.electricimp.com/api/imp/scanwifinetworks) call, the results of which should be sent to the agent and passed into *getGeolocation()*’s *networks* parameter.

The *callback* parameter is a function that will be called when Google returns location data or an error has occurred. The function takes two parameters: *error* and *results*. If an error occured while processing the request, *error* will contain a description of the error, otherwise it will be `null` and a table containing the results from Google will be passed into *results*. This table will contain the following keys:

| Key        | Description                                                |
| ---------- | ---------------------------------------------------------- |
| *location* | A table with keys *lat* and *lng*                          |
| *accuracy* | The accuracy radius of the estimated location, in meters   |

#### Example

```
// Device-side code
agent.send("wifi.networks", imp.scanwifinetworks());
```

```
// Agent-side code
const API_KEY = "<YOUR API KEY HERE>";
gmaps <- GoogleMaps(API_KEY);

device.on("wifi.networks", function(networks) {
    gmaps.getGeolocation(networks, function(error, resp) {
        if (error != null) {
            server.error(error);
        } else {
            server.log(format("Location latitude: %f, longitude: %f with accuracy: %f", resp.location.lat, resp.location.lng, resp.accuracy));
        }
    });
});
```

### getTimezone(*location, callback*)

This method takes two required parameters: a *location* table with keys *lat* and *lng*, and a *callback* function. It sends the location data to the Google Maps timezone API. The result is passed to the *callback* function, which takes two parameters: *error*, which will hold an error message if an error occurred while processing the request, otherwise `null`, and *results*, which is table with the response from Google. The results table will contain the following keys:

| Key          | Description                                                               |
| ------------ | ------------------------------------------------------------------------- |
| *status*       | Status of the API query. Either OK or FAIL                              |
| *timeZoneId*   | The name of the timezone. Refer to Google’s timezone list                    |
| *timeZoneName* | A long description of the timezone                                     |
| *gmtOffsetStr* | GMT offset as a string, eg. `"GMT-7"`                                           |
| *rawOffset*    | The timezone’s offset without DST changes                                |
| *dstOffset*    | The DST offset to be added to the *rawOffset* to get the current *gmtOffset*  |
| *gmtOffset*    | The time offset in seconds based on UTC time                             |
| *time*         | Current local time in Unix timestamp                                     |
| *date*         | The request date as a Squirrel *date()* object                            |
| *dateStr*      | The request date as a string in `YYYY-MM-DD HH-MM-SS` format             |

#### Example

```
gmaps.getGeolocation(networks, function(error, resp) {
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
