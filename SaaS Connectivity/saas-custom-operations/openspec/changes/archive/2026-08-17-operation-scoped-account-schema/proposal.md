## Why

When a result source is auto-provisioned, the framework applies a base account schema built from the **union of every registered custom operation's output fields**. That pre-declares attributes for operations the tenant may never invoke, couples unrelated operations at schema-provision time, and grows the ISC schema whenever a new operation is added to the connector bundle. Persist-time reconciliation is already scoped to the current operation; source-create should match that model so only the invoked operation's contract is enforced at provision time.

## What Changes

**Base account schema on source auto-create**
- From: Core attributes plus the union of all registered custom operation output fields.
- To: Core attributes plus **only the invoking operation's output fields** (from `operationSchema.outputFields`).
- Reason: Schema enforcement should follow the operation being called, not the full connector registry.
- Impact: Non-breaking for existing result sources (add-only reconciliation unchanged). New auto-provisions start with a smaller schema.

**Source resolution passes operation context**
- From: `resolveSourceByName` / `createDelimitedFileResultSource` use registry union internally.
- To: Caller passes current operation output fields; registry union removed from runtime source-create path.
- Reason: Wire operation scope from `customOperation` wrapper into provisioning.
- Impact: Internal API change only.

**Templates reference artifact unchanged**
- From/To: `npm run templates` / `account-schema.json` continues to document the union of all operation outputs for operators.
- Reason: Reference documentation is not runtime enforcement.
- Impact: README clarifies create vs reference behavior.

## Capabilities

### New Capabilities

_(none)_

### Modified Capabilities

- `custom-operation-framework`: Base account schema on result source create scoped to invoking operation output fields; updated scenarios for multi-operation lazy schema growth

## Impact

- **Framework:** `src/framework/result-source.ts`, `src/framework/with-custom-operation.ts`, `src/framework/base-account-schema.ts` (comments/JSDoc only if needed)
- **Tests:** `result-source.spec.ts`, `with-custom-operation.spec.ts`, `base-account-schema.spec.ts` (if scenarios change)
- **Docs:** README result-source / schema sections; CHANGELOG
- **Unchanged:** Persist-time `ensureSourceSchema`, templates generator union output, existing result sources
