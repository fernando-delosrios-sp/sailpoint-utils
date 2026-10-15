# Password Policies

Use these APIs to implement password policies functionality.

5 endpoints. Paths are relative to the environment API host.

## Get password policy by id

`GET /password-policies/v1/:id`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 200.

This API returns the password policy for the specified ID.

## Update password policy by id

`PUT /password-policies/v1/:id`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 200.

This API updates the specified password policy.

Body:

```json
{
  "description": "Password Policy after update.",
  "id": "2c91808e7d976f3b017d9f5ceae440c8",
  "name": "Improved Password Policy",
  "dateCreated": 1639056206564,
  "lastUpdated": 1662385430753,
  "firstExpirationReminder": 90,
  "accountIdMinWordLength": 3,
  "accountNameMinWordLength": 3,
  "maxLength": 0,
  "maxRepeatedChars": 4,
  "minAlpha": 1,
  "minCharacterTypes": -1,
  "minLength": 8,
  "minLower": 0,
  "minNumeric": 1,
  "minSpecial": 0,
  "minUpper": 0,
  "passwordExpiration": 90,
  "defaultPolicy": false,
  "enablePasswdExpiration": false,
  "requireStrongAuthn": false,
  "requireStrongAuthOffNetwork": false,
  "requireStrongAuthUntrustedGeographies": false,
  "useAccountAttributes": false,
  "useDictionary": false,
  "useIdentityAttributes": false,
  "validateAgainstAccountId": true,
  "validateAgainstAccountName": true,
  "sourceIds": [
    "2c91808382ffee0b01830de154f14034",
    "2c91808582ffee0c01830de36511405f"
  ]
}
```

## Delete password policy by id

`DELETE /password-policies/v1/:id`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 204.

This API deletes the specified password policy.

## Create password policy

`POST /password-policies/v1`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 200.

This API creates the specified password policy.

Body:

```json
{
  "description": "New Password Policy with high requirements to password complexity.",
  "id": null,
  "name": "High security Password Policy",
  "dateCreated": 1639056206564,
  "lastUpdated": 1662385430753,
  "firstExpirationReminder": 90,
  "accountIdMinWordLength": 3,
  "accountNameMinWordLength": 3,
  "maxLength": 0,
  "maxRepeatedChars": 4,
  "minAlpha": 1,
  "minCharacterTypes": -1,
  "minLength": 8,
  "minLower": 0,
  "minNumeric": 1,
  "minSpecial": 0,
  "minUpper": 0,
  "passwordExpiration": 90,
  "defaultPolicy": false,
  "enablePasswdExpiration": false,
  "requireStrongAuthn": false,
  "requireStrongAuthOffNetwork": false,
  "requireStrongAuthUntrustedGeographies": false,
  "useAccountAttributes": false,
  "useDictionary": false,
  "useIdentityAttributes": false,
  "validateAgainstAccountId": true,
  "validateAgainstAccountName": true,
  "sourceIds": [
    "2c91808382ffee0b01830de154f14034",
    "2c91808582ffee0c01830de36511405f"
  ]
}
```

## List password policies

`GET /password-policies/v1`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 200.

This gets list of all Password Policies.
Requires role of ORG_ADMIN

Query:

- standard: `limit`, `offset`, `count`
