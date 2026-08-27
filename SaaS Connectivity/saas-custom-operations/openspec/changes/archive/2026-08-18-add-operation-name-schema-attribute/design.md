## Context

The custom operation framework persists workflow-readable accounts on a shared DelimitedFile result source. Core attributes (`id`, `status`, `date`, `details`) cover identity, outcome, timing, and human-readable messages, but workflows cannot tell which custom command produced a row without inferring from prefixed output keys (e.g. `sod-remediation:formUrl`).

Stakeholders: workflow authors using Get Accounts, connector maintainers, operators using test mode / `npm run call:op`.

## Goals / Non-Goals

**Goals:**
- Mandatory STRING `operationName` on result source base account schema
- Auto-populate `operationName` from `context.commandType` on every persist and automatic failure persist when command is known
- Ignore handler-supplied `operationName` in persist attributes
- Schema reconciliation and templates reference artifact include `operationName` via shared base schema builder
- Test mode inhibited persist records `operationName` when present

**Non-Goals:**
- Adding `operationName` to `OperationSignature.output` or codegen sidecars
- Changing invoke response JSON shape
- Backfilling `operationName` on accounts written before deploy
- Storing slug-only values without the `custom:` prefix
- Using `operationName` as identity or display attribute

## Decisions

### D1: Attribute name and type

- **Choice:** Core attribute `operationName`, type STRING, isMulti false.
- **Reason:** Matches camelCase core attrs; reads clearly in workflow attribute maps.
- **Considered alternatives:** `commandType` (SDK-internal naming); `operation` (ambiguous) — rejected.

### D2: Value source

- **Choice:** Full command string from `context.commandType` (e.g. `custom:sod-remediation`).
- **Reason:** Aligns with logging, manifest commands, and registry keys.
- **Considered alternatives:** Slug only (`sod-remediation`) — rejected; loses namespace clarity.

### D3: Framework auto-set on persist

- **Choice:** `buildAccountAttributes` (or equivalent merge step) sets `operationName` from persist dependencies when `command` is defined; treat as framework-managed like `id`/`date`/`status`.
- **Reason:** Zero handler changes; cannot be forgotten.
- **Considered alternatives:** Optional handler field — rejected as inconsistent across operations.

### D4: Author override disallowed

- **Choice:** Strip/ignore `operationName` from handler persist attributes; add to reserved/framework-managed key set alongside `details` handling pattern.
- **Reason:** Prevents spoofing or stale values when re-persisting partial attrs.
- **Considered alternatives:** Allow override — rejected; undermines trust in the field.

### D5: Missing commandType

- **Choice:** Omit `operationName` from written account when `commandType` is undefined; still declare schema attribute.
- **Reason:** Rare manual-registration edge case; avoid empty placeholder strings.
- **Considered alternatives:** Default `custom:unknown` — rejected as misleading.

### D6: Core schema integration

- **Choice:** Add to `CORE_ATTRIBUTES` / `CORE_ATTRIBUTE_NAMES` in `base-account-schema.ts`; exclude from operation output field collection; include in `result-source` required core reconciliation.
- **Reason:** Single source of truth; templates generator inherits via `buildBaseAccountSchema`.
- **Considered alternatives:** Persist-time-only attribute — rejected; workflows need schema declared before first read.

### D7: Failure persist and test mode

- **Choice:** Pass command into failure persist and test-mode inhibited persist paths so failed accounts and summaries include `operationName`.
- **Reason:** Failures must be attributable same as success.
- **Considered alternatives:** Success-only — rejected per user intent.

## Risks / Trade-offs

- [Risk] Same `requestId` reused across different operations overwrites `operationName` → Mitigation: documented upsert semantics; matches `status`/`date` behavior.
- [Risk] Command string exceeds 256-char STRING limit → Mitigation: truncate with existing `truncateForIscStorage` + warning (unlikely for command names).
- [Trade-off] Duplicate signal vs prefixed output keys → Accept; explicit core field simplifies workflow filters.

## Migration Plan

1. Deploy connector with framework changes.
2. No manual source migration — first persist reconciles `operationName` onto existing result source schemas.
3. Workflows may optionally map `accounts[0].attributes.operationName` for routing or display.
4. Rollback: revert connector; attribute remains on schema but unused if workflows don't reference it.

## Open Questions

_(none)_
