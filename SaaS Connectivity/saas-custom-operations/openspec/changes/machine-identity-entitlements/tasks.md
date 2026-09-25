## 1. SDK client

- [x] 1.1 Add `machineIdentities: MachineIdentitiesApi` to `SailPointClients` in `src/framework/types.ts` and construct it in `src/framework/sdk-factory.ts` (scenario: Machine identities client configured for machine identity entitlements)
- [x] 1.2 Stub `ctx.sdk.machineIdentities` on offline/test-mode RequestContext
- [x] 1.3 Unit test sdk-factory returns a configured `MachineIdentitiesApi` and existing `EntitlementsApi`

## 2. ISC machine-identities module

- [x] 2.1 Create `src/isc/machine-identities/` with barrel `index.ts`, list (paginated), get (including `userEntitlements`), and resolve-by-`identityId` (`id` then `cisIdentityId`)
- [x] 2.2 Send experimental header when the SDK method requires it (scenario: Experimental header sent when required)
- [x] 2.3 Add `offline-data.ts` fixtures
- [x] 2.4 Unit tests — list paginates (scenario: List paginates machine identities)
- [x] 2.5 Unit tests — get returns user entitlements (scenario: Get returns user entitlements)
- [x] 2.6 Unit tests — list API failure throws ConnectorError (scenario: List API failure surfaces error)
- [x] 2.7 Unit tests — resolve by id and cisIdentityId (scenarios: Match by machine identity id; Match by cisIdentityId)
- [x] 2.8 Unit tests — unknown identityId not found (scenario: Unknown identityId is not found)
- [x] 2.9 Confirm layout: wrappers live only under `src/isc/machine-identities/` (scenario: Machine identities API separated)

## 3. ISC entitlements module

- [x] 3.1 Create `src/isc/entitlements/` with barrel `index.ts` and list-by-value using `listEntitlementsV1` + OData escape
- [x] 3.2 Add offline fixtures
- [x] 3.3 Unit tests — value equality match returns id and source id (scenario: Value equality match)
- [x] 3.4 Unit tests — no match returns empty list (scenario: No match returns empty list)
- [x] 3.5 Unit tests — quoted values escaped (scenario: Quotes in value are escaped)
- [x] 3.6 Unit tests — API failure throws ConnectorError (scenario: API failure surfaces error)
- [x] 3.7 Confirm layout: wrappers live only under `src/isc/entitlements/` (scenario: Entitlements API separated)

## 4. Machine identity entitlements operation

- [x] 4.1 Copy `src/operations/_template/` to `src/operations/machine-identity-entitlements/` with `command: 'custom:machine-identity-entitlements'`, optional input `identityId`, namespaced `output`, optional `response` counts
- [x] 4.2 Implement schema opt-in: cache account schema by sourceId; skip missing/blank `configuration.inboundEntitlements` or missing attribute (scenarios: Schema without inboundEntitlements is skipped; Unknown attribute name is skipped)
- [x] 4.3 Implement value extraction for single- and multi-valued attributes, trim/drop blanks, union across processable underlying accounts (scenarios: Single-valued inbound attribute is read; Multi-valued inbound attribute drops blanks; Values union across processable accounts)
- [x] 4.4 List underlying accounts with `identityId eq` using `cisIdentityId ?? id`; document mapping in README if live tenant differs (design D8)
- [x] 4.5 Match catalog entitlements, dedupe, compute entitlements to add vs `userEntitlements` (scenarios: Value matches catalog entitlement; Unmatched value is skipped; Already assigned entitlement omitted; Duplicate values collapse)
- [x] 4.6 Persist only non-empty add lists at `{requestId}:{machineIdentityId}` with parallel entitlement-ids and entitlement-source-ids (scenarios: Full scan persists one trigger account per identity with work; Empty delta skips persist; Output contract is identity and parallel entitlement arrays)
- [x] 4.7 Optional `identityId`: resolve one MI or ConnectorError; omit `identityId` for full scan; empty work succeeds with no persist (scenarios: Optional identityId limits the scan; Targeted unknown identity rejected; Tenant scan with no work succeeds)
- [x] 4.8 Offline path uses canned data without ISC calls (scenario: Offline invoke supported)
- [x] 4.9 Run `npm run codegen:schemas` so auto-registry and `connector-spec.json` include the command (scenarios: Auto-discovery registration; Machine identity entitlements follows namespacing convention)

## 5. Bundled apply workflow

- [x] 5.1 Add `workflows/` export: Account Created on result source, filter `operationName == custom:machine-identity-entitlements` (scenario: Trigger filters on operationName)
- [x] 5.2 GET machine identity then PATCH `userEntitlements` as union of existing + persisted add list (scenario: Patch unions user entitlements)
- [x] 5.3 Workflow variable Delete Trigger Account default false; delete trigger account only after successful patch when true (scenarios: Delete trigger account off by default; Delete trigger account after successful patch)
- [x] 5.4 `workflows.spec.ts` asserting trigger filter, PATCH union (not replace-only), and delete gating

## 6. Payloads and local invoke

- [x] 6.1 Add `payloads/` examples (offline scan, connected scan, connected `identityId`)
- [x] 6.2 Confirm `call:op` resolves the handler from codegen `OPERATION_HANDLERS` (no manual map)

## 7. Verification

- [x] 7.1 Confirm canonical test command: `npm test`
- [x] 7.2 Run `npm run typecheck`
- [x] 7.3 All delta spec scenarios covered by named automated tests
- [x] 7.4 `npm run pack-zip` (or project spcx pack script) succeeds with the new command in the bundle

## 8. Documentation

- [x] 8.1 Write `src/operations/machine-identity-entitlements/README.md` (command, inputs, persist identity, outputs, inbound entitlements attribute, workflow, PAT scopes, Accounts `identityId` mapping) (scenario: Operation README documents contract)
- [x] 8.2 Update root README operations table with `custom:machine-identity-entitlements`
- [x] 8.3 JSDoc on public `src/isc/machine-identities/` and `src/isc/entitlements/` exports
- [x] 8.4 Confirm C4 diagram remains linked from the change design (`diagrams/machine-identity-entitlements.drawio`)

## 9. Changelog

- [x] 9.1 Create or update CHANGELOG entry via changelog-generator skill during apply
- [x] 9.2 Confirm entry covers `custom:machine-identity-entitlements`, schema opt-in, persist cardinality, and the bundled Account Created apply workflow
