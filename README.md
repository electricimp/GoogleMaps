# GoogleMaps

This library uses the Google Maps API to obtain geolocation and time zone information based on a scan of WiFi networks around the device. Please see [Google’s API documentation](https://developers.google.com/maps/web-services/) for further information.

To use the library, you will need a Google API key. You can apply for an API key on the [Google Developer Console](https://console.developers.google.com/apis/credentials).

**To add this library to your project, add** `#require "GoogleMaps.agent.lib.nut:1.1.0"` **to the top of your agent code.**

## Class Usage

### Constructor(*apiKey*)

The library takes one parameter, your Google API key.

```
#require "GoogleMaps.agent.lib.nut:1.1.0"

const API_KEY = "<YOUR API KEY HERE>";
gmaps <- GoogleMaps(API_KEY);
```

## Class Methods

### getGeolocation(*data[, callback]*)

This method will try to determine the location of your device based on a device-side scan of nearby WiFi networks or cell towers.

#### Parameters

| Parameter | Type | Required? | Description |
| --- | --- | --- | --- |
| *data* | Table or Array[*](#data-note) | Yes | A table containing useful data and parameters to make a [Geolocation request](https://developers.google.com/maps/documentation/geolocation/overview#requests) to the Google Maps API. [The description](#geolocation-data-parameter) is below. Or an array of scanned WiFi networks (see [the note below](#data-note)). |
| *callback* | Function | No | A function that will be called when Google returns location data or an error has occurred. The function takes two parameters: *error* and *results*. If an error occured while processing the request, *error* will contain a description of the error, otherwise it will be `null` and [a table containing the results from Google](#geolocation-result-table) will be passed into *results*. |

#### Geolocation Data Parameter

All fields are optional. The main fields of this table are the following:

| Key        | Description                                                |
| ---------- | ---------------------------------------------------------- |
| *wifiAccessPoints* | The result of a scan of WiFi networks made by an imp API [*imp.scanwifinetworks()*](https://developer.electricimp.com/api/imp/scanwifinetworks) call. **NOTE:** The data returned by this imp API is converted to the Google API's required format automatically by this library. |
| *cellTowers* | An array of scanned cell towers. For the format, please, see [the docs](https://developers.google.com/maps/documentation/geolocation/overview#cell_tower_object). |
| *radioType* | The mobile radio type. Makes sense only if scanned cell towers passed. |

The other possible fields and options for the *data* table can be checked out [here](https://developers.google.com/maps/documentation/geolocation/overview#body).

<a id='data-note'></a>
**NOTE:** For the backward compatibility with v1.0.x, it's also allowed to pass the array returned by [*imp.scanwifinetworks()*](https://developer.electricimp.com/api/imp/scanwifinetworks) directly to [the *getGeolocation()* method](#getgeolocationdata-callback) without a wrapping table.

#### Geolocation Result Table

| Key        | Description                                                |
| ---------- | ---------------------------------------------------------- |
| *location* | A table with keys *lat* and *lng*                          |
| *accuracy* | The accuracy radius of the estimated location, in meters   |

#### Returns

If the *callback* parameter was not passed, an instance of [Promise](https://github.com/electricimp/Promise) will be returned. If an error occured while processing the request, this Promise will be rejected with a description of the error. Otherwise, this Promise will be resolved with [a table containing the results from Google](#geolocation-result-table).<br/>
If a callback function was passed into the method, nothing will be returned.

#### Example 1

```
// Device-side code
geolocationData <- {
    "wifiAccessPoints": imp.scanwifinetworks()
};

agent.send("geolocation.data", geolocationData);
```

```
// Agent-side code
const API_KEY = "<YOUR API KEY HERE>";
gmaps <- GoogleMaps(API_KEY);

device.on("geolocation.data", function(geolocationData) {
    gmaps.getGeolocation(geolocationData, function(error, resp) {
        if (error != null) {
            server.error(error);
        } else {
            server.log(format("Location latitude: %f, longitude: %f with accuracy: %f", resp.location.lat, resp.location.lng, resp.accuracy));
        }
    });
});
```

#### Example 2

```
// Device-side code
geolocationData <- {
    "wifiAccessPoints": imp.scanwifinetworks(),
    // The functions below must be implemented in your app
    "cellTowers": scanCellTowers(),
    "radioType": getRadioType()
};

agent.send("geolocation.data", geolocationData);
```

```
// Agent-side code
const API_KEY = "<YOUR API KEY HERE>";
gmaps <- GoogleMaps(API_KEY);

device.on("geolocation.data", function(geolocationData) {
    gmaps.getGeolocation(geolocationData)
    .then(function(resp) {
        server.log(format("Location latitude: %f, longitude: %f with accuracy: %f", resp.location.lat, resp.location.lng, resp.accuracy));
    }, function(err) {
        server.error(err);
    });
});
```

### getTimezone(*location[, callback]*)

This method will obtain the timezone information for the location passed in.

#### Parameters

| Parameter | Type | Required? | Description |
| --- | --- | --- | --- |
| *location* | Table | Yes | The location. A table containing keys *lat* and *lng*. |
| *callback* | Function | No | A function that will be called when Google returns timezone data or an error has occurred. The function takes two parameters: *error* and *results*. If an error occured while processing the request, *error* will contain a description of the error, otherwise it will be `null` and [a table containing the results from Google](#timezone-result-table) will be passed into *results*. |

#### Timezone Result Table

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

#### Returns

If the *callback* parameter was not passed, an instance of [Promise](https://github.com/electricimp/Promise) will be returned. If an error occured while processing the request, this Promise will be rejected with a description of the error. Otherwise, this Promise will be resolved with [a table containing the results from Google](#timezone-result-table).<br/>
If a callback function was passed into the method, nothing will be returned.

#### Example 1

```
gmaps.getGeolocation(geolocationData, function(error, resp) {
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

#### Example 2

```
gmaps.getGeolocation(geolocationData)
.then(function(resp) {
    return gmaps.getTimezone(resp.location);
})
.then(function(resp) {
    server.log(format("Timezone name: %s, date: %s", resp.timeZoneName, resp.dateStr));
})
.fail(function(err) {
    server.error(err);
});
```

## Licence

The GoogleMaps library is licensed under the [MIT License](./LICENSE)
