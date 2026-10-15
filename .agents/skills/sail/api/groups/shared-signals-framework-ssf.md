# Shared Signals Framework (SSF)

The SSF Transmitter Service is a security event notification system that monitors identity attribute changes and automatically triggers session revocation events when specific lifecycle conditions are met.

10 endpoints. Paths are relative to the environment API host.

## Get SSF configuration

`GET /.well-known/v1/ssf-configuration`

Success: 200.

Returns the SSF transmitter discovery metadata (well-known configuration).

## Get JWKS

`GET /ssf/v1/jwks`

Success: 200.

Returns the transmitter's JSON Web Key Set (JWKS) for verifying signed delivery requests.

## Create stream

`POST /ssf/v1/streams`

Success: 201.

An SSF stream is associated with the client ID of the OAuth 2.0 access token used to create the stream.
One SSF stream is allowed for each client ID.

You can create a maximum of 10 SSF stream configurations for one org.

Body:

```json
{
  "delivery": {
    "method": "urn:ietf:rfc:8935",
    "endpoint_url": "https://receiver.example.com/ssf/events"
  },
  "events_requested": [
    "https://schemas.openid.net/secevent/caep/event-type/session-revoked"
  ],
  "description": "Production event stream for session revocation notifications"
}
```

## Get stream(s)

`GET /ssf/v1/streams`

Success: 200.

Retrieves either a list of all SSF stream configurations or the individual configuration if specified by ID.

As stream configurations are tied to a client ID, you can only view the stream associated with the client ID
of the request OAuth 2.0 access token.

Query parameter `aud` (co filter) can be used to filter by audience.

Query:

- `stream_id`: If provided, returns that stream; otherwise returns list of all streams.

## Update stream configuration

`PATCH /ssf/v1/streams`

Success: 200.

Partially updates a stream's configuration (PATCH). Only provided fields are updated.

The associated stream with the client ID (through the request OAuth 2.0 access token) is updated.

Body:

```json
{
  "stream_id": "550e8400-e29b-41d4-a716-446655440000",
  "description": "Updated production event stream configuration"
}
```

## Replace stream configuration

`PUT /ssf/v1/streams`

Success: 200.

Replaces a stream's configuration (PUT). stream_id and delivery are required; full receiver-supplied properties.

The associated stream with the client ID (through the request OAuth 2.0 access token) is replaced.

Body:

```json
{
  "stream_id": "550e8400-e29b-41d4-a716-446655440000",
  "delivery": {
    "method": "urn:ietf:rfc:8935",
    "endpoint_url": "https://receiver.example.com/ssf/events"
  },
  "events_requested": [
    "https://schemas.openid.net/secevent/caep/event-type/session-revoked"
  ],
  "description": "Replaced stream configuration for production event delivery"
}
```

## Delete stream

`DELETE /ssf/v1/streams`

Success: 204.

Deletes a stream by its ID. There is no request body; the stream is identified by the required
query parameter `stream_id`. On success the response has no body (204 No Content).

The associated stream with the client ID (through the request OAuth 2.0 access token) is deleted.

Query:

- `stream_id`: (Required) ID of the stream to delete. Required; omitted or empty returns 400.

## Get stream status

`GET /ssf/v1/streams/status`

Success: 200.

Returns the status (enabled, paused, disabled) and optional reason for the stream associated with the client ID of the request's OAuth 2.0 access token. The stream_id query parameter is required.

Query:

- `stream_id`: (Required) ID of the stream whose status to retrieve.

## Update stream status

`POST /ssf/v1/streams/status`

Success: 200.

Updates the operational status (enabled, paused, disabled) with an optional reason for the stream associated with the client ID of the request's OAuth 2.0 access token.

Body:

```json
{
  "stream_id": "550e8400-e29b-41d4-a716-446655440000",
  "status": "paused",
  "reason": "manually paused"
}
```

## Verify stream

`POST /ssf/v1/streams/verify`

Success: 204.

Verifies an SSF stream by publishing a verification event requested by a security events provider.

Body:

```json
{
  "stream_id": "550e8400-e29b-41d4-a716-446655440000",
  "state": "verification-challenge-state-123"
}
```
