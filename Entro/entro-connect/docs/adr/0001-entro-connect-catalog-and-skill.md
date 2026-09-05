# ADR-0001: Skill catalog copy and self-contained Connect data

## Status

Superseded by [ADR-0002](0002-skill-catalog-tree.md) for the Skill catalog layout (single JSON file). The one-skill rule and “do not read `documentation/` pages” still hold.

## Context

The Integration index already named Add New Account targets, Coverages, and Configuration tools. Operators still had to open GitBook pages to learn Connection details and Prep steps. The entro-connect skill must run when `documentation/` markdown is absent, and must never put secrets in agent context or git.

## Decision Drivers

- One skill, catalog is data (no per-integration skills)
- Skill must not open `documentation/` pages
- Hand-maintained skill JSON goes stale
- Worker Group is always required; other Entro labels are not universal
- Commands in JSON rot; distilled `instruction` and `obtainedHow` do not

## Considered Options

### Option 1: Skill reads `documentation/integrations.json` plus ingested pages

- **Pros**: Single JSON file
- **Cons**: Pages unavailable to the skill; agents follow dead paths

### Option 2: Hand-maintained skill JSON

- **Pros**: Skill folder is self-contained
- **Cons**: Diverges from the ingest index

### Option 3: Same writer emits ingest index and Skill catalog; rows carry self-contained fields and steps

- **Pros**: One authoring module; tests fail on stale skill copy; Connect run needs no documentation tree
- **Cons**: Two JSON files to generate

## Decision

`integration_catalog.py` writes `documentation/integrations.json` (ingest index, may keep page paths) and `.agents/skills/entro-connect/integrations.json` (Skill catalog). Every row has `summary`, `connectionFields` `{name, secret, obtainedHow}`, and `prepSteps` `{title, instruction, evidence}` on Setup methods or the row. Coverages may add steps; empty Coverage `prepSteps` means inherit. Worker Group is a global field-map rule, not a per-row JSON field. The Skill catalog omits `documentation/` markdown paths. entro-connect reads only the Skill catalog.

A Connect run creates the Connect log after Lock, collects Operator inputs, persists Intro before Operation mode, and offers automated only when every selected Prep step has a Typed action and required tools have presence, Capability probe, auth-check, and Platform identity. Fit `preferred` without that complete plan is corrected to `usable` or `none`. Automated announces each Typed action and runs it itself, secret-producing ones included, routing that output to a Secret sink so no secret enters agent context; supervised discloses each action behind an Approve / adjust / stop gate and the operator runs it. External scripts are pinned (URL, version, checksum) and reviewed before execute. A collision or replacement stops before overwrite, gates the proposed fix, and retries; hardcoded names or menu choices use a disposable copy after the pinned original passes checksum.

## Consequences

### Positive

- A Connect run works without the documentation tree
- Stale or missing Skill catalog fails validation
- Secrets stay named, not valued, in JSON and Connect logs

### Negative

- Curating every row is apply-time work
- Duplicate JSON on disk (generated, not hand-edited)
