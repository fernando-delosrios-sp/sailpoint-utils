## Context

The connector is an ISC custom-operations host: handlers loop back with `ctx.sdk` and may persist typed output onto a DelimitedFile result source. Sources expose native connector configuration through `connectorAttributes`, and Machine Accounts expose the authoritative `machineIdentity` link plus raw `connectorAttributes`. `sailpoint-api-client` supports machine-identity list/get/patch and entitlement filters on `value`.

The initial implementation split evaluation and apply across per-identity trigger accounts, an Account Created workflow, and a second custom apply command. Live validation showed that the scan can perform the same idempotent union directly and return one durable run summary, eliminating the orchestration layer.

## Architecture

[Container diagram](./diagrams/machine-identity-entitlements.drawio)

## Goals / Non-Goals

**Goals:**

- Register `custom:machine-identity-entitlements` with optional `identityId`
- Process a machine account only when its source has a non-blank `connectorAttributes.userEntitlements` setting
- Normalize single- and multi-valued attribute values, match catalog entitlements by `value`, compute entitlements to add vs current `userEntitlements`
- PATCH each non-empty union directly with bounded concurrency and continue after individual failures
- Persist one scan summary account per invoke, keyed by `requestId`
- Report mixed outcomes as `partial` and all-failed outcomes as failed
- Keep the interactive Scan workflow as a thin wrapper around the single command
- Offline fixtures for local `call:op`

**Non-Goals:**

- Std command handlers on this connector
- Human identity entitlement sync
- Access-request grant as the apply path (PATCH machine identity is the apply path)
- Failing the whole scan for unconfigured sources or unmatched values
- Per-identity trigger accounts, an Account Created Apply workflow, or a standalone apply command
- Changing SoD/risk operations

## Decisions

### D1: Evaluate and apply in one operation

- **Choice**: The scan computes each identity's union and PATCHes `userEntitlements` directly.
- **Reason**: The scan already has the identity, matched refs, SDK client, and authorization. Per-identity result accounts and a second invoke add latency and failure surfaces without adding information or control.
- **Considered alternatives**: Account Created workflow plus apply command — implemented and rejected as unnecessary orchestration. Workflow-only PATCH — cannot reliably zip parallel arrays into `{sourceId, entitlementId}` objects.

### D2: One scan summary account

- **Choice**: Persist exactly one account keyed by `{requestId}` after all identity attempts, including no-work runs.
- **Reason**: The result source becomes a durable run ledger rather than an event transport. One account records scanned, updated, skipped, failed, and entitlements-added counts plus aligned failed identity ids/details.
- **Considered alternatives**: Response only — fastest, but no durable audit history. Per-identity accounts — rejected because no wrapper consumes them.

### D3: Source connector configuration

- **Choice**: Read the entitlement attribute name from source `connectorAttributes.userEntitlements`, then read that key from each machine account's `connectorAttributes`. Cache source configuration by `sourceId`; skip missing or blank settings.
- **Reason**: This is the connector's native configuration. On `Microsoft Entra ID @emea-tes-team.cloud (NHI)` it is `spn_app_groups`.
- **Considered alternatives**: Custom account-schema `configuration.inboundEntitlements` — rejected because it duplicates native connector configuration and was absent on the live source.

### D4: Value extraction

- **Choice**: Treat the named attribute as string or `string[]`. Trim, drop blanks, union across processable accounts on the same identity.
- **Reason**: User required single- and multi-valued. Union is the only way two sources can contribute.
- **Considered alternatives**: First processable account only — rejected; under-collects.

### D5: Catalog match

- **Choice**: `listEntitlementsV1` with value equality, match across every source, deduplicate by entitlement id, and warn/continue for unmatched values.
- **Reason**: The configured machine-account values identify the ISC entitlements to set. Live validation confirmed that one Entra group value can legitimately map to separate Users, NHI, active-PIM, and eligible-PIM entitlement records.
- **Considered alternatives**: Restrict to the machine account source — rejected because it omits the matching Users-source entitlement.

### D6: Delta vs assigned

- **Choice**: Compare matched `{sourceId, entitlementId}` to current `userEntitlements`; skip an empty delta, otherwise PATCH the complete union.
- **Reason**: The operation is idempotent and preserves existing refs. The summary persists counts and failure diagnostics, not entitlement payloads.
- **Considered alternatives**: Replace with only matched refs — rejected because it removes unrelated assignments. Persist an add list for another consumer — rejected because no second consumer remains.

### D7: SDK layout

- **Choice**: `ctx.sdk.machineAccounts` (`MachineAccountsApi`) drives the scan; `ctx.sdk.machineIdentities` supplies current `userEntitlements`. Add `src/isc/machine-accounts/` pagination and retain dedicated machine-identities/entitlements wrappers.
- **Reason**: target-client per-API folders and the Machine Accounts response is the authoritative account-to-identity relation.
- **Considered alternatives**: Inline SDK in the operation — rejected; breaks isc boundaries.

### D8: Machine-account correlation

- **Choice**: List `/v2026/machine-accounts` and group by its authoritative `machineIdentity.id` node. Optional invoke `identityId` resolves one machine identity, then keeps only linked machine accounts; unknown → `ConnectorError`.
- **Reason**: Live tenant accounts did not correlate through Accounts `identityId`, while all 299 Entra NHI machine accounts had a `machineIdentity` node.
- **Considered alternatives**: Match by account name — only partial coverage and not authoritative. Accounts `identityId` → machine identity id — disproven on the live tenant.

### D9: Authentication and errors

- **Choice**: Standard invoke envelope. Connected path requires PAT scopes for machine identity list/get/patch, machine accounts, sources, entitlements, and one result-source summary persist. Discovery failures fail the invoke. Identity PATCH failures are isolated; the operation continues and records each failed identity.
- **Reason**: One bad identity must not block unrelated identities. Union-and-PATCH is idempotent, so a later rerun safely retries failures.

### D10: Partial and terminal outcomes

- **Choice**: No failures yields summary status `success`. A mix of successful and failed patches yields `partial` and a successful invoke. If every attempted patch fails, persist summary status `failed`, then return an operation-level failure.
- **Reason**: Mixed completion is useful work and the summary identifies retry targets. An all-failed run did not accomplish its apply purpose and must be visible as failed to the wrapper.
- **Considered alternatives**: Fail fast — rejected because it prevents independent identities from being processed. Always succeed — rejected because an all-failed run would look healthy.

### D11: Bounded patch concurrency

- **Choice**: PATCH identities with a fixed bounded concurrency. Each worker catches and records identity-specific errors rather than rejecting the worker pool.
- **Reason**: Serial PATCHes waste the invoke budget; unbounded fan-out risks throttling. Framework-wide 429 retry remains the backstop.

### D12: Operation response and workflow

- **Choice**: The invoke response mirrors summary counts. The interactive Scan workflow reads those counts and displays success, no-op, partial, or failed messaging. There is no Apply workflow.
- **Reason**: The wrapper needs presentation only; it no longer coordinates work.

## Risks / Trade-offs

- [Risk] `cisIdentityId` vs `id` mismatch → Mitigation: resolve `id` first, then `cisIdentityId`; document the observed mapping; fixture both shapes
- [Risk] Duplicate entitlement `value` across sources and membership types → Accept: each record is a distinct ISC entitlement, so all unique ids are persisted; the UI shows repeated display names for one Entra group
- [Risk] Experimental Machine Identities API drift → Mitigation: isolate in `src/isc/machine-identities/`
- [Risk] Large tenants / N+1 source and entitlement reads → Mitigation: cache source configuration by sourceId and entitlement matches by value; paginate machine accounts
- [Risk] Concurrent changes between identity list and PATCH → Mitigation: re-read current `userEntitlements` immediately before PATCH and union again
- [Risk] Failure text exceeds result-source limits → Mitigation: store one truncated STRING per failed identity; logs retain full diagnostics
- [Trade-off] Direct PATCH can leave a partially applied tenant → Accept: continue-and-summarize exposes failures and reruns are idempotent
- [Trade-off] One summary persist adds latency after patching → Accept: durable audit history was explicitly chosen over response-only output

## Migration Plan

This replaces the already-deployed split apply architecture.

1. Change the main operation to direct union-and-PATCH with one summary persist.
2. Remove the apply operation and regenerate `auto-registry.ts` and `connector-spec.json`.
3. Replace the Scan workflow messaging and delete the Apply workflow export.
4. Publish the connector before importing the revised Scan workflow.
5. Disable/delete the tenant's old Apply workflow before running the new version, so stale trigger accounts cannot invoke a removed command.

Rollback: deploy connector v18 and restore the prior Apply workflow export. Existing historical result accounts remain readable but are not consumed by the new operation.

## Open Questions

- None.
