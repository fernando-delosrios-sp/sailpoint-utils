Identity Now | SailPoint Entro DocsFor the complete documentation index, see [llms.txt](https://docs.entro.security/llms.txt). This page is also available as [Markdown](https://docs.entro.security/api-reference/identity-now.md).GitBook AssistantAskOn this page

Manage and query NHI data for Sailpoint Identity Now
GitBook Assistant
### Get All the NHIs formatted for Identity Now[#get-v1-identity-now-nhi](#get-v1-identity-now-nhi)
gethttps://api.entro.security/v1/identity-now/nhiAuthorizationsApi-KeyAuthorizationstringRequiredQuery parametersaccountTypestring · enumOptional

Filter for NHIs with specified account type
Possible values: `GITHUB``AWS``AZURE``GCP``OKTA`takeintegerOptional

The maximum number of NHIs to return in the response. Can't be over 100
Default: `100`skipintegerOptional

The offset to use for pagination
Default: `0`Responses200

Successful response
application/jsonget/v1/identity-now/nhiHTTPGitBook AssistantAskCopy
```
GET /v1/identity-now/nhi HTTP/1.1
Host: api.entro.security
Authorization: <redacted>
Accept: */*

```
Test it200

Successful response
GitBook AssistantAskCopy
```
{
  "items": [
    {
      "attributes": {
        "entroUniqueIdentifier": "TKN-4242",
        "nhiName": "data-science-platform-manager",
        "sourceSystem": "AWS",
        "account": "156949362959",
        "environment": "DEVELOPMENT",
        "token": "AKIARWGDZ7FZHKQZ332",
        "nhiType": "AWS IAM Access Key",
        "nhiStatus": "Active",
        "tags": [
          "aws-bot",
          "lab-test"
        ],
        "createdDate": "2024-03-26T09:58:49.047Z",
        "expirationDate": "2024-06-24T08:58:49.047Z",
        "isActive": true,
        "isAdmin": false,
        "owner": "Eyal Neemany",
        "ownerEmail": "Eyal.Neemany@entro.security",
        "lastActivityDate": null,
        "policies": {
          "delegated": [],
          "application": []
        },
        "url": "https://us-east-1.console.aws.amazon.com/iam/home?region=us-east-1#/users/details/data-science-platform-manager?section=permissions"
      }
    }
  ],
  "hasNext": true,
  "nextSkipOffset": 1,
  "totalCount": 1
}
```
[PreviousIntegrations](/api-reference/integrations)

Last updated 9 months ago
