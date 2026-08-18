# target-client/sod-policies Specification

## Purpose

Generic SoD policy helpers under `src/isc/sod-policies/` for listing and fetching policies and resolving conflicting access sides. This module SHALL NOT encode operation-specific form or persist logic.

## Requirements

### Requirement: SoD policies client module

The connector SHALL provide generic SoD policy helpers under `src/isc/sod-policies/` for listing and fetching policies and resolving conflicting access sides. The module SHALL NOT encode operation-specific form or persist logic.

#### Scenario: List policies with filter

- **GIVEN** a configured SodPolicies API client and filter `state eq "ENFORCED"`
- **WHEN** `listSodPolicies` is invoked with pagination
- **THEN** the function SHALL call the Sod Policies list API
- **AND** SHALL return all pages of matching policies

#### Scenario: Get policy by id

- **GIVEN** policy id `policy-p`
- **WHEN** `getSodPolicy` is invoked
- **THEN** the function SHALL fetch the policy via `GET /sod-policies/v1/{id}` (or SDK equivalent)
- **AND** SHALL return `policyQuery`, `conflictingAccessCriteria`, `ownerRef`, and `name`

#### Scenario: Parse policyQuery sides

- **GIVEN** `policyQuery` string `@access(id:ent-a OR id:ent-b) AND @access(id:ent-c OR id:ent-d)`
- **WHEN** `parsePolicyQuerySides` is invoked
- **THEN** the function SHALL return group A entitlement ids `[ent-a, ent-b]` and group B entitlement ids `[ent-c, ent-d]`
- **AND** top-level AND SHALL separate sides
- **AND** OR within each `@access(...)` clause SHALL union entitlement ids on that side

#### Scenario: Structured criteria fallback

- **GIVEN** a policy with unparseable `policyQuery`
- **AND** `conflictingAccessCriteria.leftCriteria.criteriaList` contains entitlement `ent-a`
- **AND** `conflictingAccessCriteria.rightCriteria.criteriaList` contains entitlement `ent-c`
- **WHEN** `resolvePolicySides` is invoked
- **THEN** the function SHALL return group A `[ent-a]` and group B `[ent-c]`

#### Scenario: Unresolvable policy sides skipped

- **GIVEN** a policy where neither `policyQuery` nor `conflictingAccessCriteria` yields two non-empty sides
- **WHEN** `resolvePolicySides` is invoked
- **THEN** the function SHALL return null or an empty result indicating the policy cannot be evaluated

#### Scenario: Policy owner identity extraction

- **GIVEN** a policy with `ownerRef.type` `IDENTITY` and `ownerRef.id` `owner-z`
- **WHEN** `resolvePolicyOwnerId` is invoked
- **THEN** the function SHALL return `owner-z`

#### Scenario: Offline stub policies

- **GIVEN** offline/testMode invocation
- **WHEN** list or get policy helpers are invoked via offline entry points
- **THEN** the functions SHALL return deterministic canned policies suitable for access-sod-remediation tests
- **AND** SHALL NOT call ISC APIs

#### Scenario: API folder barrel entry

- **GIVEN** the connector source tree under `src/isc/sod-policies/`
- **WHEN** a developer inspects the module
- **THEN** the folder SHALL contain `index.ts` exporting public list, get, parse, and owner helpers
- **AND** offline stub data SHALL reside in `offline-data.ts` separate from parse logic
