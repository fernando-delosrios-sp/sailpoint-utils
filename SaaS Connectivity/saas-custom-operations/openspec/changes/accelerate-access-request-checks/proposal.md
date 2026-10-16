## Why

The Access Request Pre-Check workflow runs `custom:evaluate-access-request-risk` and `custom:preventive-sod-check` serially, then waits for two result-account indexes before deciding. Inside each operation, ISC reads for roles, access profiles, entitlements, events, and SoD policies are mostly sequential, and request-mode SoD expands overlapping entitlement sets twice. Under a real request with nested roles the critical path stretches past trigger deadlines. Parallelizing independent reads and collapsing the pre-check into one invoke that returns both verdicts in the HTTP response removes the largest fixed costs without changing the standalone operation contracts other workflows still use.

## What Changes

**Evaluator latency**

- From: serial walks over requested items, nested entitlements, event searches, entitlement expansions, and policy-level lookups; request-mode SoD expands baseline items twice before two predict calls.
- To: bounded concurrency with in-flight memoization for independent ISC reads; baseline entitlement expansion once; baseline and full predict run concurrently when both are needed.
- Impact: same scores and SoD deltas; fewer wall-clock seconds on the critical path. Throttle retries stay intact.

**Combined pre-check command**

- From: the bundled pre-check invokes two commands, polls two result accounts, and may wait a minute per missing read.
- To: one `custom:access-request-precheck` command that evaluates risk and preventive SoD concurrently, returns both result sets in the invoke `summary`, and writes one audit account under `access-request-precheck:{accessRequestId}:submitted` without waiting for provisioning verification.
- Impact: bundled pre-check workflow is rewritten around the response body. Standalone risk and SoD commands remain for Dynamic Approver and other callers.

## Capabilities

### New Capabilities

- `connector-operations/access-request-precheck`: combined risk + preventive SoD evaluation for the Access Request Submitted pre-check path.

### Modified Capabilities

- `connector-operations/evaluate-access-request-risk`: documents that independent catalog reads MAY run with bounded concurrency and in-flight memoization; scoring semantics unchanged.
- `connector-operations/preventive-sod-check`: documents concurrent event resolution, single baseline expansion, concurrent predicts, and concurrent policy-level attachment; output semantics unchanged.

## Impact

Code: risk `evaluate.ts` / `catalog.ts`, preventive `pending-grants.ts`, shared expansion in `isc/sod-prediction`, policy levels, new `src/operations/access-request-precheck/`, auto-registry, connector-spec, bundled pre-check workflow JSON and its contract tests.

Ops: redeploy the connector and re-import the Access Request Pre-Check workflow in one window. Dynamic Approver and Dynamic Approval Workflow keep calling `custom:evaluate-access-request-risk` unchanged.
