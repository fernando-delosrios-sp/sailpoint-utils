# JIT Access

Use these APIs to configure JIT provisioning activation policy for the tenant.

2 endpoints. Paths are relative to the environment API host.

## Get JIT activation policy configuration

`GET /jit-activation-config/v1/:configType`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 200.

Returns the tenant's current JIT activation policy configuration, including governed entitlement IDs, activation and extension time limits, default periods, notification settings, and whether the policy applies to future assignments.

The tenant comes from the authenticated request context (not the URL). Use **configType** to select which configuration to read. Returns **404** if that configuration has not been stored yet.

**User level:** POLICY_ADMIN (policy administrator).

## Update JIT activation policy configuration

`PATCH /jit-activation-config/v1/:configType`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 200.

Updates the tenant's JIT activation policy configuration by applying one or more **replace** operations (same shape as JSON Patch: **op**, **path**, **value**). Use this to change entitlement lists, max/default activation and extension durations, notification recipients or template, and the apply-to-future-assignments flag.

The body must be a non-empty array. Only **replace** is supported; each **path** must be one of the values documented on the request item schema. The tenant is taken from the request context. **configType** selects which configuration to update. Returns **404** if the configuration does not exist, or **400** for an empty body, unknown **configType**, or invalid path/value.

**User level:** POLICY_ADMIN (policy administrator).

Body:

```json
[
  {
    "path": "/maxActivationPeriodMins",
    "value": [
      "2c9180837dfe6949017e208e25967b22"
    ],
    "op": "replace"
  }
]
```
