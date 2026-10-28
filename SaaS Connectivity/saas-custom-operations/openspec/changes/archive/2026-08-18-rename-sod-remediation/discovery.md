## Scope

Rename the `custom:access-sod-remediation` custom operation to `custom:access-model-sod-remediation` everywhere in code, specs, persist output keys, payloads, and documentation. Behavior is unchanged; only identifiers change. Out of scope: dual-write of old keys, migration of existing persisted accounts in ISC, and renaming `custom:sod-remediation`.

## Language

**Access model SoD remediation** (`promote`):
The proactive catalog scan operation that detects intrinsic SoD violations on roles and access profiles and creates policy-owner remediation forms. Replaces the draft name "access SOD remediation" tied to the `access-sod-remediation` slug.
_Avoid_: access-sod-remediation (deprecated slug), access catalog sod remediation (informal)

**Access model SoD remediation command** (`promote`):
The ISC custom command identifier `custom:access-model-sod-remediation`. Replaces `custom:access-sod-remediation`.
_Avoid_: custom:access-sod-remediation (deprecated)

**Access model SoD remediation persist namespace** (`promote`):
The operation output key prefix `access-model-sod-remediation:` on parent and child persist accounts. Replaces `access-sod-remediation:`.
_Avoid_: access-sod-remediation: (deprecated prefix)

**SoD form HTML** (`conflicts-with-canonical`):
Canonical term unchanged; ubiquitous-language delta updates Notes and scenarios to `custom:access-model-sod-remediation`.

**Form email recipients** (`conflicts-with-canonical`):
Canonical term unchanged; scenario and Notes reference old command — delta will update.

## Decisions

**Context**: The operation scans roles and access profiles (the access model) for intrinsic SoD violations. The slug `access-sod-remediation` is ambiguous and overlaps conceptually with `sod-remediation` (identity violations).

**Q1 — Rename scope**: Command name only, or full slug including directory and persist keys?
**Chosen**: Full slug rename — command (`custom:access-model-sod-remediation`), source directory (`src/operations/access-model-sod-remediation/`), persist namespace (`access-model-sod-remediation:*`), offline payload and seed filenames, and OpenSpec capability path (`connector-operations/access-model-sod-remediation`).

**Q2 — Backward compatibility**: Dual-write old persist keys or register both commands?
**Chosen**: No dual-write. Clean breaking rename with CHANGELOG migration note. Consumers update workflows and JSONPath before/after upgrade.

**Q3 — Spec capability path**: Modify in place or rename directory?
**Chosen**: Rename capability directory at archive from `access-sod-remediation` to `access-model-sod-remediation`; delta specs use the new path with ADDED requirements and old path with REMOVED requirements.

## Open questions

None — scope and compatibility approach are locked.

## Scenarios discussed

- **Workflow command reference**: ISC scheduled or event-triggered workflows invoking `custom:access-sod-remediation` must switch to `custom:access-model-sod-remediation` after connector upgrade.
- **Persist key migration**: Existing child accounts with `access-sod-remediation:*` attributes are not migrated; new runs write `access-model-sod-remediation:*`. Workflows reading old keys need updating.
- **Auto-registry codegen**: Renaming `index.ts` `command` literal triggers schema regen and connector-spec.json sync on build.
- **Cross-references**: README, CHANGELOG, ubiquitous-language, target-client specs, sod-form-html comments, and `payloads/fer.json` must be updated in one pass.
- **Test describe blocks**: Vitest suite names may reference old path for clarity but are non-contractual.
