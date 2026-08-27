# Brainstorm: preventive-sod-check

## Background

Workflows need to know whether an identity would violate SoD if pending grant access requests complete. A standalone prototype exists at `.scratch/sod-check` using ISC `predictSodViolations`. ABB branch had a different local-policy implementation (`check-sod-pending`) — rejected in favor of the scratch algorithm.

## Decision chain

**Q1: Evaluation engine?**
ISC `startPredictSodViolationsV1` on pending GRANT_ACCESS entitlements (not local policy ID matching).

**Q2: Pending discovery?**
Access request status (EXECUTING + GRANT_ACCESS) + events index search on trackingNumber with retry loop (handles provisioning lag).

**Q3: Command name?**
`custom:preventive-sod-check`.

**Q4: Output format?**
Match sod-remediation namespaced persist fields. Drop scratch `approved` field.

Persist:
- `preventive-sod-check:situation-summary` — human-readable summary
- `preventive-sod-check:violated-policy-names` — string[] of all violated policies

**Q5: Optional accessRequestId?**
Affects situation-summary wording only:
- No violations → "No violations found"
- Violations, no accessRequestId → list all policies
- Violations, with accessRequestId → attribute summary to that access request
`violated-policy-names` always contains the full set from predict API.

**Q6: ISC modules needed?**
Access request listing, events search with retry, entitlement expansion (reuse roles/access-profiles), predict SoD violations wrapper.

## Out of scope

- access-request-status, access-request-threshold
- Revoke or remediate violations
- Substitute for ISC violation certification
