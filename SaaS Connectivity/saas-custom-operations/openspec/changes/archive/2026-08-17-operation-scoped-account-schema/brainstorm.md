<!--
Raw capture of superpowers:brainstorming output.
-->

# Brainstorm: Operation-Scoped Account Schema

## Background

The custom operation framework manages a DelimitedFile **result source** where each invocation persists an account keyed by `requestId`. Account schema attributes must exist on the ISC source before values can be stored.

**Current behavior (two paths):**

1. **Source auto-create** (`applyBaseAccountSchema` in `result-source.ts`): builds schema from **union of all registered operation output fields** via `registeredOutputFields()` → `listRegisteredOperationSchemas().flatMap(...)`.
2. **Persist-time reconciliation** (`ensureSourceSchema`): already scoped to the **current operation's** `operationSchema.outputFields` plus keys in the persist `attributes` argument.

The user request: the framework should **not** enforce account schema attributes for all existing operations — only the one being invoked.

Persist-time is already correct. The gap is source-create-time base schema application and the spec/README language that mandates the union.

## Q1: What exactly should change at runtime?

**Decision:** On auto-provision of a new result source, apply core attributes (`id`, `status`, `date`, `details`) plus **only the invoking operation's output fields** — not the registry union. Subsequent operations add their fields lazily via existing persist-time reconciliation (add-only, warn-on-type-conflict).

**Rationale:** Matches how persist already works; avoids pre-declaring attributes for operations that may never run against this tenant's result source; reduces schema churn when adding new operations to the connector bundle.

## Q2: What about `npm run templates` / `account-schema.json`?

**Decision:** Keep the templates generator producing the **union of all operations** as operator reference documentation. This is not runtime enforcement — it shows the full attribute surface the connector *can* persist across operations.

**Non-goal:** Per-operation template files or removing the union reference artifact.

## Q3: Approaches considered

| Approach | Summary | Trade-off |
|----------|---------|-----------|
| **A — Operation-scoped base schema on create (recommended)** | Pass current `operationSchema.outputFields` into `createDelimitedFileResultSource` / `applyBaseAccountSchema`; remove registry union at runtime | Minimal change; reuses persist reconciliation for cross-operation attrs |
| **B — Core-only on create** | Only core attrs on create; all operation attrs added at first persist | Simpler create path but first persist does more work; less explicit at provision time |
| **C — No change to create; document only** | Rely on persist scoping and accept union on create | Does not satisfy user request |

**Recommendation:** A.

## Q4: Threading the operation schema through source resolution

**Decision:** Extend `resolveSourceByName` (and `createDelimitedFileResultSource`) to accept optional `outputFields: OperationField[]`. `with-custom-operation.ts` already resolves `operationSchema` before handler execution — resolve it **before** source auto-create so the first invocation can pass its output contract.

When `operationSchema` is unavailable (manual registration without schema), fall back to core-only base schema — persist reconciliation still adds fields when persist runs.

## Q5: Existing sources

**Decision:** No retroactive schema shrinking. Existing result sources keep whatever attributes they already have. Only **new** auto-provisions and persist-time add-only reconciliation change behavior.

## Q6: Spec scenarios to update

- **Base account schema on result source create:** replace "union of all registered" with "current invocation operation output fields".
- **New source receives full base schema:** expect only current op fields + core, not other registered ops.
- **Add scenario:** Operation B's first persist against a source created by Operation A adds B's attributes via reconciliation.

## Trade-offs

- **Pro:** Smaller initial schema; new connector operations don't affect existing tenants until invoked.
- **Pro:** Aligns create-time and persist-time semantics.
- **Con:** First invocation of each operation against an existing source still triggers schema patch (already true today for attrs missing from union if union was stale).
- **Con:** `account-schema.json` union no longer mirrors runtime create — mitigated by README note.

## Validated design summary

Scope runtime account schema enforcement to the **invoked operation only**. Change source auto-create to use current operation output fields; keep persist-time reconciliation unchanged; keep templates union as reference docs.
