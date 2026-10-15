# Apps

Use this API to implement source application functionality.

14 endpoints. Paths are relative to the environment API host.

## Get source app by id

`GET /source-apps/v1/:id`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 200.

This API returns a source app by its ID.

## Patch source app by id

`PATCH /source-apps/v1/:id`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 200.

This API updates an existing source app using JSON Patch syntax.
The following fields are patchable: **name**, **description**, **enabled**, **owner**, **provisionRequestEnabled**, **appCenterEnabled**, **accountSource**,  **matchAllAccounts** and **accessProfiles**.
Name, description and owner can't be empty or null.

Body:

```json
[
  {
    "op": "replace",
    "path": "/enabled",
    "value": true
  }
]
```

## Delete source app by id

`DELETE /source-apps/v1/:id`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 200.

Use this API to delete a specific source app

## Bulk update source apps

`POST /source-apps/v1/bulk-update`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 204.

This API updates source apps using JSON Patch syntax.  It can update up to 50 source apps in a batch.
The following fields can be updated: **name**, **description**, **enabled**, **owner**, **provisionRequestEnabled**, **appCenterEnabled**, **accountSource**,  **matchAllAccounts**, and **accessProfiles**.
Name, description and owner can't be empty or null.

Body:

```json
{
  "appIds": [
    "2c91808a7624751a01762f19d665220d",
    "2c91808a7624751a01762f19d67c220e",
    "2c91808a7624751a01762f19d692220f"
  ],
  "jsonPatch": [
    {
      "op": "replace",
      "path": "/description",
      "value": "New description"
    },
    {
      "op": "replace",
      "path": "/description",
      "value": "New description"
    }
  ]
}
```

## List assigned source apps

`GET /source-apps/v1/assigned`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 200.

This API returns the list of source apps assigned for logged in user.

Query:

- standard: `limit`, `offset`, `count`
- sorters: id, name, created, modified, accountSource.id
- filters: id (eq, in); name (eq, in, co, sw); created (gt, lt, ge, le); modified (gt, lt, ge, le); accountSource.id (eq, in)

## List available source apps

`GET /source-apps/v1`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 200.

This API returns the list of source apps available for access request.

Query:

- standard: `limit`, `offset`, `count`
- sorters: id, name, created, modified, owner.id, accountSource.id
- filters: id (eq, in); name (eq, in, co, sw); created (gt, lt, ge, le); modified (gt, lt, ge, le); accountSource.id (eq, in)

## Create source app

`POST /source-apps/v1`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 200.

This endpoint creates a source app using the given source app payload

Body:

```json
{
  "name": "new app name",
  "description": "app description",
  "matchAllAccounts": true,
  "accountSource": {
    "id": "edcb0951812949d085b60cd8bf35bc78"
  }
}
```

## List all source apps

`GET /source-apps/v1/all`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 200.

This API returns the list of all source apps for the org.

Query:

- standard: `limit`, `offset`, `count`
- sorters: id, name, created, modified, owner.id, accountSource.id
- filters: id (eq, in); name (eq, in, co, sw); created (gt, lt, ge, le); modified (gt, ge, le); owner.id (eq, in); enabled (eq)

## List access profiles for the specified source app

`GET /source-apps/v1/:id/access-profiles`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 200.

This API returns the list of access profiles for the specified source app

Query:

- standard: `limit`, `offset`
- filters: id (eq, in); name (eq, in); created (gt, lt, ge, le); modified (gt, lt, ge, le)

## Bulk remove access profiles from the specified source app

`POST /source-apps/v1/:id/access-profiles/bulk-remove`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 200.

This API returns the final list of access profiles for the specified source app after removing

Query:

- standard: `limit`

Body:

```json
[
  "c9575abb5e3a4e3db82b2f989a738aa2",
  "c9dc28e148a24d65b3ccb5fb8ca5ddd9"
]
```

## Patch user app by id

`PATCH /user-apps/v1/:id`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 200.

This API updates an existing user app using JSON Patch syntax.
The following fields are patchable: **account**

Body:

```json
[
  {
    "op": "replace",
    "path": "/account",
    "value": {
      "id": "0891808a7813090a017814121e121518",
      "type": "ACCOUNT"
    }
  }
]
```

## List available accounts for user app

`GET /user-apps/v1/:id/available-accounts`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 200.

This API returns the list of available accounts for the specified user app. The user app needs to belong lo logged in user.

Query:

- standard: `limit`, `count`

## List owned user apps

`GET /user-apps/v1`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 200.

This API returns the list of user apps assigned to logged in user

Query:

- standard: `limit`, `offset`, `count`
- filters: id (eq); ownerName (eq, sw); ownerAlias (eq, sw); accountId (eq); sourceAppId (eq)

## List all user apps

`GET /user-apps/v1/all`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 200.

This API returns the list of all user apps with specified filters.
This API must be used with **filters** query parameter.

Query:

- standard: `limit`, `offset`, `count`
- filters: id (eq); ownerId (eq); ownerName (eq, sw); ownerAlias (eq, sw); accountId (eq); sourceAppId (eq)
