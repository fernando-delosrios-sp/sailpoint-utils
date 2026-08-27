## Why

ISC workflows frequently need governance group member email lists—for BCC on approval notifications, distribution lists, or escalation paths. Today teams implement this with multi-step HTTP actions (search workgroup by name, list members, map to emails). The saas-custom-operations scaffold has no governance-group helper, while the ABB branch proved the pattern works. Publishing it as a reusable custom operation reduces workflow complexity and keeps email resolution in one tested place.

## What Changes

- Add **`custom:governance-group-emails`** — resolves a governance group by name and persists member email addresses.
- Add **`src/isc/governance-groups/`** — ISC loopback client for workgroup lookup and member listing.
- Add operation subdirectory under `src/operations/governance-group-emails/` with README, payloads, and auto-registration via `command` literal.

**Operation contract**
- Input: `groupName` (required)
- Output (persisted): `governance-group-emails:emails` — string array of member email addresses (non-empty entries only)

**Explicit non-goals**
- Approval routing or risk-based email logic (ABB access-request-status)
- Caching or batch resolution of multiple groups in one invoke

## Capabilities

### New Capabilities

- `connector-operations/governance-group-emails`: Register and specify behavior of `custom:governance-group-emails`

### Modified Capabilities

- `connector-operations`: Namespaced persist output keys (`{slug}:{field}`) for all custom operations
- `target-client`: Add governance-groups ISC client surface (workgroup search by name, member email listing)

## Impact

- New: `src/operations/governance-group-emails/`, `src/isc/governance-groups/`, invoke payloads under `payloads/`
- Modify: `connector-spec.json` (codegen from auto-registry), root README operations table, CHANGELOG
- Tests: unit tests for governance-groups client and operation handler (mocked SDK)
- External: requires token scopes for governance group read APIs
