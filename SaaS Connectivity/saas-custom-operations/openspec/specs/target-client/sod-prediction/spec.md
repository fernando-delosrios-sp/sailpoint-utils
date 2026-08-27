# target-client/sod-prediction Specification

## Purpose
TBD - created by archiving change preventive-sod-check. Update Purpose after archive.
## Requirements
### Requirement: SoD violation prediction client

The isc sod-prediction module SHALL predict SoD violations for an identity with additional entitlement access via `SODViolationsApi.startPredictSodViolationsV1`. The module SHALL reside under `src/isc/sod-prediction/` and SHALL NOT encode access request discovery or situation summary logic.

#### Scenario: Predict violations for identity and entitlements

- **GIVEN** a configured `SODViolationsApi`, identity id `{identityId}`, and entitlement ids `[ent-a, ent-b]`
- **WHEN** `predictSodViolationsForIdentity` is invoked
- **THEN** the function SHALL call `startPredictSodViolationsV1` with `identityWithNewAccess.identityId` set to `{identityId}`
- **AND** SHALL set each `accessRefs` entry to type `ENTITLEMENT` with the corresponding entitlement id
- **AND** SHALL return the `ViolationPrediction` response

#### Scenario: Parse violated policy names

- **GIVEN** a `ViolationPrediction` response containing violated policies with names `Policy A` and `Policy B`
- **WHEN** `parseViolatedPolicyNames` is invoked
- **THEN** the function SHALL return `["Policy A", "Policy B"]`
- **AND** SHALL preserve API order when deduplicating duplicate names

#### Scenario: Empty entitlement list short-circuit

- **GIVEN** zero entitlement ids to evaluate
- **WHEN** `predictSodViolationsForIdentity` is invoked
- **THEN** the function SHALL NOT call `startPredictSodViolationsV1`
- **AND** SHALL return an empty violated policy name list

#### Scenario: Entitlement expansion before predict

- **GIVEN** pending access items include one ROLE and one ACCESS_PROFILE reference
- **WHEN** `expandAccessItemsToEntitlementIds` is invoked with configured roles and access-profiles clients
- **THEN** the function SHALL delegate role expansion to `src/isc/roles/`
- **AND** SHALL delegate access profile expansion to `src/isc/access-profiles/`
- **AND** SHALL pass through ENTITLEMENT ids unchanged
- **AND** SHALL return a deduplicated entitlement id list suitable for predict

#### Scenario: Predict API failure surfaces error

- **GIVEN** the predict API returns 403 or 500
- **WHEN** `predictSodViolationsForIdentity` is invoked
- **THEN** the function SHALL throw `ConnectorError` describing the HTTP status

#### Scenario: Offline stub prediction

- **GIVEN** test mode or offline invocation without apiUrl and token
- **WHEN** `predictSodViolationsForIdentityOffline` is invoked
- **THEN** the function SHALL return deterministic offline violation prediction results suitable for local operation tests
- **AND** SHALL NOT call ISC APIs

#### Scenario: API folder barrel entry

- **GIVEN** the connector source tree under `src/isc/sod-prediction/`
- **WHEN** a developer inspects the module
- **THEN** the folder SHALL contain `index.ts` exporting public predict helpers and types
- **AND** offline stub data SHALL reside in `offline-data.ts` separate from predict orchestration logic

