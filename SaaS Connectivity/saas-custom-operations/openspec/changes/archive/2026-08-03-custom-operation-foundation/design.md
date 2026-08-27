## Context

saas-custom-operations is a SailPoint ISC SaaS connector template. Today it ships mock aggregation handlers (std:account:list/read/test-connection) and a fake MyClient — none of which reflect its intended role. The connector should serve as a **foundation for custom operations**: ISC workflows invoke custom commands, operations use the SailPoint SDK for loopback calls, and results persist as dummy accounts on a pre-provisioned tenant source.

Exploration (brainstorm.md) validated all major design forks: no std commands, auto-init volatile context, `persist(id, params?, status?)` API, account create upsert, sailpoint-api-client dependency.

## Goals / Non-Goals

**Goals:**
- Provide `withCustomOperation()` wrapper that auto-inits RequestContext per invocation
- Expose `ctx.sdk` (sailpoint-api-client), `ctx.log`, `ctx.persist()`, `ctx.requestId`, `ctx.sourceId`
- Map `persist()` to ISC account create on dummy source (upsert semantics)
- Include example custom operation and operations registry pattern
- Remove all std command handlers and mock client code

**Non-Goals:**
- Provisioning the dummy source in ISC (document prerequisites only)
- Defining specific business custom operations beyond an example/template
- Connector customizers or std aggregation read-back
- Persistent state between invocations

## Decisions

### D1: No standard commands

- **Choice:** connector-spec.json declares custom commands only; no std handlers registered
- **Reason:** Connector is not an aggregation source; std commands add misleading surface area
- **Considered alternatives:** Stub test-connection (rejected — adds complexity without clear value for this template)

### D2: withCustomOperation wrapper pattern

- **Choice:** Higher-order function wraps every custom command handler; parses standard input, builds context, runs handler
- **Reason:** Volatile scoped context without global state; testable; authors never init SDK/persist manually
- **Considered alternatives:** Module singleton (rejected — concurrency risk); manual context init (rejected — poor DX)

### D3: persist API signature

- **Choice:** `persist(id: string, params?: string[], status?: string)` where status defaults to `"success"` and date is always set to current ISO timestamp
- **Reason:** Minimal API; positional params map to param1..param9; operations control identity including child IDs
- **Considered alternatives:** Options object (deferred — third arg sufficient for now); status in param slot (rejected — burns param slot)

### D4: Account create upsert

- **Choice:** Use ISC account create API; duplicate identity upserts existing record
- **Reason:** Idempotent retries; operations may re-persist same id safely
- **Considered alternatives:** Fail on duplicate (rejected — poor retry story)

### D5: Standard input envelope

- **Choice:** Every custom operation receives `apiUrl`, `token`, `requestId`, `sourceId` plus operation-specific fields
- **Reason:** Consistent loopback auth and persistence target across all operations
- **Considered alternatives:** Source config for apiUrl/token (rejected — per-invocation tokens are more flexible for workflows)

### D6: sailpoint-api-client for loopback

- **Choice:** Add sailpoint-api-client; SDK factory configures from apiUrl + token in context
- **Reason:** Most custom ops need ISC API access; pre-configured clients reduce boilerplate
- **Considered alternatives:** Raw fetch only (rejected — SDK is the stated author preference)

### D7: Dummy source schema

- **Choice:** Document expected attributes: `id` (identity), `date`, `status`, `param1`..`param9`. Helper sets id attribute to match native identity.
- **Reason:** Generic sink accommodates diverse operations without per-op schema changes
- **Considered alternatives:** JSON blob attribute (rejected — harder to query in ISC)

## Risks / Trade-offs

- [Risk] Token passed per invocation could be logged accidentally → Mitigation: OperationLogger redacts token; never log raw input.token
- [Risk] param1..9 semantics opaque across operations → Mitigation: Document per-operation param mapping in operation source files; example operation demonstrates convention
- [Risk] sailpoint-api-client version mismatch with tenant API → Mitigation: Pin version; document compatibility in README
- [Trade-off] No std:test-connection for source health → Accepted: connectivity proven at first custom op execution
- [Trade-off] Fixed 9 param slots may be insufficient → Accepted: param9 can hold serialized data if needed; revisit if common

## Migration Plan

1. Add framework module and sailpoint-api-client dependency
2. Replace index.ts with custom-command-only registration
3. Remove my-client.ts and std-related tests
4. Update connector-spec.json (custom commands, remove accountSchema or repurpose for documentation)
5. Add framework unit tests with mocked Accounts API
6. Update README with dummy source prerequisites and author guide

Rollback: revert to previous commit; no database migrations (connector package only).

## Open Questions

- None — all design forks resolved during exploration.
