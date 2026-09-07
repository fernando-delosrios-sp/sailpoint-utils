Risk | SailPoint Entro DocsFor the complete documentation index, see [llms.txt](https://docs.entro.security/llms.txt). This page is also available as [Markdown](https://docs.entro.security/api-reference/risk.md).GitBook AssistantAskOn this page

Query and Manage your risks
GitBook Assistant
### Retrieve risk details[#get-v1-risk-risk_guid](#get-v1-risk-risk_guid)
gethttps://api.entro.security/v1/risk/{RISK_GUID}AuthorizationsApi-KeyAuthorizationstringRequiredPath parametersRISK_GUIDstringRequiredQuery parametersenableEnrichmentbooleanOptional

Flag to enable enrichment in the response
Responses200

Successful response
application/jsonget/v1/risk/{RISK_GUID}HTTPGitBook AssistantAskCopy
```
GET /v1/risk/{RISK_GUID} HTTP/1.1
Host: api.entro.security
Authorization: <redacted>
Accept: */*

```
Test it200

Successful response
GitBook AssistantAskCopy
```
{
  "guid": "RSK-1273",
  "severity": "MEDIUM",
  "owner": "adam.cheriki@acme.com",
  "detectionTime": "1688302174",
  "type": "EXPOSURE",
  "rule": "EXPOSED_GITHUB",
  "status": "OPEN",
  "summary": "A secret of type Certificate is exposed inside 1 commit of the file 'exposure.cert' in the private GitHub repository called 'acme/test'.",
  "threatDescription": "Storing secrets in a GitHub repository poses a serious security risk because it's often shared with multiple team members, or in some cases, publicly, which increases the risk of the sensitive information being leaked or misused.",
  "payload": {
    "tokenStatus": "ENABLED",
    "tokenType": "CERTIFICATE",
    "tokenSnippet": "----- BEGIN CERT...",
    "organization": "acme",
    "repository": "test",
    "visibility": "PUBLIC",
    "filename": "exposure.cert",
    "commitAuthor": "adam.cheriki",
    "commitUrl": "https://github.com/acme/test/commit/34567d343755bd123f82051681e206da99b400bb",
    "commitDate": "2022-12-01T16:12:42Z"
  },
  "account": {
    "environmentType": "PRODUCTION",
    "environment": "Acme",
    "accountId": "infosecmachine",
    "accountType": "GITHUB"
  }
}
```

### Get risk status[#get-v1-risk-risk_guid-status](#get-v1-risk-risk_guid-status)
gethttps://api.entro.security/v1/risk/{RISK_GUID}/statusAuthorizationsApi-KeyAuthorizationstringRequiredPath parametersRISK_GUIDstringRequiredResponses200

Successful response
application/jsonget/v1/risk/{RISK_GUID}/statusHTTPGitBook AssistantAskCopy
```
GET /v1/risk/{RISK_GUID}/status HTTP/1.1
Host: api.entro.security
Authorization: <redacted>
Accept: */*

```
Test it200

Successful response
GitBook AssistantAskCopy
```
{
  "status": "IN_PROGRESS",
  "entroUser": "adam.cheriki@acme.com",
  "comment": "Working on it"
}
```

### Update risk status[#post-v1-risk-risk_guid-status](#post-v1-risk-risk_guid-status)
posthttps://api.entro.security/v1/risk/{RISK_GUID}/statusAuthorizationsApi-KeyAuthorizationstringRequiredPath parametersRISK_GUIDstringRequiredBodyapplication/jsonanyOptionalResponses204

Successful update

```

No content

```
post/v1/risk/{RISK_GUID}/statusHTTPGitBook AssistantAskCopy
```
POST /v1/risk/{RISK_GUID}/status HTTP/1.1
Host: api.entro.security
Authorization: <redacted>
Content-Type: application/json
Accept: */*
Content-Length: 50

{
  "status": "IN_PROGRESS",
  "comment": "Working on it"
}
```
Test it204

Successful update

```

No content

```

### Get risk owner[#get-v1-risk-risk_guid-owner](#get-v1-risk-risk_guid-owner)
gethttps://api.entro.security/v1/risk/{RISK_GUID}/ownerAuthorizationsApi-KeyAuthorizationstringRequiredPath parametersRISK_GUIDstringRequiredResponses200

Successful response
application/jsonget/v1/risk/{RISK_GUID}/ownerHTTPGitBook AssistantAskCopy
```
GET /v1/risk/{RISK_GUID}/owner HTTP/1.1
Host: api.entro.security
Authorization: <redacted>
Accept: */*

```
Test it200

Successful response
GitBook AssistantAskCopy
```
{
  "businessOwner": "eyal.neemany@acme.com",
  "entroUser": "adam.cheriki@acme.com",
  "comment": "He is the actual business owner of this risk"
}
```

### Update risk owner[#post-v1-risk-risk_guid-owner](#post-v1-risk-risk_guid-owner)
posthttps://api.entro.security/v1/risk/{RISK_GUID}/ownerAuthorizationsApi-KeyAuthorizationstringRequiredPath parametersRISK_GUIDstringRequiredBodyapplication/jsonanyOptionalResponses204

Successful update

```

No content

```
post/v1/risk/{RISK_GUID}/ownerHTTPGitBook AssistantAskCopy
```
POST /v1/risk/{RISK_GUID}/owner HTTP/1.1
Host: api.entro.security
Authorization: <redacted>
Content-Type: application/json
Accept: */*
Content-Length: 98

{
  "businessOwner": "eyal.neemany@acme.com",
  "comment": "He is the actual business owner of this risk"
}
```
Test it204

Successful update

```

No content

```

### Get risk comments[#get-v1-risk-risk_guid-comment](#get-v1-risk-risk_guid-comment)
gethttps://api.entro.security/v1/risk/{RISK_GUID}/commentAuthorizationsApi-KeyAuthorizationstringRequiredPath parametersRISK_GUIDstringRequiredResponses200

Successful response
application/jsonget/v1/risk/{RISK_GUID}/commentHTTPGitBook AssistantAskCopy
```
GET /v1/risk/{RISK_GUID}/comment HTTP/1.1
Host: api.entro.security
Authorization: <redacted>
Accept: */*

```
Test it200

Successful response
GitBook AssistantAskCopy
```
{
  "entroUser": "adam.cheriki@acme.com",
  "comment": "He is the actual business owner of this risk"
}
```

### Add risk comment[#post-v1-risk-risk_guid-comment](#post-v1-risk-risk_guid-comment)
posthttps://api.entro.security/v1/risk/{RISK_GUID}/commentAuthorizationsApi-KeyAuthorizationstringRequiredPath parametersRISK_GUIDstringRequiredBodyapplication/jsonanyOptionalResponses204

Successful update

```

No content

```
post/v1/risk/{RISK_GUID}/commentHTTPGitBook AssistantAskCopy
```
POST /v1/risk/{RISK_GUID}/comment HTTP/1.1
Host: api.entro.security
Authorization: <redacted>
Content-Type: application/json
Accept: */*
Content-Length: 94

{
  "entroUser": "adam.cheriki@acme.com",
  "message": "He is the actual business owner of this risk"
}
```
Test it204

Successful update

```

No content

```
Deprecated
### Revalidate risk's exposed secret[#get-v1-risk-risk_guid-revalidate](#get-v1-risk-risk_guid-revalidate)
gethttps://api.entro.security/v1/risk/{RISK_GUID}/revalidateAuthorizationsApi-KeyAuthorizationstringRequiredPath parametersRISK_GUIDstringRequiredResponses200

Successful response
application/jsonget/v1/risk/{RISK_GUID}/revalidateHTTPGitBook AssistantAskCopy
```
GET /v1/risk/{RISK_GUID}/revalidate HTTP/1.1
Host: api.entro.security
Authorization: <redacted>
Accept: */*

```
Test it200

Successful response
GitBook AssistantAskCopy
```
{
  "status": "ENABLED",
  "isArchived": false
}
```

### Start process for risk revallidation[#post-v1-risk-risk_guid-revalidate](#post-v1-risk-risk_guid-revalidate)
posthttps://api.entro.security/v1/risk/{RISK_GUID}/revalidateAuthorizationsApi-KeyAuthorizationstringRequiredPath parametersRISK_GUIDstringRequiredResponses200

Successful response
application/jsonpost/v1/risk/{RISK_GUID}/revalidateHTTPGitBook AssistantAskCopy
```
POST /v1/risk/{RISK_GUID}/revalidate HTTP/1.1
Host: api.entro.security
Authorization: <redacted>
Accept: */*

```
Test it200

Successful response
GitBook AssistantAskCopy
```
{
  "trackingId": "05829995-fa2f-4712-b17f-47dc2165658d"
}
```

### Update risk severity[#post-v1-risk-risk_guid-severity](#post-v1-risk-risk_guid-severity)
posthttps://api.entro.security/v1/risk/{RISK_GUID}/severityAuthorizationsApi-KeyAuthorizationstringRequiredPath parametersRISK_GUIDstringRequiredBodyapplication/jsonseveritystring · enumRequiredPossible values: `LOW``MEDIUM``HIGH``CRITICAL`commentstringOptional

Optional comment when updating severity
Responses200

Risk severity updated successfully
application/jsonpost/v1/risk/{RISK_GUID}/severityHTTPGitBook AssistantAskCopy
```
POST /v1/risk/{RISK_GUID}/severity HTTP/1.1
Host: api.entro.security
Authorization: <redacted>
Content-Type: application/json
Accept: */*
Content-Length: 74

{
  "severity": "CRITICAL",
  "comment": "Investigated and confirmed as critical"
}
```
Test it200

Risk severity updated successfully
GitBook AssistantAskCopy
```
{
  "message": "Risk severity updated successfully"
}
```

### Check status of risk invalidation process[#get-v1-risk-risk_guid-revalidate-tracking_id-status](#get-v1-risk-risk_guid-revalidate-tracking_id-status)
gethttps://api.entro.security/v1/risk/{RISK_GUID}/revalidate/{TRACKING_ID}/statusAuthorizationsApi-KeyAuthorizationstringRequiredPath parametersRISK_GUIDstringRequiredTRACKING_IDstringRequiredResponses200

Successful response
application/json404

Not found/expired
application/jsonget/v1/risk/{RISK_GUID}/revalidate/{TRACKING_ID}/statusHTTPGitBook AssistantAskCopy
```
GET /v1/risk/{RISK_GUID}/revalidate/{TRACKING_ID}/status HTTP/1.1
Host: api.entro.security
Authorization: <redacted>
Accept: */*

```
Test it200

Successful response
GitBook AssistantAskCopy
```
{
  "processStatus": "DONE",
  "status": "ENABLED",
  "isArchived": false
}
```

### Get risk changelog[#get-v1-risk-risk_guid-changelog](#get-v1-risk-risk_guid-changelog)
gethttps://api.entro.security/v1/risk/{RISK_GUID}/changelogAuthorizationsApi-KeyAuthorizationstringRequiredPath parametersRISK_GUIDstringRequiredResponses200

Successful response
application/jsonget/v1/risk/{RISK_GUID}/changelogHTTPGitBook AssistantAskCopy
```
GET /v1/risk/{RISK_GUID}/changelog HTTP/1.1
Host: api.entro.security
Authorization: <redacted>
Accept: */*

```
Test it200

Successful response
GitBook AssistantAskCopy
```
{
  "changelog": [
    {
      "status": "IN_PROGRESS",
      "prevStatus": "OPEN",
      "entroUser": "adam.cheriki@acme.com",
      "entroUserType": "ENTRO_BOT,ENTRO_AUTO,API,HUMAN",
      "comment": "Working on it",
      "businessOwner": "",
      "date": "2023-08-24T10:30:00Z"
    }
  ]
}
```

### List risks[#get-v1-risks](#get-v1-risks)
gethttps://api.entro.security/v1/risksAuthorizationsApi-KeyAuthorizationstringRequiredQuery parameterslimitintegerRequired

The maximum number of risks to return in the response.
Default: `50`skipintegerOptional

The number of risks to skip before selecting data.
severitystring · enumOptional

Severity of the risk
Possible values: `UNKNOWN``LOW``MEDIUM``HIGH``CRITICAL`riskStatusstring · enumOptional

Status of the risk
Possible values: `OPEN``IN_PROGRESS``DISCARDED``MITIGATED``APPROVED``RESOLVED`categorystring · enumOptional

Category of the risk. For complete list of risk categories, please use the /v1/utils/risk-category endpoint
Possible values: `CLOUD_SERVICE_RISKS``ABNORMAL_BEHAVIOR``MISCONFIGURATION``SECRET_HYGINE``EXPOSED_SECRET``LEAST_PRIVILEGE``MONITORING`sourcestringOptional

Source of the risk. For complete list of risk types, please use the /v1/utils/risk-source endpoint
secretTypestringOptional

Secret exposed of the Risk. For complete list of risk types, please use the /v1/utils/list/secret-type endpoint
fromDatestringOptional

Filter risks from this date (MM-DD-YYYY)
Pattern: `^(0[1-9]|1[0-2])-(0[1-9]|[1-2][0-9]|3[0-1])-[0-9]{4}$`fromModifyDatestringOptional

Filter risks from this modification date (MM-DD-YYYY)
Pattern: `^(0[1-9]|1[0-2])-(0[1-9]|[1-2][0-9]|3[0-1])-[0-9]{4}$`enableEnrichmentbooleanOptional

Flag to enable enrichment in the response
validitystring · enumOptional

Validity of the exposed secret (coexist only with ?category=EXPOSED_SECRET)
Possible values: `INVALID``ENABLED``DISABLED``UNSUPPORTED``UNREACHABLE``REVOKED`employeestringOptional

An employee of the risk. The exact full name or email of the employee required.
commitsstringOptional

One or more (max 10) Git commit SHAs to filter exposed secrets by. Use a single SHA or provide multiple SHAs separated by commas (e.g., 'commits=34567d343755bd123f82051681e206da99b400bb,34567d343755bd123f82051681e206da99b40012') to find risks associated with specific commits.
Responses200

Successful response
application/jsonget/v1/risksHTTPGitBook AssistantAskCopy
```
GET /v1/risks?limit=50 HTTP/1.1
Host: api.entro.security
Authorization: <redacted>
Accept: */*

```
Test it200

Successful response
GitBook AssistantAskCopy
```
{
  "risks": [
    {
      "guid": "RSK-1273",
      "severity": "MEDIUM",
      "owner": "adam.cheriki@acme.com",
      "detectionTime": "1688302174",
      "type": "EXPOSURE",
      "rule": "EXPOSED_GITHUB",
      "status": "OPEN",
      "summary": "A secret of type Certificate is exposed inside 1 commit of the file 'exposure.cert' in the private GitHub repository called 'acme/test'.",
      "threatDescription": "Storing secrets in a GitHub repository poses a serious security risk because it's often shared with multiple team members, or in some cases, publicly, which increases the risk of the sensitive information being leaked or misused.",
      "payload": {
        "tokenStatus": "ENABLED",
        "tokenType": "CERTIFICATE",
        "tokenSnippet": "----- BEGIN CERT...",
        "organization": "acme",
        "repository": "test",
        "visibility": "PUBLIC",
        "filename": "exposure.cert",
        "commitAuthor": "adam.cheriki",
        "commitUrl": "https://github.com/acme/test/commit/34567d343755bd123f82051681e206da99b400bb",
        "commitDate": "2022-12-01T16:12:42Z"
      },
      "account": {
        "environmentType": "PRODUCTION",
        "environment": "Acme",
        "accountId": "infosecmachine",
        "accountType": "GITHUB"
      }
    }
  ]
}
```

### List risks with query parameters[#get-v1-risks-query](#get-v1-risks-query)
gethttps://api.entro.security/v1/risks/queryAuthorizationsApi-KeyAuthorizationstringRequiredQuery parametersskipintegerOptional

The number of risks to skip before selecting data.
limitintegerOptional

The maximum number of risks to return in the response.
severitystringOptional

Filter for risks with specified severities, by executing this filter: "?severity=HIGH|CRITICAL". The complete list of risk severities can be retrieved via the /v1/risks endpoint
riskStatusstringOptional

Filter for risks with specified statuses, by executing this filter: "?riskStatus=OPEN|APPROVED". The complete list of risk types can be retrieved via the /v1/risk-type endpoint
categorystringOptional

Filter risks with specific secret category, OR condition example: "?category=EXPOSED_SECRET|ABNORMAL_BEHAVIOR". The complete list of supported secret categories can be retrieved via the /v1/utils/risk-category endpoint
sourcestringOptional

Filter risks with specific source, OR condition example: "?source=AWS_LAMBDA|@GITHUB@". You can use the ‘@@’ to look for partial secret source (contains operator). For complete list of risk types, please use the /v1/utils/risk-source endpoint
secretTypestringOptional

Filter risks with specific secret type, OR condition example: "?secretType=GCP_SERVICE_ACCOUNT_CREDS|@GITHUB@". You can use the ‘@@’ to look for partial secret type name (contains operator). The complete list of supported secret types can be retrieved via the /v1/secret-type endpoint
fromDatestringOptional

Filter risks creation dates, by using the following filter example: "?fromDate=10-22-2023"
Pattern: `^(0[1-9]|1[0-2])-(0[1-9]|[1-2][0-9]|3[0-1])-[0-9]{4}$`fromModifyDatestringOptional

Filter risks modification dates, by using the following filter example: "?fromModifyDate=10-22-2023"
Pattern: `^(0[1-9]|1[0-2])-(0[1-9]|[1-2][0-9]|3[0-1])-[0-9]{4}$`enableEnrichmentbooleanOptional

Flag to enable enrichment in the response
validitystring · enumOptional

Validity of the exposed secret (coexist only with ?category=EXPOSED_SECRET)
Possible values: `INVALID``ENABLED``DISABLED``UNSUPPORTED``UNREACHABLE``REVOKED`employeestringOptional

An employee of the risk. The exact full name or email of the employee required.
commitsstringOptional

One or more (max 10) Git commit SHAs to filter exposed secrets by. Use a single SHA or provide multiple SHAs separated by commas (e.g., 'commits=34567d343755bd123f82051681e206da99b400bb,34567d343755bd123f82051681e206da99b40012') to find risks associated with specific commits.
Responses200

Successful response
application/jsonget/v1/risks/queryHTTPGitBook AssistantAskCopy
```
GET /v1/risks/query HTTP/1.1
Host: api.entro.security
Authorization: <redacted>
Accept: */*

```
Test it200

Successful response
GitBook AssistantAskCopy
```
{
  "risks": [
    {
      "guid": "RSK-1273",
      "severity": "MEDIUM",
      "owner": "adam.cheriki@acme.com",
      "detectionTime": "1688302174",
      "type": "EXPOSURE",
      "rule": "EXPOSED_GITHUB",
      "status": "OPEN",
      "summary": "A secret of type Certificate is exposed inside 1 commit of the file 'exposure.cert' in the private GitHub repository called 'acme/test'.",
      "threatDescription": "Storing secrets in a GitHub repository poses a serious security risk because it's often shared with multiple team members, or in some cases, publicly, which increases the risk of the sensitive information being leaked or misused.",
      "payload": {
        "tokenStatus": "ENABLED",
        "tokenType": "CERTIFICATE",
        "tokenSnippet": "----- BEGIN CERT...",
        "organization": "acme",
        "repository": "test",
        "visibility": "PUBLIC",
        "filename": "exposure.cert",
        "commitAuthor": "adam.cheriki",
        "commitUrl": "https://github.com/acme/test/commit/34567d343755bd123f82051681e206da99b400bb",
        "commitDate": "2022-12-01T16:12:42Z"
      },
      "account": {
        "environmentType": "PRODUCTION",
        "environment": "Acme",
        "accountId": "infosecmachine",
        "accountType": "GITHUB"
      }
    }
  ]
}
```
[PreviousEntro API](/api-reference)[NextExposed Secret](/api-reference/exposed-secret)

Last updated 9 months ago

- [getRetrieve risk details](#get-v1-risk-risk_guid)
- [getGet risk status](#get-v1-risk-risk_guid-status)
- [postUpdate risk status](#post-v1-risk-risk_guid-status)
- [getGet risk owner](#get-v1-risk-risk_guid-owner)
- [postUpdate risk owner](#post-v1-risk-risk_guid-owner)
- [getGet risk comments](#get-v1-risk-risk_guid-comment)
- [postAdd risk comment](#post-v1-risk-risk_guid-comment)
- [getRevalidate risk's exposed secret](#get-v1-risk-risk_guid-revalidate)
- [postStart process for risk revallidation](#post-v1-risk-risk_guid-revalidate)
- [postUpdate risk severity](#post-v1-risk-risk_guid-severity)
- [getCheck status of risk invalidation process](#get-v1-risk-risk_guid-revalidate-tracking_id-status)
- [getGet risk changelog](#get-v1-risk-risk_guid-changelog)
- [getList risks](#get-v1-risks)
- [getList risks with query parameters](#get-v1-risks-query)
