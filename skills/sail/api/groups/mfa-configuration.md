# MFA Configuration

Configure and test multifactor authentication (MFA) methods

7 endpoints. Paths are relative to the environment API host.

## Configuration of okta mfa method

`GET /mfa/v1/okta-verify/config`

Success: 200.

This API returns the configuration of an Okta MFA method.

## Set okta mfa configuration

`PUT /mfa/v1/okta-verify/config`

Success: 200.

This API sets the configuration of an Okta MFA method.

Body:

```json
{
  "mfaMethod": "okta-verify",
  "enabled": true,
  "host": "www.example.com",
  "accessKey": "dk778Y3QlA5UqocYpdU3rEkzrK2D497y",
  "identityAttribute": "email"
}
```

## Configuration of duo mfa method

`GET /mfa/v1/duo-web/config`

Success: 200.

This API returns the configuration of an Duo MFA method.

## Set duo mfa configuration

`PUT /mfa/v1/duo-web/config`

Success: 200.

This API sets the configuration of an Duo MFA method.

Body:

```json
{
  "mfaMethod": "duo-web",
  "enabled": true,
  "host": "www.example.com",
  "accessKey": "qw123Y3QlA5UqocYpdU3rEkzrK2D497y",
  "identityAttribute": "email",
  "configProperties": {
    "skey": "12q3WERlcUHWJmiMqyCXI3uOF7EaDJTbdeOp6E2B",
    "ikey": "Q123WE45R6TY7890ZXCV"
  }
}
```

## Configuration of kba mfa method

`GET /mfa/v1/kba/config`

Success: 200.

This API returns the KBA configuration for MFA.

Query:

- `allLanguages`: Indicator whether the question text should be returned in all configured languages * If true, the question text is returned in all languages that it is configured in. * If false, the question text is returned in the user locale if…

## Set mfa kba configuration

`POST /mfa/v1/kba/config/answers`

Success: 200.

This API sets answers to challenge questions.  Any configured questions omitted from the request are removed from user KBA configuration.

Body:

```json
[
  {
    "id": "173423",
    "answer": "822cd15d6c15aa0c55ad015a3bf4f1b2b0b822cd15d6c15b0f00a0859a2fea34"
  },
  {
    "id": "c54fee53-2d63-4fc5-9259-3e93b9994135",
    "answer": "9f86d081884c7d659a2feaa0c55ad015a3bf4f1b2b0b822cd15d6c15b0f00a08"
  }
]
```

## Mfa method's test configuration

`GET /mfa/v1/:method/test`

Success: 200.

This API validates that the configuration is valid and will properly authenticate with the MFA provider identified by the method path parameter.
