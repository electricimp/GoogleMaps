# GoogleMaps

This library uses the Google Maps API to obtain geolocation and time zone information based on a scan of WiFi networks and cell towers around the device. Please see [Google’s API documentation](https://developers.google.com/maps/web-services/) for further information.

To use the library, you will need a Google API key. You can apply for an API key on the [Google Developer Console](https://console.developers.google.com/apis/credentials).

**To add this library to your project, add** `#require "GoogleMaps.agent.lib.nut:1.1.0"` **to the top of your agent code.**

Note, this version is backward compatible with the 1.0.x versions.

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

This method tries to determine the location of your device based on a device-side scan of nearby WiFi networks and/or cell towers.

#### Parameters

| Parameter | Type | Required? | Description |
| --- | --- | --- | --- |
| *data* | Table or Array | Yes | Table with [Geolocation Request Parameters](#geolocation-request-parameters). For the backward compatibility with the 1.0.x versions of this library, it is allowed to directly pass the *wifiAccessPoints* array (array of WiFi networks - see [Geolocation Request Parameters](#geolocation-request-parameters)) without wrapping this array into a table. |
| *callback* | Function | No | Function that will be called when the Google Maps API returns location or an error has occurred. The function takes two parameters: *error* (String with the error description) and *results* (Table [Geolocation Result](#geolocation-result)). If *error* is *null* (an error has occurred), then *results* should be ignored. If *error* is not *null* (no error has occurred), then *results* contains the location information. If the *callback* function is not specified or is *null*, then the result of the operation is returned via the [Promise](#getgeolocation-returns). |

#### Geolocation Request Parameters

Table with parameters for a [Geolocation request](https://developers.google.com/maps/documentation/geolocation/overview#requests) to the Google Maps API.

| Key        | Type | Description                                                |
| ---------- | ---- | ---------------------------------------------------------- |
| *wifiAccessPoints* | Array | Array with information about nearby WiFi networks. The format is equal to the format returned by the [*imp.scanwifinetworks()*](https://developer.electricimp.com/api/imp/scanwifinetworks) imp API method. This format is converted to the Geolocation request parameters by the GoogleMaps library itself. |
| *cellTowers* | Array | Array with information about nearby cell towers. For the format - see the [Cell tower objects](https://developers.google.com/maps/documentation/geolocation/overview#cell_tower_object) section in the Geolocation request description. |
| *radioType* | String | Mobile radio type. Makes sense if *cellTowers* is passed. See the [radioType](https://developers.google.com/maps/documentation/geolocation/overview#body) field in the Geolocation request body description. |

- When you need to determine the location using WiFi networks - specify the *wifiAccessPoints* field. Alternatively, you can pass this array directly to the *getGeolocation()* method as the *data* parameter.
- When you need to determine the location using cell towers - specify the *cellTowers* field and, optionally, the *radioType* field.
- If you specify the both *wifiAccessPoints* and *cellTowers* fields, the Google Maps API will decide how to determine the location by itself.

There are more optional fields which can be additionally specified in the table and passed into the Geolocation request - see the [Geolocation request body description](https://developers.google.com/maps/documentation/geolocation/overview#body).

#### Geolocation Result

Table with the location if it is successfully determined.

| Key        | Type | Description                                                |
| ---------- | ---- | ---------------------------------------------------------- |
| *location* | Table | Estimated location - table with the fields: *lat* (Float - latitude, in degrees) and *lng* (Float - longitude, in degrees) |
| *accuracy* | Float | Accuracy radius of the estimated location, in meters |

#### getGeolocation Returns

- If the *callback* parameter was not specified or was *null*, an instance of [Promise](https://github.com/electricimp/Promise) is returned. If an error has occurred, this Promise is rejected with String - description of the error. Otherwise, this Promise is resolved with Table [Geolocation Result](#geolocation-result) - location information.
- If the *callback* parameter was specified, nothing is returned.

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

This method obtains the timezone information for the location passed in.

#### Parameters

| Parameter | Type | Required? | Description |
| --- | --- | --- | --- |
| *location* | Table | Yes | Location - table with the fields: *lat* (Float - latitude, in degrees) and *lng* (Float - longitude, in degrees) |
| *callback* | Function | No | Function that will be called when the Google Maps API returns timezone information or an error has occurred. The function takes two parameters: *error* (String with the error description) and *results* (Table [Timezone Result](#timezone-result)). If *error* is *null* (an error has occurred), then *results* should be ignored. If *error* is not *null* (no error has occurred), then *results* contains the timezone information. If the *callback* function is not specified or is *null*, then the result of the operation is returned via the [Promise](#gettimezone-returns). |

#### Timezone Result

Table with the timezone information if it is successfully obtained.

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

#### getTimezone Returns

- If the *callback* parameter was not specified or was *null*, an instance of [Promise](https://github.com/electricimp/Promise) is returned. If an error has occurred, this Promise is rejected with String - description of the error. Otherwise, this Promise is resolved with Table [Timezone Result](#timezone-result) - timezone information.
- If the *callback* parameter was specified, nothing is returned.

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

## License

The GoogleMaps library is licensed under the [MIT License](./LICENSE)
