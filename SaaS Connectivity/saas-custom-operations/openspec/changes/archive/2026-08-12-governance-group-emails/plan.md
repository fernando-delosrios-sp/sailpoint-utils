# Governance Group Emails Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add `custom:governance-group-emails` — resolves a governance group (workgroup) by name and persists member email addresses as `governance-group-emails:emails: string[]` for workflow BCC/distribution use.

**Architecture:** Extend `ctx.sdk` with `GovernanceGroupsApi` via `createSailPointClients`. Thin wrappers in `src/isc/governance-groups/` call `listWorkgroupsV1` (name filter) and paginated `listWorkgroupMembersV1` (email extraction). Operation handler at `src/operations/governance-group-emails/index.ts` orchestrates lookup, validates input, persists output, and supports offline fixtures.

**Tech Stack:** TypeScript, Vitest, `@sailpoint/connector-sdk`, `sailpoint-api-client` (`GovernanceGroupsApi`)

## Global Constraints

- Canonical test command: `npm test`
- Build command: `npm run build`
- Codegen command: `npm run codegen:schemas` (registers new command + syncs connector-spec.json)
- Integration validation: `npm run build` + optional `spcx` pack after implementation
- Operation input: `groupName` (required)
- Operation output: `governance-group-emails:emails` (string array, namespaced)
- Auth: reuse invocation `apiUrl` + `token`; no new sourceConfig fields
- Errors: throw `ConnectorError` on missing input, unknown group, or ISC API failure
- Coverage: 60% statements, 50% branches minimum

**Spec references:**
- `openspec/changes/governance-group-emails/specs/connector-operations/governance-group-emails/spec.md`
- `openspec/changes/governance-group-emails/specs/target-client/governance-groups/spec.md`
- `openspec/changes/governance-group-emails/specs/target-client/spec.md`
- `openspec/changes/governance-group-emails/design.md`

---

## Task 1: SDK governance groups client extension

**Files:**
- Modify: `src/framework/types.ts`
- Modify: `src/framework/sdk-factory.ts`
- Modify: `src/framework/request-context.ts` (offline stub if applicable)
- Create: `src/framework/sdk-factory.spec.ts` (extend existing tests if present)

- [ ] **Step 1:** Write failing test — `createSailPointClients` returns `governanceGroups: GovernanceGroupsApi`
- [ ] **Step 2:** Import `GovernanceGroupsApi` from `sailpoint-api-client/dist/governance_groups/api` (or package export path used elsewhere)
- [ ] **Step 3:** Wire into factory and `SailPointClients` type as `governanceGroups`
- [ ] **Step 4:** Update offline test-mode stub with no-op `listWorkgroupsV1` / `listWorkgroupMembersV1`
- [ ] **Step 5:** Run `npm test -- sdk-factory` — PASS

---

## Task 2: Workgroup lookup by name

**Files:**
- Create: `src/isc/governance-groups/find-workgroup-by-name.ts`
- Create: `src/isc/governance-groups/find-workgroup-by-name.spec.ts`
- Create: `src/isc/governance-groups/index.ts` (partial barrel)

- [ ] **Step 1:** Write failing test — `findWorkgroupByName` calls `listWorkgroupsV1` with `filters: 'name eq "My Group"'` and returns first match
- [ ] **Step 2:** Write failing test — zero results throws ConnectorError with group name
- [ ] **Step 3:** Write failing test — non-2xx response throws ConnectorError with status
- [ ] **Step 4:** Implement with OData string escaping (reuse pattern from accounts module if available)
- [ ] **Step 5:** Export from `index.ts`
- [ ] **Step 6:** Run `npm test -- find-workgroup-by-name` — PASS

---

## Task 3: Member email listing with pagination

**Files:**
- Create: `src/isc/governance-groups/list-workgroup-member-emails.ts`
- Create: `src/isc/governance-groups/list-workgroup-member-emails.spec.ts`

- [ ] **Step 1:** Write failing test — extracts non-empty `email` fields from member response
- [ ] **Step 2:** Write failing test — omits members with blank/missing email
- [ ] **Step 3:** Write failing test — paginates when multiple pages returned (mock offset/limit)
- [ ] **Step 4:** Write failing test — API failure throws ConnectorError
- [ ] **Step 5:** Implement pagination loop over `listWorkgroupMembersV1`
- [ ] **Step 6:** Export from `index.ts`
- [ ] **Step 7:** Run `npm test -- list-workgroup-member-emails` — PASS

---

## Task 4: Orchestrator and offline data

**Files:**
- Create: `src/isc/governance-groups/resolve-governance-group-emails.ts`
- Create: `src/isc/governance-groups/resolve-governance-group-emails.spec.ts`
- Create: `src/isc/governance-groups/offline-data.ts`

- [ ] **Step 1:** Write failing test — `resolveGovernanceGroupEmails(name)` chains find + list and returns emails
- [ ] **Step 2:** Write failing test — missing group propagates ConnectorError
- [ ] **Step 3:** Add offline map `{ 'Offline Approvers': ['a@example.com', 'b@example.com'] }` (example)
- [ ] **Step 4:** Implement orchestrator accepting `GovernanceGroupsApi` or SDK clients bag
- [ ] **Step 5:** Run `npm test -- resolve-governance-group-emails` — PASS

---

## Task 5: Governance group emails operation handler

**Files:**
- Create: `src/operations/governance-group-emails/index.ts`
- Create: `src/operations/governance-group-emails/index.spec.ts`
- Create: `src/operations/governance-group-emails/README.md`
- Generated: `src/operations/governance-group-emails/index.schema.ts`, `auto-registry.ts`, `connector-spec.json`

- [ ] **Step 1:** Write failing test — handler persists `governance-group-emails:emails` array on happy path (mocked SDK)
- [ ] **Step 2:** Write failing test — missing `groupName` throws ConnectorError
- [ ] **Step 3:** Write failing test — unknown group throws ConnectorError
- [ ] **Step 4:** Write failing test — offline mode returns canned emails without SDK calls
- [ ] **Step 5:** Implement `OperationSignature` with `command: 'custom:governance-group-emails'`, input `{ groupName: string }`, output `{ 'governance-group-emails:emails': string[] }`
- [ ] **Step 6:** Wire connected path via `resolveGovernanceGroupEmails(ctx.sdk.governanceGroups, groupName)`
- [ ] **Step 7:** Run `npm run codegen:schemas`; verify auto-registry and connector-spec.json
- [ ] **Step 8:** Run `npm test -- governance-group-emails` — PASS

---

## Task 6: Payloads, docs, and validation

**Files:**
- Create: `payloads/governance-group-emails-offline.json`
- Create: `payloads/governance-group-emails.json`
- Modify: `README.md` (operations table)
- Modify: `scripts/call-op.ts` (if operation registration required)
- Modify: `CHANGELOG.md` (via changelog-generator skill)

- [ ] **Step 1:** Author operation README with invoke examples, output shape, required token scopes, workflow integration
- [ ] **Step 2:** Add offline and connected invoke payloads aligned with README
- [ ] **Step 3:** Register in `scripts/call-op.ts` if other operations do
- [ ] **Step 4:** Update root README operations table
- [ ] **Step 5:** Run full `npm test` — PASS
- [ ] **Step 6:** Run `npm run build` — PASS
- [ ] **Step 7:** Update CHANGELOG via changelog-generator skill

---

## Commit guidance

- Commit SDK factory extension separately
- Commit isc governance-groups module (find, list, orchestrator)
- Commit operation handler + codegen outputs together
- Commit payloads, README, CHANGELOG last

## PRECHECK (apply phase)

Before connected integration test against live tenant (optional):
- Confirm workgroup name uniqueness policy for expected inputs
- Verify member `email` field population; add `resolveIdentityEmail` fallback only if spike shows gaps
- Document required OAuth scopes in operation README
