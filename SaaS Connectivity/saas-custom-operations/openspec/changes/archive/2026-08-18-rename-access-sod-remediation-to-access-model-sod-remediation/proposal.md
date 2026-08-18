## Why

The slug `access-sod-remediation` reads like a variant of `sod-remediation` (identity violation response) rather than what the operation actually does: scan the access model—roles and access profiles—for intrinsic SoD policy violations. The ambiguous name causes confusion in specs, workflows, and persist namespaces. Renaming to `access-model-sod-remediation` aligns the command and output keys with the access-model scope and distinguishes the operation clearly from `custom:sod-remediation`.

## What Changes

**Custom command identifier**
- From: `custom:access-sod-remediation`
- To: `custom:access-model-sod-remediation`
- Reason: Reflect access-model scan scope; reduce confusion with identity SoD remediation
- Impact: **Breaking** — ISC workflows, schedules, and invoke payloads must use the new command name

**Operation source directory**
- From: `src/operations/access-sod-remediation/`
- To: `src/operations/access-model-sod-remediation/`
- Reason: Directory name follows command slug convention
- Impact: Non-breaking for runtime; import paths and auto-registry update on build

**Persist output namespace**
- From: `access-sod-remediation:*` (e.g. `access-sod-remediation:violations-found`)
- To: `access-model-sod-remediation:*`
- Reason: Persist keys mirror command slug per namespacing convention
- Impact: **Breaking** — Get Accounts / workflow JSONPath must update to new attribute names

**OpenSpec capability path**
- From: `connector-operations/access-sod-remediation`
- To: `connector-operations/access-model-sod-remediation`
- Reason: Spec tree matches operation slug
- Impact: Archive replaces old capability directory with renamed one

**Offline payload and seed filenames**
- From: `payloads/access-sod-remediation-offline.json`, `access-sod-remediation.seed.json`
- To: `payloads/access-model-sod-remediation-offline.json`, `access-model-sod-remediation.seed.json`
- Reason: Filename convention matches command slug
- Impact: **Breaking** for local `call:op` scripts referencing old payload path

**Explicit non-goals**
- Dual-write of old command or persist keys
- Migration of existing persisted accounts in ISC
- Renaming `custom:sod-remediation` or shared `sod-form-html` module paths
- Behavior changes to violation detection, form launch, or email outputs

## Capabilities

### New Capabilities

- `connector-operations/access-model-sod-remediation`: Renamed access-model SoD scan operation — same requirements as former `access-sod-remediation` under the new command, directory, and persist namespace

### Modified Capabilities

- `connector-operations/access-sod-remediation`: Remove all requirements (capability superseded by rename)
- `ubiquitous-language`: Update SoD form HTML, form email recipients, and related scenario references from `custom:access-sod-remediation` to `custom:access-model-sod-remediation`
- `target-client`: Update prose references in roles, access-profiles, sod-policies, and root spec scenarios from `access-sod-remediation` to `access-model-sod-remediation`

## Impact

- Rename: `src/operations/access-sod-remediation/` → `src/operations/access-model-sod-remediation/` (all modules, tests, README, seed)
- Modify: `src/operations/auto-registry.ts`, `connector-spec.json` (codegen sync)
- Rename: `payloads/access-sod-remediation-offline.json` → `payloads/access-model-sod-remediation-offline.json`
- Modify: `payloads/fer.json`, root `README.md`, `CHANGELOG.md`, cross-references in `src/lib/sod-form-html/`, `scripts/call-op.ts`, `src/isc/forms/forms.spec.ts`
- Specs: delta for new capability ADDED, old capability REMOVED, ubiquitous-language and target-client MODIFIED
- Tests: `npm test` — update command literals, persist key assertions, schema expectations
- External: deployed ISC workflows invoking `custom:access-sod-remediation` or reading `access-sod-remediation:*` attributes must update before relying on post-upgrade connector output
