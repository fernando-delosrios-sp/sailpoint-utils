## Context

Every custom operation declares `interface XOperation extends OperationSignature` with `input` and `output` object-literal types. Codegen (`scripts/generate-operation-schemas.ts` via `scripts/templates/operation-introspection.ts`) extracts `output` and writes two artifacts:

1. the per-op `*.schema.ts` sidecar (`defineOperationSchema`), attached to `ctx` and used by persist for typed formatting and by base/persist-time schema reconciliation;
2. the flattened ISC **account schema** (`scripts/templates/account-schema.ts` → `buildAccountSchema`), the union of all operations' `output` fields.

At runtime the handler writes accounts with `ctx.persist(id, attributes)` and returns a response with `ctx.res.send(payload)`. `output` was meant to describe the *persisted* attributes, but authors also list `ctx.res.send` rollup counters in it. Those never-persisted keys become account-schema attributes on no account.

Confirmed state on `main`:
- `access-model-sod-remediation` `output` mixes persisted child keys (`form-url`, `form-email-header/body/recipients`) with res.send-only counters (`access-items-scanned`, `violations-found`, `forms-skipped`, `forms-skipped-instances`, `forms-launch-failed`, `forms-persist-failed`). The glossary already names the counters a **scan summary** that is *not persisted*.
- Correct operations: `example`, `governance-group-emails`, `preventive-sod-check`, `_template`, and `access-model-sod-remediation-apply` (persist and res.send share the same object).
- abb `access-expiration-reminders` replicates the defect (motivation only; fixed on its branch).

All persist call sites in current handlers pass an inline object literal as the second argument, which makes static key extraction feasible.

## Goals / Non-Goals

**Goals:**
- `OperationSignature.output` means persisted attributes only; it remains the sole feed for the account schema.
- Give `ctx.res.send` a typed response envelope (`name`, `type`, `status`, `responses`, per-operation `summary`) that never reaches the account schema.
- Fail the build (codegen) when an `output` field is not persisted.
- Refactor every `main` violator to comply.

**Non-Goals:**
- Changing persist retry/verify, source provisioning, or reconciliation semantics.
- Typed validation of arbitrary summary values beyond TypeScript types.
- Editing abb's `access-expiration-reminders`.
- Auto-migrating existing result-source account schemas in ISC (attributes are additive; stale ones are left, not removed).

## Decisions

### D1: `output` is the persisted-attribute contract
- **Choice**: Keep `OperationSignature.output` and `ctx.persist(id, attributes: Partial<TOutput>)`, but define `output` semantically as exactly the keys persisted. Account/base schema derivation is unchanged in mechanism (already reads `output`); it becomes correct once summary keys leave `output`.
- **Reason**: Minimal churn to the persist/schema pipeline; the fix is contract meaning + guard + operation refactors.
- **Considered alternatives**: Rename to `persistedOutput` — rejected as a broad breaking rename with no added safety once the guard exists.

### D2: Typed operation response envelope on the signature
- **Choice**: Add an optional `response` (author summary) field to `OperationSignature`, and a framework `OperationResponse<TSummary>` envelope:

```ts
interface OperationSignature {
    command?: string
    input: object
    output: object            // persisted attributes only
    response?: object         // author-declared summary detail (optional)
}

interface OperationResponse<TSummary extends object> {
    name: string              // operation/command name, e.g. 'custom:access-model-sod-remediation'
    type: string              // 'custom'
    status: string            // 'success' | 'error' | operation-defined
    responses: string[]       // native ids persisted this invoke
    summary: TSummary         // the operation's response detail
}
```

- **Reason**: Structurally separates res.send content from `output`, matching the requested `name`/`type`/`status`/`responses` + summary shape.
- **Considered alternatives**: Leave res.send untyped — rejected; nothing then prevents authors from reaching back into `output`. Flatten summary fields at the envelope top level — rejected; nesting under `summary` keeps framework fields (`name`/`status`/`responses`) unambiguous.

### D3: Framework builds the envelope; author supplies only summary
- **Choice**: Add `ctx.respond(summary)` to `RequestContext`. It assembles `{ name: command, type: 'custom', status, responses, summary }` where `responses` comes from the persist `WriteRegistry` (ids written this invoke) and `status` defaults to `success`, then calls `ctx.res.send(envelope)`. `RequestContext` gains a second type param `TSummary` (default `Record<string, unknown>`), so `ctx.respond` is typed from `OperationSignature['response']`.
- **Reason**: `responses` is correct by construction (the framework already tracks persisted ids); authors cannot desync it.
- **Considered alternatives**: Author-built envelope passed to `res.send` — rejected; reintroduces drift and manual id lists. Keep raw `ctx.res.send` only — rejected; loses typing and auto-`responses`.

### D4: Codegen persist-output guard
- **Choice**: Extend the shared introspection so, per operation entry module, it collects the set of object-literal keys passed as the second argument of `ctx.persist(...)` calls. `generate-operation-schemas.ts` fails (non-zero exit) when any `output` field is absent from that persisted-key set, reporting the module path and offending fields. The inverse is enforced by construction (`response` keys live outside `output`).
- **Reason**: Mechanical enforcement at the same stage that reads `output`; current handlers use inline persist literals, so detection is reliable.
- **Known limit**: keys built in helper functions or spread from non-literal objects are not detected. Escape hatch: a `// persist-dynamic: <key>` marker comment in the module registers a key as intentionally persisted-but-dynamic. No current operation needs it.
- **Considered alternatives**: Separate ESLint rule — rejected to avoid a second AST toolchain; codegen already parses these modules. Runtime-only check — rejected; wouldn't fail CI deterministically before invoke.

### D5: Remediation via refactor, not schema surgery
- **Choice**: For each violator, move res.send-only keys from `output` into `response`, replace `ctx.res.send({...})` with `ctx.respond({...summary})`, regenerate sidecars, and let `buildAccountSchema` shrink naturally. Start with `access-model-sod-remediation`.
- **Reason**: Keeps `output`↔account-schema and `response`↔res.send aligned in one edit per op.

### D6: Glossary reconciliation
- **Choice**: Promote **operation response** (the typed envelope) and **response id list** (`responses`). Redefine **scan summary** as the access-model instance of the operation response `summary`.
- **Reason**: The concept already exists for one op; generalize rather than fork vocabulary.

## Risks / Trade-offs

- [Risk] `ctx.res.send` payload shape changes (now nested under the envelope) → Mitigation: workflows read results via account reads keyed by `requestId` (per templates-generator guide), not the invoke response body; document the new envelope in the workflow guide and changelog.
- [Risk] Guard false-positives for operations that persist via helpers → Mitigation: `// persist-dynamic:` escape hatch; current ops use inline literals.
- [Trade-off] `RequestContext` gains a second generic param → Accept: defaulted to `Record<string, unknown>`, so existing untyped call sites keep compiling.
- [Risk] Existing ISC result sources keep stale summary-named schema attributes → Accept: attributes are additive and unused; no destructive migration.

## Migration Plan

1. Land framework types (`output` meaning, `response`, `OperationResponse`, `ctx.respond`, `RequestContext<TOutput, TSummary>`).
2. Land the codegen guard (initially warn to surface violators, then flip to fail once operations are refactored — or land fail-mode together with the refactors in one PR to keep CI green).
3. Refactor each violator (`access-model-sod-remediation` first), regenerate `*.schema.ts` sidecars, `auto-registry.ts`, and `connector-spec.json` via `npm run codegen:schemas`.
4. Update the workflow-invocation guide/README for the response envelope.
5. Acceptance: `npm run typecheck`, `npm test`, `npm run codegen:schemas` (guard passes), `npm run build` all green; account schema contains no res.send-only counter attributes; `ctx.respond` returns `responses` matching persisted ids.

**Rollback**: revert the framework + codegen + operation commits; sidecars/`connector-spec.json` regenerate from reverted signatures. No ISC-side data migration to undo.

## Open Questions

- Envelope field name for author detail: `summary` (chosen) vs `operation`. Defaulting to `summary`; trivially renameable before apply.
- Whether to ship the guard in fail-mode in the same PR as the refactors (preferred, keeps CI green) or warn-first then fail. Recommend single-PR fail-mode.
