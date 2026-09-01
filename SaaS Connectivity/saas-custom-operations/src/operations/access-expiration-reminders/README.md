# custom:access-expiration-reminders

## Purpose

Discovers ACCESS_PROFILE assignments whose `removeDate` is exactly `expirationDays` UTC calendar days from the run date, creates a standalone manager reminder form per matching assignment (subject to caps and skips), persists one expiration notice account per launched form, and returns a reminder scan summary via `ctx.respond`. Does **not** apply the manager-selected `newExpirationDate` to ISC.

## Command

`custom:access-expiration-reminders`

## Input

| Field | Required | Default | Description |
|---|---|---|---|
| `formName` | Yes | — | Shared tenant form definition name (ensure-from-seed on first use) |
| `expirationDays` | No | `1` | Exact UTC calendar-day offset from run date to `removeDate` |

## Output

### Invoke response (scan summary)

On success, `ctx.respond(summary)` returns an **operation response** envelope:

| Envelope field | Meaning |
|---|---|
| `name` | `custom:access-expiration-reminders` |
| `status` | `success` |
| `responses` | Native identities persisted this invoke |
| `summary` | Scan rollup counters (below) |

Optional zero-valued skip/failure/overflow counters may be omitted. These fields are **not** persisted on result-source identity `{requestId}`.

| Summary field | Description |
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

## Cap and skips

- At most **25** forms per invoke (`MAX_FORMS_PER_RUN`). Overflow is counted in `forms-overflow` and logged once.
- Skip when manager id or public email is missing (counted; run continues).
- Skip when notice account already exists (idempotency).

## Workflows

| Workflow | Trigger | Role |
|---|---|---|
| [`workflows/Access Expiration Reminders - Analysis.json`](../../../workflows/Access%20Expiration%20Reminders%20-%20Analysis.json) | Daily 00:00 UTC | Invokes this command with stable `requestId` `access-expiration-reminders`, `formName`, `expirationDays: 1` |
| [`workflows/Access Expiration Reminders - Notification.json`](../../../workflows/Access%20Expiration%20Reminders%20-%20Notification.json) | `idn:account-created` filtered by `operationName` | Sends email from persisted `form-email-*` attributes |

Import both workflows, set connector ID / source / OAuth, and ensure the form definition name matches Analysis `formName`. Keep `requestId` stable across scheduled runs for cross-day idempotency.

## Local development

```bash
npm run call:op -- payloads/access-expiration-reminders-offline.json
```

Offline fixtures use `OFFLINE_REFERENCE_NOW` so the default `expirationDays: 1` matches without fake timers.
