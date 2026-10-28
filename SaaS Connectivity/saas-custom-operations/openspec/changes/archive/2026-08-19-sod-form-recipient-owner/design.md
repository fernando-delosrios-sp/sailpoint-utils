## Context

`custom:access-model-sod-remediation` scans enabled roles/access profiles, detects intrinsic SoD conflicts, and launches one standalone form per `(accessItem, policy)` pair. Today the handler calls `resolvePolicyOwnerId(violation.policy)` for both the form instance `recipientId` and the persisted `form-email-recipients` email. Catalog items already have a primary `owner` (`OwnerReference`) on Role and AccessProfile APIs; `CatalogAccessItem` currently carries only `id`/`name`/`type`. Form definition ownership remains the access-token identity via `ensureAccessModelSodFormDefinition`.

Stakeholders: access item owners (new recipients), policy owners (no longer form audience for this op), workflow operators using `form-email-recipients`.

## Goals / Non-Goals

**Goals:**
- Resolve the violating access item’s IDENTITY owner and use it as form instance recipient
- Persist that owner’s email as `access-model-sod-remediation:form-email-recipients`
- Fail a single form launch (not the whole scan) when owner is missing or not IDENTITY
- Update operation docs/seed/glossary so “access item owner” is the stated audience
- Add thin ISC helpers for role/AP owner extraction (parallel to `resolvePolicyOwnerId`)

**Non-Goals:**
- Changing form definition owner
- Recipient override input (unlike `custom:sod-remediation`’s `owner` field)
- Apply operation, child identity keys, or idempotency rules
- Using `additionalOwners` / governance-group owners as recipients
- Silent fallback to policy owner or token identity

## Decisions

### D1: Recipient source is access item primary owner
- **Choice:** Form `recipientId` and email resolution use the role/AP primary `owner` identity id
- **Reason:** Matches who can remediate the catalog definition; discovery locked this direction
- **Considered alternatives:** Keep policy owner; dual-notify both — rejected (wrong audience / out of scope multi-recipient)

### D2: Fetch owner via getRole/getAccessProfile, memoized per access item
- **Choice:** Add `resolveRoleOwnerId` / `resolveAccessProfileOwnerId` (or a thin dispatcher) that reads `owner` from `getRoleV1` / `getAccessProfileV1`, require `type` IDENTITY (or unset treated like IDENTITY when id present — match policy helper strictness: IDENTITY required when type set). Memoize owner id and email by access item id within the scan
- **Reason:** List/search paths may not always surface owner; get-by-id is authoritative; memoization avoids N×policies refetch
- **Considered alternatives:** Enrich `CatalogAccessItem` at list time — rejected (search vs list inconsistency); piggyback only on expand’s existing `getRoleV1` — deferred as optional optimization (APs still need a get)

### D3: Missing owner fails the launch, not the scan
- **Choice:** Throw `ConnectorError` from resolve helpers; handler catches like today’s form launch failures, increments `forms-launch-failed`, continues
- **Reason:** Mirrors current policy-owner strictness without aborting large scans
- **Considered alternatives:** Skip silently without counter; fall back to policy owner — rejected

### D4: Stop calling `resolvePolicyOwnerId` in this operation
- **Choice:** Remove policy-owner resolution from the access-model scan path; keep the sod-policies helper for other callers/specs
- **Reason:** Avoid accidental dual use and clarify ownership of recipient logic
- **Considered alternatives:** Keep call for logging only — rejected (noise, unused)

### D5: Docs and glossary update in the same change
- **Choice:** Update operation README, seed description, package workflow table wording, and ubiquitous-language purpose sentence
- **Reason:** Behavior and vocabulary must not diverge; discovery marked promote/conflicts terms
- **Considered alternatives:** Code-only — rejected

## Risks / Trade-offs

- [Risk] Roles/APs without IDENTITY owners fail form launch → Mitigation: counter + warn log; operators fix catalog ownership
- [Risk] Extra GET per unique access item with violations → Mitigation: memoize by access item id; accept double-get with expand for roles until optional join
- [Risk] Operators expecting policy-owner inboxes miss notifications → Mitigation: CHANGELOG breaking note; README callout
- [Trade-off] `additionalOwners` ignored → Accepted: primary owner only, same as policy single-owner model

## Migration Plan

1. Ship connector with access-item-owner recipient/email resolution
2. No workflow JSONPath change if already bound to `form-email-recipients`
3. Operators: ensure roles/APs in scope have IDENTITY owners before relying on form delivery
4. In-flight forms created under the old build remain with prior recipients; new scans use access item owners
5. Rollback: revert connector version (recipient targeting returns to policy owner)

## Open Questions

None.
