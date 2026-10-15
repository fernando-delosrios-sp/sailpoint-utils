# Entitlement Connections

Use this API to search and manage entitlement connections.

3 endpoints. Paths are relative to the environment API host.

## List entitlement connections

`GET /entitlement-connections/v1`

Success: 200.

Returns entitlement connections for the tenant.

This endpoint proxies to Search and supports standard collection query parameters.
The `filters` and `sorters` values support the Entitlement Connections search fields documented by ECS.

Query:

- standard: `limit`, `offset`, `count`
- `searchAfter`: Used to begin the search window at the values specified. This parameter consists of the last values of the sorted fields in the current record set. searchAfter length must match the number of sorters. This is used to expand the…
- filters: identity.id (eq, in); identity.name (eq, in, co); source.id (eq, in); source.name (eq, in, co); account.id (eq, in); account.name (eq, in, co); entitlement.id (eq, in); entitlement.attribute (eq, in, co); entitlement.value (eq, in, co); entitlement.privilegeLevel.effective (eq, in, co); type (eq, in); state.value (eq, in, co); standalone (eq, in); jit.activation (gt, lt, ge, le); jit.provision (gt, lt, ge, le); jit.deactivation (gt, lt, ge, le); jit.deprovision (gt, lt, ge, le); jit.expiration (gt, lt, ge, le)
- sorters: id, identity.id, identity.name, source.id, source.name, account.id, account.name, entitlement.id, entitlement.displayName, entitlement.attribute, entitlement.privilegeLevel.effective, type, state.value, standalone, jit.activation, jit.provision, jit.deactivation, jit.deprovision, jit.expiration

## List my entitlement connections

`GET /entitlement-connections/v1/current-identity`

Success: 200.

Returns entitlement connections constrained to the authenticated identity.
This endpoint proxies to Search and supports standard collection query parameters.

Query:

- standard: `limit`, `offset`, `count`
- `searchAfter`: Used to begin the search window at the values specified. This parameter consists of the last values of the sorted fields in the current record set. searchAfter length must match the number of sorters. This is used to expand the…
- filters: identity.id (eq, in); identity.name (eq, in, co); source.id (eq, in); source.name (eq, in, co); account.id (eq, in); account.name (eq, in, co); entitlement.id (eq, in); entitlement.attribute (eq, in, co); entitlement.value (eq, in, co); entitlement.privilegeLevel.effective (eq, in, co); type (eq, in); state.value (eq, in, co); standalone (eq, in); jit.activation (gt, lt, ge, le); jit.provision (gt, lt, ge, le); jit.deactivation (gt, lt, ge, le); jit.deprovision (gt, lt, ge, le); jit.expiration (gt, lt, ge, le)
- sorters: id, identity.id, identity.name, source.id, source.name, account.id, account.name, entitlement.id, entitlement.displayName, entitlement.attribute, entitlement.privilegeLevel.effective, type, state.value, standalone, jit.activation, jit.provision, jit.deactivation, jit.deprovision, jit.expiration

## Update entitlement connection

`PATCH /entitlement-connections/v1/:connectionId`

Success: 200.

Applies JSON Patch operations to an entitlement connection selected by `connectionId`.

Body:

```json
[
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
```
