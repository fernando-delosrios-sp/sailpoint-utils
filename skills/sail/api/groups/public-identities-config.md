# Public Identities Config

Use this API to implement public identity configuration functionality.

2 endpoints. Paths are relative to the environment API host.

## Get the public identities configuration

`GET /public-identities-config/v1`

Success: 200.

Returns the publicly visible attributes of an identity available to request approvers for Access Requests and Certification Campaigns.

## Update the public identities configuration

`PUT /public-identities-config/v1`

Success: 200.

Updates the publicly visible attributes of an identity available to request approvers for Access Requests and Certification Campaigns.

Body:

```json
{
  "attributes": [
    {
      "key": "country",
      "name": "Country"
    },
    {
      "key": "country",
      "name": "Country"
    }
  ],
  "modified": "2018-06-25T20:22:28.104Z",
  "modifiedBy": {
    "type": "IDENTITY",
    "id": "2c9180a46faadee4016fb4e018c20639",
    "name": "Thomas Edison"
  }
}
```
