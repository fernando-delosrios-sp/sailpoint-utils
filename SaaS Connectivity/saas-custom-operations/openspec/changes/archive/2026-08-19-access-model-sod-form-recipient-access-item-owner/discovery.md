## Scope

Retarget `custom:access-model-sod-remediation` form instance recipients and persisted notification emails from the SoD **policy owner** to the violating **access item owner** (role or access profile). Out of scope: form definition ownership (stays token identity), apply/correct operations, recipient override input, multi-recipient fan-out, and changing child persist identity keys.

## Language

**Access item owner** (`promote`):
The IDENTITY-typed owner of the catalog access item (role or access profile) that holds an intrinsic SoD conflict; the form instance recipient and sole email-notification target for access-model SoD remediation.
_Avoid_: policy owner (as form recipient), violation owner, form definition owner, “catalog owner” without access-item qualifier

**Policy owner** (`conflicts-with-canonical` for this operation’s recipient wording):
The IDENTITY-typed owner of the SoD policy. Remains a policy attribute and may still appear in copy/context, but is **not** the form recipient or `form-email-recipients` source for access-model SoD remediation after this change.
_Avoid_: using “policy owner” to mean the person who remediates the access item definition

**Form definition owner** (`draft`):
The identity that owns the shared ISC form definition on create (access-token identity). Unchanged by this change; distinct from form instance recipient.
_Avoid_: conflating with access item owner or policy owner

**Access model SoD remediation** (`conflicts-with-canonical`):
Canonical glossary still describes forms as “policy-owner remediation forms”; this change retargets that phrase to access-item-owner forms. Promote updated wording via ubiquitous-language delta.
_Avoid_: leaving “policy owner” in the operation’s primary purpose statement

## Decisions

- **Context:** Catalog hygiene forms ask someone to remove conflicting entitlements/APs from a role or access profile. That change belongs to the access item’s owner, not the SoD policy’s owner.
- **Q1:** Who is the form instance recipient? → **Access item owner** (IDENTITY), resolved from the role or access profile `owner` / `ownerRef` equivalent on the item.
- **Q2:** Do notification emails follow? → **Yes** — `access-model-sod-remediation:form-email-recipients` is the access item owner’s email (single-element array), same as today’s policy-owner pattern.
- **Q3:** Does form definition ownership change? → **No** — `ensureAccessModelSodFormDefinition` still uses the token identity.
- **Q4:** Missing or non-IDENTITY access item owner? → **Fail that violation’s form launch** (increment `forms-launch-failed`, continue scan), mirroring `resolvePolicyOwnerId` strictness. No silent fallback to policy owner or token identity.
- **Q5:** Does apply need changes? → **No** — apply consumes form submission, not recipient identity.
- **Q6:** Docs/seed/workflow narrative? → **Update in-package wording** from “policy owner” to “access item owner” where it describes who receives/submits the form. Bundled notification workflow binding stays on `form-email-recipients` (no structural workflow change expected).

## Open questions

None — scope locked by user request; missing-owner behavior assumed to mirror current policy-owner resolution strictness.

## Scenarios discussed

- Role violation → form recipient and email are the role’s IDENTITY owner, not the policy’s `ownerRef`.
- Access profile violation → same for the access profile’s IDENTITY owner.
- Same access item violates multiple policies → same owner receives multiple forms (one per pair); email resolution stays memoized by owner id.
- Access item has no owner id / non-IDENTITY owner → that launch fails; scan continues; counter `forms-launch-failed` increments.
- Offline fixtures supply a canned access-item owner id/email so local invoke still launches forms.
- Child persist idempotency key `{requestId}:{accessItemId}:{policyId}` unchanged; skipped forms do not re-resolve recipients.
- Form seed/README/root workflow table language updates so operators expect access item owners, not policy owners.
