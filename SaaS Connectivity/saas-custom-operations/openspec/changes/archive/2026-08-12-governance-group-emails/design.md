## Context

ISC workflows often need governance group (workgroup) member email lists for BCC lines, distribution lists, or escalation paths. Teams currently chain HTTP actions: search workgroup by name, list members, map to emails. The saas-custom-operations scaffold has ISC loopback helpers under `src/isc/<api-grouping>/` and auto-discovered custom operations under `src/operations/<slug>/`, but no governance-group integration. The ABB branch proved the pattern with `custom:govgroup-emails`; this change ports it to main as `custom:governance-group-emails`.

Authentication reuses the standard custom-operation input envelope (`apiUrl`, `token`) — no new sourceConfig fields. ISC calls use the bearer token from each invocation; required scopes are governance group read (workgroup list + member list).

## Goals / Non-Goals

**Goals:**
- Implement `custom:governance-group-emails` with input `groupName` and persisted output `governance-group-emails:emails: string[]`
- Add `src/isc/governance-groups/` for workgroup lookup by name and member email extraction
- Add `src/operations/governance-group-emails/` with README, payloads, auto-registration via `command` literal
- Match ABB WorkgroupService error semantics (ConnectorError on missing group or API failure)

**Non-Goals:**
- Approval routing, risk-based email logic, or access-request-status integration
- Caching or batch resolution of multiple groups in one invoke

## Decisions

### D1: Command name and output shape
- **选择:** `custom:governance-group-emails`; persist `governance-group-emails:emails: string[]` (non-empty entries only).
- **理由:** Aligns with sod-remediation and preventive-sod-check namespaced persist keys; avoids collisions on shared result source schema.
- **已考虑 alternative:** Unprefixed `emails` — rejected; violates connector-wide namespaced output convention.

### D2: ISC module location
- **选择:** New `src/isc/governance-groups/` aligned to `GovernanceGroupsApi` / `/workgroups/v1`.
- **理由:** Matches existing per-API subdirectory convention; keeps operation handler thin.
- **已考虑 alternative:** Inline HTTP in operation handler — rejected; violates isc layer boundaries.

### D3: API transport
- **选择:** Extend `ctx.sdk` with `GovernanceGroupsApi` via `createSailPointClients`; thin wrappers in `governance-groups/` call `listWorkgroupsV1` and `listWorkgroupMembersV1`.
- **理由:** Methods exist in bundled `sailpoint-api-client`; consistent with accounts/forms SDK wiring.
- **已考虑 alternative:** Raw `iscGet` to `/workgroups/v1` — works but duplicates SDK pagination/filter handling.

### D4: Workgroup lookup strategy
- **选择:** `listWorkgroupsV1` with OData filter `name eq "{groupName}"` (escaped); take first exact name match; fail if zero results.
- **理由:** Mirrors ABB WorkgroupService; name is the workflow-friendly identifier.
- **已考虑 alternative:** Search API — unnecessary for exact name lookup.

### D5: Email extraction
- **选择:** Map member `email` from `listWorkgroupMembersV1` response; filter falsy/blank strings; preserve API order; dedupe not required unless duplicates observed in spike.
- **理由:** Member response includes `email` directly; blank filtering avoids invalid BCC entries.
- **已考虑 alternative:** Resolve via `public-identities` per member id — extra round-trips; use only if member `email` absent in spike.

### D6: Authentication and authorization
- **选择:** Reuse invocation `token` and `apiUrl`; no connector-level credential storage beyond existing sourceConfig.
- **理由:** All custom operations already receive loopback credentials per invoke.
- **已考虑 alternative:** Dedicated PAT in sourceConfig — rejected; workflows already pass OAuth token.

### D7: Error handling
- **选择:** Throw `ConnectorError` when: `groupName` missing/blank; zero workgroups match; ISC API returns non-2xx; optional paginated member fetch fails. Message SHALL include group name or HTTP status for workflow troubleshooting.
- **理由:** Matches brainstorm and ABB WorkgroupService; fails fast for workflow error branches.
- **已考虑 alternative:** Return empty `emails` on not-found — rejected; silent failure hides misconfigured group names.

### D8: Operation layout
- **选择:** Subdirectory `src/operations/governance-group-emails/index.ts` with `OperationSignature` declaring `command: 'custom:governance-group-emails'`, co-located README, offline fixture module, and invoke payloads under `payloads/`.
- **理由:** Matches sod-remediation and example operation patterns; codegen auto-registers command.
- **已考虑 alternative:** Flat `governance-group-emails-operation.ts` — rejected; subdirectory is current standard.

### D9: Offline / test mode
- **选择:** Support offline invoke when `apiUrl` and `token` absent — return canned emails from `offline-data.ts` keyed by `groupName` (same pattern as sod-remediation).
- **理由:** Enables local `npm test` and `spcx` dry-run without tenant credentials.

## Risks / Trade-offs

- [Risk] Duplicate workgroup names in tenant → Mitigation: document first-match behavior; consider exact-name validation in spike; log matched workgroup id
- [Risk] Member records missing `email` → Mitigation: filter blanks; optional follow-up to resolve via `public-identities` if spike shows gaps
- [Risk] Large groups exceed default page size → Mitigation: paginate `listWorkgroupMembersV1` until exhausted in client wrapper
- [Risk] Token lacks governance group read scope → Mitigation: ConnectorError with HTTP 403; document required scopes in operation README
- [Trade-off] No caching of membership → Accept: freshness over latency; workflows invoke on demand

## Migration Plan

N/A — new custom command; no breaking changes to existing operations. Deploy updated connector bundle; `npm run codegen:schemas` syncs `connector-spec.json`. Workflows replace multi-step HTTP with single `custom:governance-group-emails` invoke. Rollback: revert connector version; workflows fall back to prior HTTP actions.

## Open Questions

- Confirm tenant has unique workgroup names for expected inputs (or document first-match policy)
- Spike: verify member `email` population rate vs needing `resolveIdentityEmail` fallback
- Confirm minimum token scopes label for README (e.g. governance group read)
