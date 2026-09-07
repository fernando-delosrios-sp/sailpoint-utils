Exposed Secret | SailPoint Entro DocsFor the complete documentation index, see [llms.txt](https://docs.entro.security/llms.txt). This page is also available as [Markdown](https://docs.entro.security/api-reference/exposed-secret.md).GitBook AssistantAskOn this page

Query and Manage your exposed secrets
GitBook Assistant
### List exposed secrets[#get-v1-exposed-secrets](#get-v1-exposed-secrets)
gethttps://api.entro.security/v1/exposed-secretsAuthorizationsApi-KeyAuthorizationstringRequiredQuery parametersskipintegerOptional

The number of exposed secrets to skip before selecting data.
limitinteger · min: 1 · max: 50Optional

The maximum number of exposed secrets to return in the response.
Default: `50`fromDatestringOptional

Filter risks creation dates, by using the following filter example: "?fromDate=10-22-2023"
Pattern: `^(0[1-9]|1[0-2])-(0[1-9]|[1-2][0-9]|3[0-1])-[0-9]{4}$`isGenericbooleanOptional

Filter for exposed secrets of type generic
isArchivedbooleanOptional

Filter for archived exposed secrets
Default: `false`severitystring · enumOptional

Filter for exposed secrets with specified severities
Possible values: `UNKNOWN``LOW``MEDIUM``HIGH``CRITICAL`statusstring · enumOptional

Filter for exposed secrets with specified status
Possible values: `INVALID``ENABLED``DISABLED``UNSUPPORTED``UNREACHABLE``REVOKED`sourcestringOptional

Filter for exposed secrets with specified source
accountstringOptional

Filter for exposed secrets with specified account id
typestringOptional

Filter for exposed secrets with specified type
publicExposurebooleanOptional

Filter for pubiclly exposed secrets
commitsstringOptional

One or more (max 10) Git commit SHAs to filter exposed secrets by. Use a single SHA or provide multiple SHAs separated by commas (e.g., 'commits=34567d343755bd123f82051681e206da99b400bb,34567d343755bd123f82051681e206da99b40012') to find exposed secrets associated with specific commits.
Responses200

Successful response
application/jsonget/v1/exposed-secretsHTTPGitBook AssistantAskCopy
```
GET /v1/exposed-secrets HTTP/1.1
Host: api.entro.security
Authorization: <redacted>
Accept: */*

```
Test it200

Successful response
GitBook AssistantAskCopy
```
{
  "exposedSecrets": [
    {
      "exposedId": "EXP-1",
      "severity": "HIGH",
      "status": "ENABLED",
      "exposureUrl": "https://example.com",
      "isGeneric": false,
      "keyId": "keyid",
      "secretValue": "secretvalue",
      "location": "lambda123",
      "locationType": "AWS_LAMBDA",
      "owner": "owner123",
      "path": "path123",
      "type": "AWS_ACCESS_KEY",
      "snippet": "snippet123",
      "tags": [
        "tag1",
        "tag2"
      ],
      "targetAccount": "target123",
      "vendorHash": "vendorhash123",
      "occurrences": [
        "EXP-123",
        "EXP-456"
      ],
      "account": {
        "id": "acc123",
        "type": "AWS",
        "environment": "prod",
        "environmentType": "DEVELOPMENT",
        "tags": [
          "tag1",
          "tag2"
        ]
      },
      "employee": {
        "name": "John Doe",
        "email": "john@example.com"
      },
      "redactedSecret": "***secret***",
      "hash": "hash123",
      "isPublic": true
    }
  ]
}
```

### Adds or removes an exposed secret hash from the blacklist to prevent it from being displayed in the system[#patch-v1-exposed-secret-exp_guid-blacklist](#patch-v1-exposed-secret-exp_guid-blacklist)
patchhttps://api.entro.security/v1/exposed-secret/{EXP_GUID}/blacklistAuthorizationsApi-KeyAuthorizationstringRequiredPath parametersEXP_GUIDstringRequired

The exposed secret guid
Pattern: `^EXP-\d+$`Query parametersactionstring · enumRequired

Determines the operation
Possible values: `add``remove`entroUserstringOptional

The identifier of the user performing the action
Responses200

Successful response
application/jsonpatch/v1/exposed-secret/{EXP_GUID}/blacklistHTTPGitBook AssistantAskCopy
```
PATCH /v1/exposed-secret/{EXP_GUID}/blacklist?action=add HTTP/1.1
Host: api.entro.security
Authorization: <redacted>
Accept: */*

```
Test it200

Successful response
GitBook AssistantAskCopy
```
{
  "message": "Number of exposed secrets that have been added/removed to the blacklist: [NUMBER]"
}
```

### Adds or removes an exposed secret hash from the whitelist to mark the secret as a true one[#patch-v1-exposed-secret-exp_guid-whitelist](#patch-v1-exposed-secret-exp_guid-whitelist)
patchhttps://api.entro.security/v1/exposed-secret/{EXP_GUID}/whitelistAuthorizationsApi-KeyAuthorizationstringRequiredPath parametersEXP_GUIDstringRequired

The exposed secret guid
Pattern: `^EXP-\d+$`Query parametersactionstring · enumRequired

Determines the operation
Possible values: `add``remove`Responses200

Successful response
application/jsonpatch/v1/exposed-secret/{EXP_GUID}/whitelistHTTPGitBook AssistantAskCopy
```
PATCH /v1/exposed-secret/{EXP_GUID}/whitelist?action=add HTTP/1.1
Host: api.entro.security
Authorization: <redacted>
Accept: */*

```
Test it200

Successful response
GitBook AssistantAskCopy
```
{
  "message": "Number of exposed secrets that have been added/removed to the whitelist: [NUMBER]"
}
```
[PreviousRisk](/api-reference/risk)[NextScanner](/api-reference/scanner)

Last updated 9 months ago

- [getList exposed secrets](#get-v1-exposed-secrets)
- [patchAdds or removes an exposed secret hash from the blacklist to prevent it from being displayed in the system](#patch-v1-exposed-secret-exp_guid-blacklist)
- [patchAdds or removes an exposed secret hash from the whitelist to mark the secret as a true one](#patch-v1-exposed-secret-exp_guid-whitelist)
