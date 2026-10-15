# Global Tenant Security Settings

Use this API to implement and customize global tenant security settings.

9 endpoints. Paths are relative to the environment API host.

## Get security network configuration.

`GET /auth-org/v1/network-config`

Success: 200.

This API returns the details of an org's network auth configuration.

## Create security network configuration.

`POST /auth-org/v1/network-config`

Success: 200.

This API returns the details of an org's network auth configuration. Requires security scope of: 'sp:auth-org:manage'

Body:

```json
{
  "range": [
    "1.3.7.2",
    "255.255.255.252/30"
  ],
  "geolocation": [
    "CA",
    "FR",
    "HT"
  ],
  "whitelisted": true
}
```

## Update security network configuration.

`PATCH /auth-org/v1/network-config`

Success: 200.

This API updates an existing network configuration for an org using PATCH
 Requires security scope of:  'sp:auth-org:manage'

Body:

```json
[
  {
    "op": "replace",
    "path": "/whitelisted",
    "value": "false,"
  },
  {
    "op": "add",
    "path": "/geolocation",
    "value": [
      "AF",
      "HN",
      "ES"
    ]
  }
]
```

## Get auth org lockout configuration.

`GET /auth-org/v1/lockout-config`

Success: 200.

This API returns the details of an org's lockout auth configuration.

## Update auth org lockout configuration

`PATCH /auth-org/v1/lockout-config`

Success: 200.

This API updates an existing lockout configuration for an org using PATCH

Body:

```json
[
  {
    "op": "replace",
    "path": "/maximumAttempts",
    "value": "7,"
  },
  {
    "op": "add",
    "path": "/lockoutDuration",
    "value": 35
  }
]
```

## Get service provider configuration.

`GET /auth-org/v1/service-provider-config`

Success: 200.

This API returns the details of an org's service provider auth configuration.

## Update service provider configuration

`PATCH /auth-org/v1/service-provider-config`

Success: 200.

This API updates an existing service provider configuration for an org using PATCH.

Body:

```json
[
  {
    "op": "replace",
    "path": "/enabled",
    "value": "true,"
  },
  {
    "op": "add",
    "path": "/federationProtocolDetails/0/jitConfiguration",
    "value": {
      "enabled": true,
      "sourceId": "2c9180857377ed2901739c12a2da5ac8",
      "sourceAttributeMappings": {
        "firstName": "okta.firstName",
        "lastName": "okta.lastName",
        "email": "okta.email",
        "employeeNumber": "okta.employeeNumber"
      }
    }
  }
]
```

## Get auth org session configuration.

`GET /auth-org/v1/session-config`

Success: 200.

This API returns the details of an org's session auth configuration.

## Update auth org session configuration

`PATCH /auth-org/v1/session-config`

Success: 200.

This API updates an existing session configuration for an org using PATCH.

Body:

```json
[
  {
    "op": "replace",
    "path": "/rememberMe",
    "value": "true,"
  },
  {
    "op": "add",
    "path": "/maxSessionTime",
    "value": 480
  }
]
```
