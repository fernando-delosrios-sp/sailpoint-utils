## Why

Custom operations persist results to a pre-provisioned DelimitedFile source identified by UUID. Operators must manually create the source, apply a generated account schema, and keep schema in sync when operations add output fields. This friction blocks self-service adoption and duplicates what the connector already knows from `OperationSignature.output`.

## What Changes

- Replace connector config `sourceId` with **`sourceName`**
- **Auto-resolve** source by name on each invocation; **create** DelimitedFile source if missing (owner = token identity)
- **Reconcile account schema** inside `ctx.persist`, scoped to the **current operation's** output contract
- **Typed attribute inference** — map TS output types to ISC schema types (`INT`, `BOOLEAN`, `LONG`, `DATE`, `STRING`) with native value storage
- **Conflict policy:** warn and keep existing on type mismatch; warn and patch `isMulti` to `true` when needed
- Update persist serialization and verification for typed values (replacing all-string `String()` coercion)

## Capabilities

### Modified Capabilities

- `connector-config`: `sourceName` replaces `sourceId`; document auto-provisioning prerequisites (token scopes)
- `custom-operation-framework`: source resolution, schema reconciliation at persist, typed inference/storage, `SourcesApi` on SDK factory

## Impact

- `connector-spec.json` — config field rename
- `src/framework/types.ts`, `with-custom-operation.ts`, `request-context.ts`, `persist-result.ts`, `sdk-factory.ts`
- New: `src/framework/source-provisioning.ts`, `src/framework/schema-inference.ts` (or equivalent)
- `scripts/templates/account-schema.ts` — align inference table with runtime (documentation parity)
- Tests: framework unit tests for inference, reconciliation, persist typed values
- Workflows / README — `sourceName` instead of `sourceId`
- **Breaking:** existing deployments must rename config and remove hardcoded source IDs
