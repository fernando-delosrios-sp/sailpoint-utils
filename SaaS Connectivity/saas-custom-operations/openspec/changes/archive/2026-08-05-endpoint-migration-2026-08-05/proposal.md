## Why

ABB POV workflows call an external Express service (`isc-custom-endpoint`) because ISC workflow steps cannot consume nested JSON from connector invoke responses. The `saas-custom-operations` foundation provides `ctx.persist()` with flat string slots and Get Accounts read-back — the correct integration pattern. Migrating the four Express endpoints into custom connector operations removes external infrastructure and aligns with the dummy-source result model.

## What Changes

- Port four Express routes to `custom:*` commands using `sailpoint-api-client` SDK loopback only
- Assimilate upstream workflow HTTP steps (access-request-status fetch, outliers, item metadata) into operations
- Assimilate Compare Strings routing and email/comment formatting to minimize persisted params
- Deliver migrated workflow JSON under root `workflows/`
- Persist threshold analytics via `custom:access-request-threshold`; defer persist for `custom:check-sod-pending` until a calling workflow exists

## Capabilities

### Modified Capabilities

- `connector-operations`: Four new custom commands with documented input/output contracts
- `target-client`: Expand SDK factory beyond AccountsApi
- `connector-config`: Declare new commands in manifest

## Impact

- `src/framework/sdk-factory.ts`, `src/framework/types.ts`
- `src/services/*`, `src/operations/*`
- `connector-spec.json`, `workflows/*`
- `abb-pov` workflows superseded by `workflows/` exports

