# Parameter Storage

The Parameter Storage is SailPoint's centralized repository for authentication, authorization, and connection configurations, stored as typed Parameters.

8 endpoints. Paths are relative to the environment API host.

## Get an attestation document.

`GET /parameter-storage/v1/attestation`

Success: 200.

Get an attestation document containing a NIST P-384 service public key for an ECDHE handshake, enabling the end-to-end-encrypted transport of parameter private fields.

Query:

- `key`: (Required) Base64Url encoded NIST P-384 public key

## Add a new parameter.

`POST /parameter-storage/v1/parameters`

Success: 201.

Add a new parameter.

Body:

```json
{
  "ownerId": "c0b4568a4fe7458c434ee77d1fbt156b",
  "name": "Credentials for server.",
  "type": "1.1",
  "publicFields": {},
  "privateFields": "ZW5jcnlwdGVkIHBhc3N3b3JkIGhlcmUu",
  "description": "Credentials for server."
}
```

## Query stored parameters.

`GET /parameter-storage/v1/parameters`

Success: 200.

Query a stored parameter.

Query:

- standard: `limit`, `offset`
- filters: id (eq, ne); name (eq, in, co); description (co); ownerId (eq); type (eq, sw)
- sorters: id, name, ownerId, type, description, lastModifiedAt, lastModifiedBy, privateFieldsLastModifiedAt, privateFieldsLastModifiedAt

## Get a specific parameter.

`GET /parameter-storage/v1/parameters/:id`

Success: 200.

Get a parameter by ID. This will only return the public fields for the parameter.

## Update a parameter.

`PATCH /parameter-storage/v1/parameters/:id`

Success: 200.

Update a parameter. You cannot change a parameter's type once set. Only the name, owner, description, public fields, and private fields can be updated. Private field updates are made via JWE AES256 encrypted blobs.

Body:

```json
{
  "ownerId": "c0b4568a4fe7458c434ee77d1fbt156b",
  "name": "Credentials for server.",
  "publicFields": {},
  "privateFields": "ZW5jcnlwdGVkIHBhc3N3b3JkIGhlcmUu",
  "description": "Credentials for server."
}
```

## Delete a parameter.

`DELETE /parameter-storage/v1/parameters/:id`

Success: 200.

Delete a parameter. Will only delete parameters without existing references.

## Get parameter references.

`GET /parameter-storage/v1/parameters/:id/references`

Success: 200.

Get the references for a given parameter.

Query:

- standard: `limit`, `offset`
- sorters: id, consumerId, parameterId, name, usageHint

## Get specifications for parameter types.

`GET /parameter-storage/v1/specifications`

Success: 200.

Get the specifications for all parameter types. All parameters must conform to this specification document.
