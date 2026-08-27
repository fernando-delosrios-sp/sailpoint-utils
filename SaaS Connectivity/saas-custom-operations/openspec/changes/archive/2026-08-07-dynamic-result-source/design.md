## Context

The connector persists custom-operation output to an ISC DelimitedFile source. Configuration currently requires a pre-existing source UUID. A templates generator produces static account-schema JSON from registered operations, but operators must apply it manually. The framework stringifies all attribute values before `createAccountV1`.

Exploration converged on runtime source provisioning and per-operation schema reconciliation embedded in `ctx.persist`.

## Goals / Non-Goals

**Goals:**

- Config accepts `sourceName`; framework resolves to `sourceId` each invocation
- Auto-create DelimitedFile source when name not found (owner from token identity)
- Reconcile account schema before each persist for the **current operation only**
- Typed ISC schema inference from `OperationSignature.output` TS types
- Typed value formatting and type-aware read-back verification
- Warn-only conflict handling (keep type; upgrade isMulti)

**Non-Goals:**

- Per-author schema hint overrides (`outputSchemaHints`) — deferred
- Removing or changing templates generator behavior
- Union-of-all-operations schema at invoke time
- Removing attributes from existing schemas (add-only)
- Supporting non-DelimitedFile source types

## Decisions

### D1: sourceName replaces sourceId

- **Choice:** `connector-spec.json` and `StandardInput` use `sourceName`
- **Reason:** Human-readable workflow config; ID resolution is internal

### D2: Source resolution at customOperation wrapper

- **Choice:** Resolve/create source once per invocation in `customOperation`, before handler runs
- **Alternatives:** Resolve on first persist — rejected; handler may call persist multiple times; single resolve is sufficient
- **API:** `SourcesApi.listSourcesV1({ filters: 'name eq "<name>"' })`; on miss `createSourceV1({ source, provisionAsCsv: true })`

### D3: Owner from token identity

- **Choice:** Decode or introspect access token to obtain identity ID for `source.owner`
- **Spike:** JWT claim vs dedicated ISC endpoint — implementer validates against PAT and OAuth client-credentials tokens

### D4: Schema reconciliation inside persist

- **Choice:** `createPersist` calls `ensureSourceSchema` before `createAccountV1`
- **Scope:** Current operation's output fields (from `OperationSchemaContract` on context) plus keys in the attributes argument
- **Core attrs:** Always ensure `id`, `status`, `date` exist on schema

### D5: Conflict policy

- **Choice:** Missing → add; type mismatch → `console.warn`, keep existing; isMulti false→true → warn + JSON Patch
- **Reason:** User decision — don't break existing tenants on type drift; arrays must work

### D6: Type inference table

- **Choice:** string→STRING, number→INT, boolean→BOOLEAN, bigint→LONG, Date→DATE, object/unknown→STRING+json, arrays→element type + isMulti true
- **Reason:** Align ISC schema with JS output shapes; replace prior all-STRING template inference

### D7: Persist value formatting

- **Choice:** Replace `serializeAttributeValue` (all strings) with `formatAttributeValue` returning native types where ISC API accepts them; arrays stored per element rules
- **Verification:** Compare read-back with type coercion rules matching storage

### D8: OperationSchemaContract on RequestContext

- **Choice:** `customOperation` attaches `{ command, outputFields }` parsed from operation module (reuse templates introspection or lightweight duplicate)
- **Reason:** Persist needs output contract without re-parsing at each call

### D9: SourcesApi in SDK factory

- **Choice:** Add `sources: SourcesApi` to `SailPointClients`
- **Reason:** Centralized loopback client configuration

## Risks / Trade-offs

- [Risk] DelimitedFile read-back returns strings for typed attrs → Mitigation: spike on tenant; verification may coerce types
- [Risk] Token lacks source create/schema permissions → Mitigation: fail fast with clear ConnectorError; document scopes
- [Risk] Race on concurrent source create → Mitigation: catch conflict, re-list by name
- [Risk] Extra API latency per persist → Mitigation: acceptable for correctness; optional future cache within invocation
- [Trade-off] Breaking config rename → Accepted; update workflow JSON and README

## Migration Plan

1. Add source-provisioning and schema-inference modules with tests
2. Extend SDK factory with SourcesApi
3. Change config field sourceId → sourceName across framework
4. Wire source resolve in customOperation; schema reconcile in persist
5. Update typed formatting/verification in persist-result
6. Align templates generator inference (documentation parity)
7. Update connector-spec, README, workflow sample, tests
8. Run `npm test` and `npm run build`

## Open Questions

- Token identity resolution mechanism (JWT decode vs API) — resolve in spike during implementation
- DelimitedFile typed attribute read-back shape — validate in integration spike
