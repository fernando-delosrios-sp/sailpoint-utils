# IAI Recommendations

3 endpoints. Paths are relative to the environment API host.

## Returns recommendation based on object

`POST /recommendations/v1/request`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 200.

The getRecommendations API returns recommendations based on the requested object. The recommendations are invoked by IdentityIQ and IdentityNow plug-ins that retrieve recommendations based on the performed calculations.

Body:

```json
{
  "requests": [
    {
      "identityId": "2c938083633d259901633d25c68c00fa",
      "item": {
        "id": "2c938083633d259901633d2623ec0375",
        "type": "ENTITLEMENT"
      }
    },
    {
      "identityId": "2c938083633d259901633d25c68c00fa",
      "item": {
        "id": "2c938083633d259901633d2623ec0375",
        "type": "ENTITLEMENT"
      }
    }
  ],
  "excludeInterpretations": "false",
  "includeTranslationMessages": "false",
  "includeDebugInformation": "false",
  "prescribeMode": "false"
}
```

## Get certification recommendation config values

`GET /recommendations/v1/config`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 200.

Retrieves configuration attributes used by certification recommendations.

## Update certification recommendation config values

`PUT /recommendations/v1/config`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 200.

Updates configuration attributes used by certification recommendations.

Body:

```json
{
  "recommenderFeatures": [
    "jobTitle",
    "location",
    "peer_group",
    "department",
    "active"
  ],
  "peerGroupPercentageThreshold": 0.5,
  "runAutoSelectOnce": false,
  "onlyTuneThreshold": false
}
```
