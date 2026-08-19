# custom:access-expiration-reminders

## Purpose

Discovers ACCESS_PROFILE assignments whose `removeDate` is exactly `expirationDays` UTC calendar days from the run date, creates a standalone manager reminder form per matching assignment (subject to caps and skips), persists one expiration notice account per launched form, and returns a reminder scan summary on `ctx.res.send`. Does **not** apply the manager-selected `newExpirationDate` to ISC.

## Command

`custom:access-expiration-reminders`

## Input

| Field | Required | Default | Description |
|---|---|---|---|
| `formName` | Yes | — | Shared tenant form definition name (ensure-from-seed on first use) |
| `expirationDays` | No | `1` | Exact UTC calendar-day offset from run date to `removeDate` |

## Output

### Invoke response (scan summary)

On success, `ctx.res.send` returns rollup counters alongside `status: 'success'`. Optional zero-valued skip/failure/overflow counters may be omitted. These fields are **not** persisted on result-source identity `{requestId}`.

| Field | Description |
|---|---|
| `access-expiration-reminders:identities-scanned` | Identities returned by sunset ACCESS_PROFILE search |
| `access-expiration-reminders:expirations-matched` | Assignments matching `expirationDays` |
| `access-expiration-reminders:forms-created` | Forms launched this run |
| `access-expiration-reminders:forms-skipped-existing` | Optional; notice account already exists |
| `access-expiration-reminders:forms-skipped-missing-manager-email` | Optional; missing manager id or email |
| `access-expiration-reminders:forms-launch-failed` | Optional; form instance create failures |
| `access-expiration-reminders:forms-persist-failed` | Optional; child persist failures after form create |
| `access-expiration-reminders:forms-overflow` | Optional; matched assignments beyond the 25-form cap |

### Child account (persisted) — `{requestId}:{identityId}:{accessProfileId}`

| Field | Description |
|---|---|
| `access-expiration-reminders:identityId` | Identity holding the assignment |
| `access-expiration-reminders:managerId` | Manager form recipient |
| `access-expiration-reminders:accessProfileId` | Expiring ACCESS_PROFILE id |
| `access-expiration-reminders:removeDate` | Current assignment removeDate |
| `access-expiration-reminders:daysRemaining` | Matched UTC day offset |
| `access-expiration-reminders:form-url` | Standalone form URL |
| `access-expiration-reminders:form-email-header` | Plain-text email subject |
| `access-expiration-reminders:form-email-body` | HTML email body with form link |
| `access-expiration-reminders:form-email-recipients` | Manager email (`string[]`) |

## Matching

Exact UTC calendar-day difference between run date and `removeDate` must equal `expirationDays`. Not rolling hour-based `Math.ceil` math. Offline runs use `OFFLINE_REFERENCE_NOW` (`2026-08-19`) as `now`.

## Idempotency

Skip form launch when a notice account already exists at `{requestId}:{identityId}:{accessProfileId}`. Callers that need cross-run dedupe must reuse a stable `requestId`.

## Local development

```bash
npm run call:op -- payloads/access-expiration-reminders-offline.json
```

Offline payload and workflows are added in later tasks.
