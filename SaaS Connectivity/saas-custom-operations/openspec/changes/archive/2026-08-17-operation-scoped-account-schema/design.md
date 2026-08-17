## Context

The custom operation framework auto-provisions a DelimitedFile result source when `sourceName` is missing. Today, `applyBaseAccountSchema` builds the initial schema from `listRegisteredOperationSchemas()` — the union of every operation's output fields. Persist-time reconciliation (`ensureSourceSchema`) already limits patches to the current operation's output contract plus keys in the persist payload.

Operators and workflows are unaffected by which attributes exist on the ISC schema as long as required attrs are present before each write. The union-on-create behavior is an implementation choice that predates multi-operation connectors and creates unnecessary coupling.

## Goals / Non-Goals

**Goals:**
- Auto-provisioned result sources receive core framework attributes plus **only the invoking operation's output fields**.
- `customOperation` passes resolved `operationSchema.outputFields` into source resolution before auto-create.
- Persist-time reconciliation remains add-only and operation-scoped (no regression).
- Spec scenarios and tests cover multi-operation lazy schema growth.

**Non-Goals:**
- Shrinking schemas on existing result sources (no attribute removal).
- Changing `account-schema.json` templates to per-operation files (union stays as reference).
- Changing persist attribute formatting, typed inference, or ISC value limits.
- Modifying std connector commands or `connector-spec.json`.

## Decisions

### D1: Operation-scoped base schema on create (not registry union)

**Choice:** Replace `registeredOutputFields()` in `applyBaseAccountSchema` with caller-supplied `outputFields` from the current invocation.

**Alternatives:**
- *Core-only on create* — defer all operation attrs to persist; simpler but less explicit at provision.
- *Keep union* — rejected; does not meet requirement.

**Rationale:** Aligns create-time with persist-time semantics; minimal diff.

### D2: Resolve operationSchema before source auto-create

**Choice:** In `runCustomOperation`, resolve `operationSchema` (registry or explicit option) **before** calling `resolveSourceByName`, and pass `outputFields` into source provisioning.

**Rationale:** First invocation of an operation that creates the source must know which fields to declare.

### D3: Fallback when operationSchema is absent

**Choice:** If no `operationSchema` is available at source create, apply **core-only** base schema (`buildBaseAccountSchema([])`). Persist reconciliation adds operation fields on first `ctx.persist`.

**Rationale:** Preserves behavior for manually registered operations without sidecars; persist path already handles missing attrs.

### D4: Templates generator keeps union

**Choice:** `scripts/templates/account-schema.ts` continues flattening all registered operations for `account-schema.json`.

**Rationale:** Operator reference doc showing full connector attribute surface; not runtime enforcement. README will distinguish reference vs runtime create.

## Risks / Trade-offs

- **[Risk] Operation B first run against source created by A triggers schema patch** → Mitigation: existing persist reconciliation; add test scenario.
- **[Risk] README/docs still describe union-on-create** → Mitigation: documentation task in apply phase.
- **[Risk] `registeredOutputFields` helper becomes dead code** → Mitigation: remove private helper and unused import from `result-source.ts`.

## Migration Plan

1. Deploy connector update; no ISC migration required.
2. Existing result sources: unchanged attributes retained.
3. New auto-provisions: smaller initial schema; subsequent operations grow schema on first persist.
4. Rollback: revert to union-based `applyBaseAccountSchema` (additive-only — no data loss).

## Open Questions

_(none — scope locked in brainstorm)_
