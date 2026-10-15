# Identity History

11 endpoints. Paths are relative to the environment API host.

## Lists all the identities

`GET /historical-identities/v1`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 200.

This gets the list of identities for the customer. This list end point does not support count=true request param. The total  count of identities would never be returned even if the count param is specified in the request Requires authorization scope of 'idn:identity-history:read'

Query:

- standard: `limit`, `offset`
- `starts-with-query`: This param is used for starts-with search for first, last and display name of the identity
- `is-deleted`: Indicates if we want to only list down deleted identities or not.
- `is-active`: Indicates if we want to only list active or inactive identities.

## Get latest snapshot of identity

`GET /historical-identities/v1/:id`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 200.

This method retrieves a specified identity Requires authorization scope of 'idn:identity-history:read'

## List access items by identity

`GET /historical-identities/v1/:id/access-items`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 200.

This method retrieves a list of access item for the identity filtered by the access item type

Query:

- standard: `limit`, `offset`, `count`
- `type`: The type of access item for the identity. If not provided, it defaults to account (This can only be one of account,entitlement,app,accessProfile,role)

## Lists all the snapshots for the identity

`GET /historical-identities/v1/:id/snapshots`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 200.

This method retrieves all the snapshots for the identity Requires authorization scope of 'idn:identity-history:read'

Query:

- standard: `limit`, `offset`, `count`
- `start`: The specified start date
- `interval`: The interval indicating the range in day or month for the specified interval-name (This can only be one of day,month)

## Gets the summary for the event count for a specific identity

`GET /historical-identities/v1/:id/snapshot-summary`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 200.

This method gets the summary for the event count for a specific identity by month/day Requires authorization scope of 'idn:identity-history:read'

Query:

- standard: `limit`, `offset`, `count`
- `before`: The date before which snapshot summary is required
- `interval`: The interval indicating day or month. Defaults to month if not specified (This can only be one of day,month)
- `time-zone`: The time zone. Defaults to UTC if not provided

## Gets an identity snapshot at a given date

`GET /historical-identities/v1/:id/snapshots/:date`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 200.

This method retrieves a specified identity snapshot at a given date Requires authorization scope of 'idn:identity-history:read'

## Gets the list of identity access items at a given date filterd by item type

`GET /historical-identities/v1/:id/snapshots/:date/access-items`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 200.

This method retrieves the list of identity access items at a given date filterd by item type Requires authorization scope of 'idn:identity-history:read'

Query:

- `type`: The access item type

## List identity event history

`GET /historical-identities/v1/:id/events`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 200.

This method retrieves all access events for the identity Requires authorization scope of 'idn:identity-history:read'

Query:

- standard: `limit`, `offset`, `count`
- `from`: The optional instant until which access events are returned
- `eventTypes`: An optional list of event types to return. If null or empty, all events are returned
- `eventTypes`: An optional list of event types to return. If null or empty, all events are returned
- `accessItemTypes`: An optional list of access item types (app, account, entitlement, etc...) to return. If null or empty, all access items types are returned
- `accessItemTypes`: An optional list of access item types (app, account, entitlement, etc...) to return. If null or empty, all access items types are returned

## Gets the start date of the identity

`GET /historical-identities/v1/:id/start-date`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 200.

This method retrieves start date of the identity Requires authorization scope of 'idn:identity-history:read'

## Gets a difference of count for each access item types for the given identity between 2 snapshots

`GET /historical-identities/v1/:id/compare`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 200.

This method gets a difference of count for each access item types for the given identity between 2 snapshots Requires authorization scope of 'idn:identity-history:read'

Query:

- standard: `limit`, `offset`, `count`
- `snapshot1`: The snapshot 1 of identity
- `snapshot2`: The snapshot 2 of identity
- `accessItemTypes`: An optional list of access item types (app, account, entitlement, etc...) to return. If null or empty, all access items types are returned
- `accessItemTypes`: An optional list of access item types (app, account, entitlement, etc...) to return. If null or empty, all access items types are returned

## Gets a list of differences of specific accesstype for the given identity between 2 snapshots

`GET /historical-identities/v1/:id/compare/:access-type`

Experimental. Send `-H "X-SailPoint-Experimental: true"`.

Success: 200.

This method gets a list of differences of specific accessType for the given identity between 2 snapshots Requires authorization scope of 'idn:identity-history:read'

Query:

- standard: `limit`, `offset`, `count`
- `access-associated`: Indicates if added or removed access needs to be returned. true - added, false - removed, null - both added & removed
- `snapshot1`: The snapshot 1 of identity
- `snapshot2`: The snapshot 2 of identity
