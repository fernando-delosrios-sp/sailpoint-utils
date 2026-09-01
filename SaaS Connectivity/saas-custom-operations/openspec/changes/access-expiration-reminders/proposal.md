## Why

Managers need advance notice when a report’s access-profile assignment is about to expire so they can propose a new end date. Today there is no connector command that discovers expiring ACCESS_PROFILE assignments, creates one manager form per notice, and emits workflow-ready email accounts. Adding `custom:access-expiration-reminders` closes that gap using the same scan → form → child-persist pattern already proven by access-model SoD remediation.

## What Changes

**New custom operation**
- Add `custom:access-expiration-reminders` under `src/operations/access-expiration-reminders/`
- Required input `formName`; optional `expirationDays` (default `1`)
- Match ACCESS_PROFILE assignments whose UTC calendar-day distance to `removeDate` equals `expirationDays`
- Create one standalone manager form per match (cap 25); persist one expiration notice account per form
- Return reminder scan summary via `ctx.respond` (no parent account on `requestId`)

**Form and email contract**
- Form inputs: `responseAccountId`, `identityId`, `accessProfileId`, plus friendly situation context
- Form collects required `newExpirationDate`; form instance expires at current `removeDate`
- Persist `access-expiration-reminders:form-url` and `form-email-*` fields for Send Email workflows

**Importable workflows**
- Scheduled daily 00:00 UTC invoker with stable `requestId` and `expirationDays: 1`
- `idn:account-created` notification workflow filtered by `operationName`

**Explicit non-goals**
- Applying `newExpirationDate` to the assignment in ISC
- Enforcing “new date after current expiration” beyond form guidance
- Role or entitlement expiration notices

## Capabilities

### New Capabilities

- `connector-operations/access-expiration-reminders`: Custom command contract — inputs, matching, form launch, notice accounts, scan summary, caps, skips
- `target-client/identities`: Search identities with sunset ACCESS_PROFILE assignments and resolve manager identity id

### Modified Capabilities

- `connector-operations`: Document namespaced persist keys for the new operation
- `target-client`: Include `identities` in ISC module layout / barrel inventory
- `target-client/forms`: Document caller-supplied form instance `expire` on standalone create
- `ubiquitous-language`: Promote access expiration reminder vocabulary from discovery

## Impact

- Add: `src/operations/access-expiration-reminders/` (handler, form seed/service, email builders, constants, README, tests, offline fixtures)
- Add: `src/isc/identities/` (or equivalent) for search + manager resolution wrappers and offline data
- Modify: codegen/auto-registry and `connector-spec.json` via existing discovery
- Add: `workflows/Access Expiration Reminders - Analysis.json` and `... - Notification.json`
- Add: offline payload under `payloads/`
- Specs: deltas under the capabilities listed above
- Tests: `npm test`, `npm run typecheck`; local `call:op` offline payload
- External: ISC workflows import; stable `requestId` required for cross-run idempotency
