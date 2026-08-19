## Context

Managers need one actionable reminder per ACCESS_PROFILE assignment that expires in a configurable number of UTC calendar days. The connector already supports multi-child persist + standalone forms via `custom:access-model-sod-remediation`. This change adds a parallel scan operation focused on identity assignments and managers, with notification-only semantics (no apply path in this change).

## Architecture

[Container diagram](./diagrams/access-expiration-reminders.drawio)

```
Scheduler ──invoke──▶ SaaS Custom Operations ──search──▶ ISC Search/Identities
                              │
                              ├──forms──▶ ISC Forms (manager instances)
                              └──persist─▶ Result Source (DelimitedFile)
                                              │
                                              └──account-created──▶ Notification WF ──email──▶ Manager
```

## Goals / Non-Goals

**Goals:**
- Register `custom:access-expiration-reminders` with auto-discovery
- Discover identities with ACCESS_PROFILE assignments matching `expirationDays` (UTC calendar exact)
- Launch at most 25 manager forms per run; skip missing manager/email and existing notice accounts
- Persist one expiration notice account per launched form with context + form/email fields
- Return full reminder scan summary on `ctx.res.send`
- Ship Analysis (scheduled) and Notification (account-created) workflows

**Non-Goals:**
- Applying `newExpirationDate` via access-request or assignment update APIs
- Form-level enforcement that `newExpirationDate` > current `removeDate`
- ROLE / ENTITLEMENT sunset reminders
- Changing framework persist/schema semantics

## Decisions

### D1: Child persist identity and idempotency

- **Choice:** `` `${requestId}:${identityId}:${accessProfileId}` ``; skip launch when account exists (`findAccountOnSource`)
- **Reason:** Matches proven access-model SoD pattern; user-requested key; stable scheduled `requestId` enables cross-run dedupe
- **Considered alternatives:** Identity+AP only (loses request scoping); include `removeDate` in key (user rejected for assignment-only intent within request scope)

### D2: UTC calendar-day matching

- **Choice:** Compare floored UTC dates of `now` and `removeDate`; match when difference == `expirationDays` (default `1`)
- **Reason:** Avoids rolling `Math.ceil` hour skew that misreports “tomorrow”
- **Considered alternatives:** Rolling 24h ceil; within-window ≤ N days

### D3: Manager as form recipient; email required before launch

- **Choice:** Resolve manager from identity; resolve public email; skip before form create if either missing; count in summary
- **Reason:** Notice is for the manager; Send Email workflow needs recipients
- **Considered alternatives:** Fall back to AP owner; create form without email account

### D4: Persist and response split

- **Choice:** Notice account holds context + `form-url` / `form-email-*`; `res.send` holds scan counters only (no parent persist on `requestId`)
- **Reason:** Same delivery model as access-model SoD after scan-summary change
- **Considered alternatives:** Nested `data[]` on `res.send` (user rejected)

### D5: Form seed and expiry

- **Choice:** Bundled seed with situation DESCRIPTION + required DATE `newExpirationDate`; form inputs include `responseAccountId`, `identityId`, `accessProfileId`, display context; instance `expire` = assignment `removeDate`
- **Reason:** Friendly manager UX; form unavailable after access already expires
- **Considered alternatives:** 30-day default form TTL

### D6: Cap of 25

- **Choice:** Hard constant `MAX_FORMS_PER_RUN = 25`; overflow counted in reminder scan summary
- **Reason:** User-selected batch limit; protects Forms API and persist latency
- **Considered alternatives:** Unlimited; configurable input

### D7: New identities ISC module

- **Choice:** Add `src/isc/identities/` for search of sunset ACCESS_PROFILE assignments and manager id resolution, with offline fixtures
- **Reason:** No manager or sunset-search helpers exist today; keep handlers thin
- **Considered alternatives:** Inline SearchApi calls in the operation; extend identity-access only

### D8: Workflows mirror Access Model SOD

- **Choice:** Analysis workflow: daily 00:00 UTC, stable `requestId` (e.g. `access-expiration-reminders`), `expirationDays: 1`, required `formName`. Notification: `idn:account-created` + `operationName` filter + Send Email from persisted attributes
- **Reason:** Proven pattern; enables idempotent daily runs

### D9: Date guidance without form validation

- **Choice:** Form copy states new date must be after current expiration; no ISC DATE min-bound (platform limitation); apply/ignore of earlier dates is external
- **Reason:** Discovery decision; ISC custom forms lack dynamic date validation against another input

## Risks / Trade-offs

- [Risk] Unique `requestId` per schedule run recreates forms for same identity+AP → Mitigation: Document stable `requestId` in README and Analysis workflow (same as SOD Analysis)
- [Risk] Search query for sunset APs may need tenant tuning → Mitigation: Encapsulate query in identities module; offline fixtures for unit tests; spike during apply
- [Risk] Manager type not IDENTITY or missing → Mitigation: Skip + summary counter; no hard fail of whole run
- [Risk] Cap truncates large tenants → Mitigation: Overflow counter + logs; operators re-run after clearing or with filtered scope later
- [Trade-off] No apply in this change → Accepted: notification-only scope
- [Trade-off] Identity length budget (128) for composite keys → Mitigation: Keep three UUID/hex segments; document limit

## Migration Plan

1. Deploy connector package with new command (codegen updates `connector-spec.json`)
2. Import/create form definition name used by Analysis workflow `formName`
3. Import Analysis + Notification workflows; set connector ID, source name, OAuth, and form name
4. Enable Analysis schedule; verify notice accounts and emails for a known near-expiry assignment
5. Rollback: disable workflows; redeploy prior connector zip (command absent)

## Open Questions

None blocking. During apply, confirm the exact Search query field path for nested `access.removeDate` / ACCESS_PROFILE type against the tenant index (spike if fixtures alone are insufficient).
