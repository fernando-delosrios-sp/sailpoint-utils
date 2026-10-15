# IAI Access Request Recommendations

10 endpoints. Paths are relative to the environment API host.

## Identity access request recommendations

`GET /ai-access-request-recommendations/v1`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 200.

This API returns the access request recommendations for the specified identity. The default identity is *me* which indicates the current user.

Query:

- standard: `limit`, `offset`, `count`
- `identity-id`: Get access request recommendations for an identityId. *me* indicates the current user.
- `include-translation-messages`: If *true* it will populate a list of translation messages in the response.
- filters: access.name (co); access.type (eq, in); access.description (co, eq, in)
- sorters: access.name, access.type

## Get access request recommendations config

`GET /ai-access-request-recommendations/v1/config`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 200.

This API returns the configurations for Access Request Recommender for the tenant.

## Update access request recommendations config

`PUT /ai-access-request-recommendations/v1/config`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 200.

This API updates the configurations for Access Request Recommender for the tenant.

Body:

```json
{
  "scoreThreshold": 0.5,
  "startDateAttribute": "startDate",
  "restrictionAttribute": "location",
  "moverAttribute": "isMover",
  "joinerAttribute": "isJoiner",
  "useRestrictionAttribute": true
}
```

## Ignore access request recommendation

`POST /ai-access-request-recommendations/v1/ignored-items`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 201.

This API ignores a recommended access request item. Once an item is ignored, it will be marked as ignored=true if it is still a recommended item. The consumer can decide to hide ignored recommendations.

Body:

```json
{
  "identityId": "2c91808570313110017040b06f344ec9",
  "access": {
    "id": "2c9180835d2e5168015d32f890ca1581",
    "type": "ACCESS_PROFILE"
  }
}
```

## List ignored access request recommendations

`GET /ai-access-request-recommendations/v1/ignored-items`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 200.

This API returns the list of ignored access request recommendations.

Query:

- standard: `limit`, `offset`, `count`
- filters: access.id (eq, in); access.type (eq, in); identityId (eq, in)
- sorters: access.id, access.type, identityId, timestamp

## Accept access request recommendation

`POST /ai-access-request-recommendations/v1/requested-items`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 201.

This API consumes a notification that a recommended access request item was requested. This API does not actually make the request, it is just a notification. This will help provide feedback in order to improve our recommendations.

Body:

```json
{
  "identityId": "2c91808570313110017040b06f344ec9",
  "access": {
    "id": "2c9180835d2e5168015d32f890ca1581",
    "type": "ACCESS_PROFILE"
  }
}
```

## List accepted access request recommendations

`GET /ai-access-request-recommendations/v1/requested-items`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 200.

This API returns a list of requested access request recommendations.

Query:

- standard: `limit`, `offset`, `count`
- filters: access.id (eq, in); access.type (eq, in); identityId (eq, in)
- sorters: access.id, access.type, identityId, timestamp

## Mark viewed access request recommendations

`POST /ai-access-request-recommendations/v1/viewed-items`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 201.

This API consumes a notification that a recommended access request item was viewed. Future recommendations with this item will be marked with viewed=true. This can be useful for the consumer to determine if there are any new/unviewed recommendations.

Body:

```json
{
  "identityId": "2c91808570313110017040b06f344ec9",
  "access": {
    "id": "2c9180835d2e5168015d32f890ca1581",
    "type": "ACCESS_PROFILE"
  }
}
```

## List viewed access request recommendations

`GET /ai-access-request-recommendations/v1/viewed-items`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 200.

This API returns the list of viewed access request recommendations.

Query:

- standard: `limit`, `offset`, `count`
- filters: access.id (eq, in); access.type (eq, in); identityId (eq, in)
- sorters: access.id, access.type, identityId, timestamp

## Bulk mark viewed access request recommendations

`POST /ai-access-request-recommendations/v1/viewed-items/bulk-create`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 201.

This API consumes a notification that a set of recommended access request item were viewed. Future recommendations with these items will be marked with viewed=true. This can be useful for the consumer to determine if there are any new/unviewed recommendations.

Body:

```json
[
  {
    "identityId": "2c91808570313110017040b06f344ec9",
    "access": {
      "id": "2c9180835d2e5168015d32f890ca1581",
      "type": "ACCESS_PROFILE"
    }
  },
  {
    "identityId": "2c91808570313110017040b06f344ec9",
    "access": {
      "id": "2c9180835d2e5168015d32f890ca1581",
      "type": "ACCESS_PROFILE"
    }
  }
]
```
