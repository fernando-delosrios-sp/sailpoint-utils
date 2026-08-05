# Brainstorm: Custom Operation Foundation

Raw capture of design exploration for transforming saas-custom-operations from an aggregation scaffold into a custom-operation foundation template.

## Background

The connector is **not** meant to be instantiated as a traditional aggregation source. It is a **foundation template** for building ISC custom operations. Each operation receives a standard input envelope (`apiUrl`, `token`, `requestId`, `sourceId` + operation-specific params), may perform loopback calls into ISC via the SailPoint SDK, and persists results as dummy accounts on a **pre-provisioned dummy source** per tenant.

Current scaffold is misleading: mock `MyClient`, std:account:list/read/test-connection, firstName/lastName/email schema — none of this matches the intended use case.

## Decision Chain

### Q1: What is the connector's role?

**Decision:** Custom-op runtime + ISC write-back layer, not an external SaaS aggregation source.

**Rationale:** Operations are invoked by ISC workflows; results are persisted back to ISC as accounts on a separate dummy source.

### Q2: How do operations persist output?

**Decision:** A `persist(id, params?, status?)` helper on auto-initialized request context.

- `id` → native account identity (operation may derive child IDs from `ctx.requestId`)
- `params` → positional array mapping to `param1`..`param9` (sparse OK)
- `status` → optional, defaults to `"success"`
- `date` → always set by helper to current timestamp
- Uses ISC account create API (upserts on duplicate identity)

**Rationale:** Authors should not wire ISC API plumbing; one call persists results.

### Q3: One or many persists per invocation?

**Decision:** Many. Operation passes `id` explicitly; may create child identities from `ctx.requestId` (e.g. `${ctx.requestId}:step-1`).

### Q4: In-memory context for API parameters?

**Decision:** Yes — auto-init per custom operation invocation, volatile, scoped to handler execution.

Context provides:
- `requestId`, `sourceId` (from input)
- Pre-configured `sailpoint-api-client` for loopback
- `persist()` helper
- Correlated `log`

Implemented via `withCustomOperation()` wrapper — authors never manually init SDK or persistence.

**Rationale:** Coding convenience; most operations use SailPoint SDK for loopback.

### Q5: Standard std commands?

**Decision:** None. connector-spec.json declares custom commands only.

Remove mock aggregation scaffolding entirely.

### Q6: Dummy source provisioning?

**Decision:** Pre-provisioned per tenant. Document expected account schema in connector-config spec.

Schema attributes: `id`, `date`, `status`, `param1`..`param9`. Identity attribute: `id`.

### Q7: Dependencies?

**Decision:** Add `sailpoint-api-client` alongside existing `@sailpoint/connector-sdk`.

## Trade-offs Accepted

| Trade-off | Acceptance |
|---|---|
| Fixed param1..9 slots vs named attrs per op | Generic sink source; ops document param semantics in their own docs |
| No std:test-connection | Simpler manifest; connectivity validated at runtime via SDK/persist |
| Volatile context vs explicit passing | Better DX; wrapper pattern avoids concurrency issues |
| Account create upsert | Idempotent retries; same identity overwrites prior result |

## Validated Design Summary

```
.command('custom:foo', withCustomOperation(async (ctx, input) => {
  ctx.log.info('starting')
  const data = await ctx.sdk.accounts...()
  await ctx.persist(ctx.requestId, [data.status, String(data.count)])
  await ctx.persist(`${ctx.requestId}:detail`, [data.detail], 'failed')  // optional status override
}))
```

Authors add files under `src/operations/` and register commands. Framework handles SDK init, logging, and persistence.
