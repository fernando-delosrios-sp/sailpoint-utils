## Why

Access-model SoD remediation asks someone to change a role or access profile that already contains conflicting entitlements. Forms and notification emails currently go to the SoD **policy owner**, who may not control that catalog item. Routing to the **access item owner** puts the remediation decision with the identity that can actually edit the item, and aligns operator docs with how catalog ownership works in ISC.

## What Changes

**Form instance recipient**
- From: SoD policy `ownerRef` identity (`resolvePolicyOwnerId`)
- To: Role or access profile primary `owner` identity (IDENTITY required)
- Reason: Remediation mutates the access item, not the policy definition
- Impact: **Breaking** for operators who expected policy owners to receive forms; existing in-flight forms unchanged

**Notification email recipients**
- From: `form-email-recipients` = policy owner email
- To: `form-email-recipients` = access item owner email (still single-element `string[]`)
- Reason: Bundled notification workflow emails whoever is in persist; must match form recipient
- Impact: **Breaking** for notification targeting; workflow JSONPath binding unchanged

**Operator-facing wording**
- From: README, seed description, root workflow table, and glossary describe “policy owner” as the form audience
- To: “access item owner” (role/AP owner) as the form audience
- Reason: Keep docs and ubiquitous language consistent with behavior
- Impact: Non-breaking documentation/spec sync

**Explicit non-goals**
- Changing form definition owner (token identity)
- Recipient override input
- Apply/correct operation behavior
- Child persist identity key or scan idempotency
- Falling back to policy owner when access item owner is missing

## Capabilities

### New Capabilities

- None

### Modified Capabilities

- `connector-operations/access-model-sod-remediation`: Form recipient, email recipients, and purpose wording retarget to access item owner
- `ubiquitous-language`: Access model SoD remediation glossary term no longer describes policy-owner forms; introduce access item owner term for this audience
- `target-client/roles`: Add IDENTITY owner extraction helper for roles used as form recipients
- `target-client/access-profiles`: Add IDENTITY owner extraction helper for access profiles used as form recipients

## Impact

- Modify: `src/operations/access-model-sod-remediation/index.ts`, tests, README, seed description, form-service comments
- Modify: `src/isc/roles/` and `src/isc/access-profiles/` (owner resolve helpers + offline fixtures as needed)
- Modify: package README workflow table wording; CHANGELOG note for breaking recipient change
- Specs on archive: `connector-operations/access-model-sod-remediation`, `ubiquitous-language`, `target-client/roles`, `target-client/access-profiles`
- External: ISC operators/workflows that assumed policy-owner inboxes will start emailing access item owners after upgrade; no JSONPath change required if already bound to `form-email-recipients`
