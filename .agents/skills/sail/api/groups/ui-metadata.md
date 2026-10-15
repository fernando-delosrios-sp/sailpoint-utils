# UI Metadata

API for managing UI Metadata. Use this API to manage metadata about your User Interface.

2 endpoints. Paths are relative to the environment API host.

## Get a tenant ui metadata

`GET /ui-metadata/v1/tenant`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 200.

This API endpoint retrieves UI metadata configured for your tenant.

## Update tenant ui metadata

`PUT /ui-metadata/v1/tenant`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 200.

This API endpoint updates UI metadata for your tenant. These changes may require up to 5 minutes to take effect on the UI.

Body:

```json
{
  "iframeWhiteList": "http://example.com http://example2.com",
  "usernameLabel": "Email",
  "usernameEmptyText": "Please provide your work email address...",
  "instanceBadgeDisplayName": "Sandbox",
  "instanceBadgeColor": "FFAA00",
  "instanceBadgeVisible": true
}
```
