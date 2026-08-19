## Scope

Add a framework-managed core result-source account attribute `operationName` (STRING) that is declared on the base schema and automatically populated on every persist with the invoking custom command name (`context.commandType`, e.g. `custom:sod-remediation`). Out of scope: exposing `operationName` on `OperationSignature.output`, changing invoke response shape, or backfilling historical accounts.

## Language

**operationName core attribute** (`promote`):
A mandatory framework-managed STRING attribute on the DelimitedFile result source account schema that stores the ISC custom command name that last wrote the account.
_Avoid_: `command`, `commandType`, `operation` as attribute names (conflict with SDK / internal naming).

**custom command name** (`draft`):
The full connector command identifier for a custom operation invocation (e.g. `custom:sod-remediation`), sourced from `context.commandType` at runtime.
_Avoid_: `slug` alone when referring to the persisted attribute value (slug omits the `custom:` prefix).

## Decisions

**Context:** Workflows read result accounts via Get Accounts. Core attributes already carry `id`, `status`, `date`, and `details`, but nothing identifies which custom operation produced the row—problematic when one result source serves many commands or when the same `requestId` is reused across retries.

**Q1 — Attribute name?** → `operationName` (camelCase, matches existing core attrs; reads naturally in workflow mappings).

**Q2 — Stored value format?** → Full command type (`custom:<slug>`), not slug alone. Matches SDK `commandType`, logging, and manifest command names.

**Q3 — Population model?** → Framework auto-sets on every persist (success and automatic failure persist), same as `id`, `date`, and `status`. Handlers SHALL NOT override via persist attributes (ignored if supplied).

**Q4 — Schema placement?** → Core base schema alongside `details`; excluded from operation output codegen union; reconciled at persist like other core attrs.

**Q5 — When commandType missing?** → Omit `operationName` from written account attributes; still declare attribute on schema. Rare path (manual ops without context); no default placeholder string.

## Open questions

_(none — scope locked)_

## Scenarios discussed

- New auto-provisioned result source: base schema includes `operationName` with other core attrs.
- Existing result source missing `operationName`: first persist reconciles schema then writes value.
- Success persist: account includes `operationName` matching invoked command.
- Automatic failure persist: failed account includes `operationName` alongside `details`.
- Handler attempts `ctx.persist(..., { operationName: 'custom:other' })`: framework ignores author value; uses invocation command.
- Test mode inhibited persist: recorded attributes include `operationName` when command known.
- Templates reference schema (`npm run templates`): includes `operationName` via shared `buildBaseAccountSchema`.
- Operation declares output field named `operationName`: excluded from operation output sidecar / schema union; framework core definition wins.
- Re-invoke same `requestId` with different operation: account upsert overwrites `operationName` to latest command (same semantics as status/date).
