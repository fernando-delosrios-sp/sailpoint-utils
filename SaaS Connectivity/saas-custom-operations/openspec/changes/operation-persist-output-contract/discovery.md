## Scope

**In:** Redefine `OperationSignature.output` as the persisted-attribute contract only (what `ctx.persist` writes → account schema), add a distinct typed contract for the `ctx.res.send` response envelope, enforce the split with a codegen/lint guard, and remediate every operation on `main` that currently mixes the two. **Out:** changing persist retry/verify behavior, the DelimitedFile provisioning flow, or the abb-branch `access-expiration-reminders` code (cited as motivation; fixed on its own branch).

## Language

**persist output** (`draft`):
The set of account attributes an operation writes via `ctx.persist(id, attributes)`. It is the single source of truth for the result-source account schema. Today expressed as `OperationSignature.output`.
_Avoid_: "operation output" (ambiguous — conflated with the invoke response).

**operation response** (`promote`):
The typed payload an operation returns via `ctx.res.send(...)`. An envelope of `name`/`type`, `status`, `responses` (the persisted native ids written this invoke), and per-operation summary detail. Not persisted; never propagated to the account schema.
_Avoid_: "output", "result".

**response id list** (`draft`):
The `responses: string[]` field on the operation response — the native identities (`ctx.persist` ids) persisted during the invoke, so a caller can correlate the response to result-source accounts.
_Avoid_: "account ids" (these are native identities, not ISC account UUIDs).

**scan summary** (`conflicts-with-canonical`):
Already canonical for `access-model-sod-remediation` as the `ctx.res.send` rollup counters, explicitly *not persisted*. This change generalizes that idea to every operation as **operation response** summary detail; scan summary becomes the access-model-specific instance of it.
_Avoid_: introducing a second parallel term for the same res.send envelope.

**persist shape** (`draft`):
Whether an operation persists one account (single), a parent plus children, or an array of accounts. All shapes share one rule: only persisted attribute keys belong in `persist output`.

## Decisions

- **Context:** `OperationSignature.output` drives two codegen outputs — the per-op `*.schema.ts` sidecar and the flattened ISC account schema (`buildAccountSchema`). Authors have been declaring `ctx.res.send` summary counters (e.g. `access-items-scanned`, `forms-created`) in `output`, so those never-persisted keys become account-schema attributes that appear on no account.
- **Q: Should `output` describe persisted data or the res.send payload?** → Persisted data only. The account schema is the contract `output` feeds, so it must mirror `ctx.persist`.
- **Q: Where does the res.send summary live?** → In its own typed contract on the signature (a `response`/summary field), structurally separate from `output`, so the two cannot be conflated.
- **Q: What is in the response envelope?** → `name`/`type`, `status`, `responses` (persisted native ids), plus per-operation summary detail. `status`/`responses` are framework-populatable from the persist registry; summary detail is author-declared.
- **Q: How to prevent regressions?** → A codegen/lint guard fails the build when an `output` field is never persisted, or when a res.send-only key leaks into `output`/the account schema.
- **Q: How far does remediation go?** → Audit all `main` operations; fix every violator. `access-model-sod-remediation` is the confirmed `main` violator; `access-expiration-reminders` (abb) is motivation only.

## Open questions

- Exact signature surface for the response envelope (new `OperationSignature` field name and whether `responses`/`status` are framework-injected vs author-declared) — resolved in design.md; recommended default is framework-injected `status`/`responses`, author-declared summary detail.
- Whether the guard is enforced at codegen time (fail `codegen:schemas`), as a separate lint step, or both — resolved in design.md.

## Scenarios discussed

- Single-persist op (`preventive-sod-check`, `governance-group-emails`): `output` = the one account's attributes; response envelope carries any counters.
- Parent + children op (`example`, `access-model-sod-remediation`): `output` = union of persisted parent + child attribute keys only; per-run counters move to the response envelope.
- Array-of-accounts op: `output` = union of persisted attribute keys across accounts; `responses` lists every persisted id.
- Violator detection: an `output` field that no `ctx.persist(...)` call ever writes → guard failure.
- Correctly-typed response: `access-model-sod-remediation:access-items-scanned` present in the response envelope, absent from `output` and the account schema.
- Reserved keys (`id`, `sourceId`, `date`, `status`, `operationName`) remain framework-managed and out of `output`.
