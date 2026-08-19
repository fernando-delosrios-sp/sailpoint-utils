## Scope

Add custom operation `custom:access-expiration-reminders` that finds ACCESS_PROFILE assignments expiring in exactly N UTC calendar days, creates one manager-facing reminder form per matching assignment, and persists one result-source account per notice for workflow email. Out of scope: applying the manager-selected new expiration date to ISC; enforcing “new date after current expiration” beyond form guidance; role or entitlement expiration notices.

## Language

**Access expiration reminder** (`promote`):
A notice that an identity’s ACCESS_PROFILE assignment will expire on a specific `removeDate`, addressed to that identity’s manager via a standalone ISC form.
_Avoid_: sunset reminder, access expiry alert (unless aliased)

**Expiration notice account** (`promote`):
The result-source account at `` `${requestId}:${identityId}:${accessProfileId}` `` holding per-notice workflow outputs (form URL, email fields, identity/manager/access-profile context).
_Avoid_: parent account, summary account

**Expiration days** (`promote`):
Optional invoke input `expirationDays` (default `1`): the exact UTC calendar-day difference between the run date and the assignment `removeDate` that selects which assignments receive reminders.
_Avoid_: daysThreshold, rolling day count, within-window threshold

**Response account id** (`promote`):
Form input `responseAccountId` equal to the expiration notice account native identity, used for correlation and idempotency awareness by downstream workflows.
_Avoid_: childId alone when referring to the form field

**New expiration date** (`promote`):
Required manager form element key `newExpirationDate` collecting the proposed replacement `removeDate`.
_Avoid_: expirationDate, removeDate (as the form output key)

**Reminder scan summary** (`promote`):
Rollup counters returned on successful `ctx.res.send` for identities scanned, expirations matched, forms created, existing-account skips, missing-manager/email skips, launch/persist failures, and cap overflow.
_Avoid_: parent persist rollup

## Decisions

**Context:** Legacy sketch returned one nested `data[]` payload via `res.send`. This connector’s pattern is one result-source account per actionable notice (see access-model-sod-remediation), with rollup on `res.send` and email via `idn:account-created`.

**Q1 — Output shape?**
→ Chosen: One `ctx.persist` per notice; `ctx.res.send` carries reminder scan summary only.

**Q2 — Persist namespace?**
→ Chosen: `access-expiration-reminders:` prefix (same field kinds as sod form-email outputs, not the `sod-remediation:` keys).

**Q3 — Notice account fields?**
→ Chosen: `identityId`, `managerId`, `accessProfileId`, `removeDate`, `daysRemaining`, plus `form-url`, `form-email-header`, `form-email-body`, `form-email-recipients`.

**Q4 — Form contract?**
→ Chosen: Required `formName` input. Form inputs include `responseAccountId`, `identityId`, `accessProfileId`, plus friendly situation context. Form collects required `newExpirationDate`. Form instance `expire` = assignment `removeDate`.

**Q5 — Matching rule?**
→ Chosen: Exact UTC calendar-day difference equals `expirationDays` (default `1`). Not rolling `Math.ceil` hours.

**Q6 — Idempotency?**
→ Chosen: Native identity `` `${requestId}:${identityId}:${accessProfileId}` ``; skip form launch when that account already exists. Callers that need stable dedupe across scheduled runs MUST reuse a stable `requestId` (same pattern as Access Model SOD Analysis workflow).

**Q7 — Missing manager / email?**
→ Chosen: Skip before form launch; count in scan summary.

**Q8 — Batch cap?**
→ Chosen: Hard cap of 25 forms per run; overflow counted in summary.

**Q9 — Completion / apply?**
→ Chosen: Notification-only. Applying `newExpirationDate` is out of scope. Form shows guidance that the new date must be after current expiration; downstream processes ignore earlier dates.

**Q10 — Workflows?**
→ Chosen: Include importable scheduled invocation workflow (daily 00:00 UTC, `expirationDays: 1`) and `idn:account-created` notification workflow filtered by `operationName`.

## Open questions

None blocking. Deferred by design: ISC form DATE controls do not enforce “after current removeDate” at submit time — guidance + downstream ignore of earlier dates.

## Scenarios discussed

- Identity with one AP expiring in exactly N UTC days → one form, one notice account, manager email recipients.
- Identity with multiple APs matching → one account/form per AP.
- Same `requestId` re-run → existing notice account skips form recreation.
- Fresh unique `requestId` each day → new notices even for same identity+AP (documented caller responsibility).
- No manager or manager without email → skip, summary counters, no form.
- Cap exceeded → first 25 created; overflow counted; remaining unmatched not launched.
- Zero matches → summary only; no notice accounts.
- Offline/test mode → deterministic fixtures; persist inhibited in test mode per framework.
- Manager submits earlier date → out of scope for this operation; guidance on form; apply path (external) ignores.
