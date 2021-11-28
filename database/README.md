# Database code

_Run on a Raspberry Pi 4 with port 8000 exposed to local network_

## Get a dump of data from database

```bash
curl "10.0.0.137:8000/dumpdata?nobs=10"
```

Returns...

```json
{
  "res": [
    { "time": 1637978931, "co2": 501, "temp": 50.1, "humidity": 50.1 },
    { "time": 1638033661, "co2": 501, "temp": 20.1, "humidity": 50.1 },
    { "time": 1638033661, "co2": 501, "temp": 20.1, "humidity": 50.1 },
    { "time": 1638037261, "co2": 401, "temp": 40.1, "humidity": 40.1 },
    { "time": 1638056534, "co2": 611, "temp": 22.067, "humidity": 25.026 },
    { "time": 1638056538, "co2": 606, "temp": 21.584, "humidity": 25.533 },
    { "time": 1638056544, "co2": 636, "temp": 21.333, "humidity": 25.896 },
    { "time": 1638056548, "co2": 630, "temp": 21.116, "humidity": 26.274 },
    { "time": 1638056553, "co2": 626, "temp": 20.881, "humidity": 26.517 },
    { "time": 1638056557, "co2": 630, "temp": 20.697, "humidity": 26.898 }
  ]
}
```
