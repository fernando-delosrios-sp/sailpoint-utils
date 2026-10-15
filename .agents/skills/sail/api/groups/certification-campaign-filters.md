# Certification Campaign Filters

Use this API to implement the certification campaign filter functionality.

5 endpoints. Paths are relative to the environment API host.

## Create campaign filter

`POST /campaign-filters/v1`

Success: 200.

Use this API to create a campaign filter based on filter details and criteria.

Body:

```json
{
  "id": "5ec18cef39020d6fd7a60ad3970aba61",
  "name": "Identity Attribute Campaign Filter",
  "owner": "SailPoint Support",
  "mode": "INCLUSION",
  "isSystemFilter": false,
  "description": "Campaign filter to certify data based on an identity attribute's specified property.",
  "criteriaList": [
    {
      "type": "IDENTITY_ATTRIBUTE",
      "property": "displayName",
      "value": "Allie",
      "operation": "EQUALS",
      "negateResult": false,
      "shortCircuit": false,
      "recordChildMatches": false,
      "id": "5ec18cef39020d6fd7a60ad3970aba61",
      "suppressMatchedItems": false
    },
    {
      "type": "IDENTITY_ATTRIBUTE",
      "property": "displayName",
      "value": "Allie",
      "operation": "EQUALS",
      "negateResult": false,
      "shortCircuit": false,
      "recordChildMatches": false,
      "id": "5ec18cef39020d6fd7a60ad3970aba61",
      "suppressMatchedItems": false
    }
  ]
}
```

## List campaign filters

`GET /campaign-filters/v1`

Success: 200.

Use this API to list all campaign filters. You can reduce scope with standard V3 query parameters.

Query:

- standard: `limit`
- `start`: Start/Offset into the full result set. Usually specified with *limit* to paginate through the results. See V3 API Standard Collection Parameters for more information.
- `includeSystemFilters`: If this is true, the API includes system filters in the count and results. Otherwise it excludes them. If no value is provided, the default is true.

## Get campaign filter by id

`GET /campaign-filters/v1/:id`

Success: 200.

Retrieves information for an existing campaign filter using the filter's ID.

## Updates a campaign filter

`POST /campaign-filters/v1/:id`

Success: 200.

Updates an existing campaign filter using the filter's ID.

Body:

```json
{
  "id": "5ec18cef39020d6fd7a60ad3970aba61",
  "name": "Identity Attribute Campaign Filter",
  "owner": "SailPoint Support",
  "mode": "INCLUSION",
  "isSystemFilter": false,
  "description": "Campaign filter to certify data based on an identity attribute's specified property.",
  "criteriaList": [
    {
      "type": "IDENTITY_ATTRIBUTE",
      "property": "displayName",
      "value": "Allie",
      "operation": "EQUALS",
      "negateResult": false,
      "shortCircuit": false,
      "recordChildMatches": false,
      "id": "5ec18cef39020d6fd7a60ad3970aba61",
      "suppressMatchedItems": false
    },
    {
      "type": "IDENTITY_ATTRIBUTE",
      "property": "displayName",
      "value": "Allie",
      "operation": "EQUALS",
      "negateResult": false,
      "shortCircuit": false,
      "recordChildMatches": false,
      "id": "5ec18cef39020d6fd7a60ad3970aba61",
      "suppressMatchedItems": false
    }
  ]
}
```

## Deletes campaign filters

`POST /campaign-filters/v1/delete`

Success: 204.

Deletes campaign filters whose Ids are specified in the provided list of campaign filter Ids. Authorized callers must be an ORG_ADMIN or a CERT_ADMIN.

Body:

```json
[
  "0fbe863c063c4c88a35fd7f17e8a3df5",
  "2efb374d392c4d88a34sv7b11e8a4eq6"
]
```
