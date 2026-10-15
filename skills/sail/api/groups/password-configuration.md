# Password Configuration

Use this API to implement organization password configuration functionality.

3 endpoints. Paths are relative to the environment API host.

## Get password org config

`GET /password-org-config/v1`

Success: 200.

This API returns the password org config . Requires ORG_ADMIN, API role or authorization scope of 'idn:password-org-config:read'

## Update password org config

`PUT /password-org-config/v1`

Success: 200.

This API updates the password org config for specified fields. Other fields will keep original value.
You must set the `customInstructionsEnabled` field to "true" to be able to use custom password instructions.
Requires ORG_ADMIN, API role or authorization scope of 'idn:password-org-config:write'

Body:

```json
{
  "digitTokenEnabled": true,
  "digitTokenDurationMinutes": 12
}
```

## Create password org config

`POST /password-org-config/v1`

Success: 200.

This API creates the password org config. Unspecified fields will use default value.
To be able to use the custom password instructions, you must set the `customInstructionsEnabled` field to "true".
Requires ORG_ADMIN, API role or authorization scope of 'idn:password-org-config:write'

Body:

```json
{
  "customInstructionsEnabled": true,
  "digitTokenEnabled": true,
  "digitTokenDurationMinutes": 12,
  "digitTokenLength": 9
}
```
