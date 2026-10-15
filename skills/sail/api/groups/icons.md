# Icons

Use this API to implement functionality related to object icons (application icons for example).

2 endpoints. Paths are relative to the environment API host.

## Update an icon

`PUT /icons/v1/:objectType/:objectId`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 200.

This API endpoint updates an icon by object type and object id. A token with ORG_ADMIN authority is required to call this API.

## Delete an icon

`DELETE /icons/v1/:objectType/:objectId`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 204.

This API endpoint delete an icon by object type and object id. A token with ORG_ADMIN authority is required to call this API.
