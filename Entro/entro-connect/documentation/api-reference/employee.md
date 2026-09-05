Employee | SailPoint Entro DocsFor the complete documentation index, see [llms.txt](https://docs.entro.security/llms.txt). This page is also available as [Markdown](https://docs.entro.security/api-reference/employee.md).GitBook AssistantAskOn this page

Query human employee data
GitBook Assistant
### List Employee[#get-v1-employees](#get-v1-employees)
gethttps://api.entro.security/v1/employeesAuthorizationsApi-KeyAuthorizationstringRequiredQuery parameterslimitintegerOptional

The maximum number of employees to return in the response. Can't be over 10000
Default: `1000`skipintegerOptional

The number of employees to skip before selecting data.
Default: `0`statusstringOptional

Employee status
divisionstringOptional

Employee division
organizationstringOptional

Employee organization
employeeTypestring · enumOptional

Employee type
Possible values: `HUMAN``APP``UNKNOWN`azureEmployeeTypestringOptional

Employee Azure type
Responses200

Successful response
application/jsonget/v1/employeesHTTPGitBook AssistantAskCopy
```
GET /v1/employees HTTP/1.1
Host: api.entro.security
Authorization: <redacted>
Accept: */*

```
Test it200

Successful response
GitBook AssistantAskCopy
```
{
  "employees": [
    {
      "fullName": "Adam Cheriki",
      "status": "ACTIVE",
      "division": "CTO",
      "organization": "Entro",
      "manager": null,
      "phone": null,
      "aliases": [
        "adam@entro.security"
      ],
      "ownerUid": "3213ea55-a05d-48b9-8330-ad684b0a6692",
      "email": "adam.cheriki@entro.security",
      "accounts": "[\"120798482511\",\"adam-testing-3\"]",
      "title": "Co-founder and Chief Technology Officer",
      "creationDate": "2023-06-07T07:51:20.000Z",
      "lastLogin": null,
      "idpSources": [
        "OKTA"
      ],
      "employeeType": "HUMAN",
      "azureEmployeeType": "Member"
    }
  ]
}
```

### Get NHIs by employee[#get-v1-employee-employee_email-nhis](#get-v1-employee-employee_email-nhis)
gethttps://api.entro.security/v1/employee/{EMPLOYEE_EMAIL}/nhisAuthorizationsApi-KeyAuthorizationstringRequiredPath parametersEMPLOYEE_EMAILstringRequired

The employee email or alias.
Query parametersskipintegerOptional

The number of NHIs to skip before selecting data.
Default: `0`limitintegerOptional

The maximum number of NHIs to return in the response. Can't be over 100
Default: `100`accountstringOptional

Filter for NHIs from specified account id
statusstringOptional

Filter for NHIs with specified status
identityTypestringOptional

Filter for NHIs with specified identity type
Responses200

Successful response
application/jsonget/v1/employee/{EMPLOYEE_EMAIL}/nhisHTTPGitBook AssistantAskCopy
```
GET /v1/employee/{EMPLOYEE_EMAIL}/nhis HTTP/1.1
Host: api.entro.security
Authorization: <redacted>
Accept: */*

```
Test it200

Successful response
GitBook AssistantAskCopy
```
{
  "employeeEmail": "employee@acme.com",
  "employeeAliases": [
    "employee@acme.co.uk"
  ],
  "employeeName": "Employee McEmployee",
  "isFormerEmployee": true,
  "nhis": [
    {
      "tokenId": "ABC123DEF456",
      "accountId": "github account id",
      "status": "Active",
      "accessedDate": "2024-01-01T16:12:42Z",
      "rotationDate": "2023-12-01T16:12:42Z",
      "identity": "DevUser",
      "identityType": "AWS Role"
    }
  ]
}
```

### Get Exposed Secrets by employee[#get-v1-employee-employee_email-exposedsecrets](#get-v1-employee-employee_email-exposedsecrets)
gethttps://api.entro.security/v1/employee/{EMPLOYEE_EMAIL}/exposedSecretsAuthorizationsApi-KeyAuthorizationstringRequiredPath parametersEMPLOYEE_EMAILstringRequired

The employee email or alias.
Query parametersskipintegerOptional

The number of Exposed Secrets to skip before selecting data.
Default: `0`limitintegerOptional

The maximum number of Exposed Secrets to return in the response. Can't be over 100
Default: `100`accountstringOptional

Filter for Exposed Secrets from specified account id
statusstring · enumOptional

Filter for Exposed Secrets with specified status
Possible values: `INVALID``ENABLED``DISABLED``UNSUPPORTED``UNREACHABLE``REVOKED`severitystring · enumOptional

Filter for Exposed Secrets with specified risk severity
Possible values: `UNKNOWN``LOW``MEDIUM``HIGH``CRITICAL`exposedAtstring · enumOptional

Filter for Exposed Secrets with specified exposed at location.
Possible values: `AWS_LAMBDA``GCP_FUNCTION``BITBUCKET_REPO_COMMIT``AZURE_FUNCTION_APP``AZURE_DEV_OPS_WIKI_PAGE``AZURE_APP_CONFIGURATION``GITHUB_REPO_COMMIT``AWS_PARAMETER_STORE``CONFLUENCE``SLACK_CHANNEL``JIRA``MICROSOFT_TEAMS_CHANNEL``AZURE_DEV_OPS_COMMIT``GITHUB_ACTIONS_WORKFLOWS_LOG``GITLAB_REPO_COMMIT``FILES_SHARING_SMB``SHAREPOINT``GITHUB_PULL_REQUEST``GITHUB_PULL_REQUEST_COMMENT``BUILDKITE_BUILD_LOGS`Responses200

Successful response
application/jsonget/v1/employee/{EMPLOYEE_EMAIL}/exposedSecretsHTTPGitBook AssistantAskCopy
```
GET /v1/employee/{EMPLOYEE_EMAIL}/exposedSecrets HTTP/1.1
Host: api.entro.security
Authorization: <redacted>
Accept: */*

```
Test it200

Successful response
GitBook AssistantAskCopy
```
{
  "employeeEmail": "employee@acme.com",
  "employeeAliases": [
    "employee@acme.co.uk"
  ],
  "employeeName": "Employee McEmployee",
  "isFormerEmployee": true,
  "exposedSecrets": [
    {
      "exposedType": "GITHUB_TOKEN",
      "exposedAt": "GITHUB_PULL_REQUEST",
      "accountId": "github account id",
      "status": "ENABLED",
      "severity": "LOW",
      "exposurePath": "config/app.yml",
      "secretSnippet": "Password=1"
    }
  ]
}
```
[PreviousUtils](/api-reference/utils)[NextConnectors](/api-reference/connectors)

Last updated 9 months ago

- [getList Employee](#get-v1-employees)
- [getGet NHIs by employee](#get-v1-employee-employee_email-nhis)
- [getGet Exposed Secrets by employee](#get-v1-employee-employee_email-exposedsecrets)
