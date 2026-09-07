## Why

The Intro C4 draws the same seven nodes (Operator, Agent + entro-connect, Skill
catalog, Vendor CLI / MCP, Entro UI, Connector, Integration) for every Connect
run, so it says nothing about the Integration being connected — an operator
looking at a Microsoft run and an AWS run sees an identical picture. The one
question the picture should answer, what Entro needs configured on the vendor
side, is already answered by the locked catalog row: Typed action
`expectedChange` and `target`, locked Coverages, `connectionFields`, `hosting`.
Redrawing it from that row turns a decoration into the Intro's summary of the
work ahead.

## What Changes

**Intro C4 topology**
- From: one fixed run-machinery topology, identical every run
- To: the Configuration topology of the locked Integration — Identity object,
  permission grants, the vendor scopes those grants reach, the credential, and
  the Entro-side Connection and Connector
- Reason: the fixed picture carries no Integration-specific information
- Impact: non-breaking for Connect runs; every Intro and Connect log written
  after this change draws a different picture than before

**Where the nodes come from**
- From: literal fence copied out of `intro.md`
- To: node vocabulary in `intro.md`, filled per run from the locked row
- Reason: ~38 catalog rows already carry the facts; no catalog authoring needed
- Impact: `intro.md` in both `entro-connect` skill trees

Unchanged: mermaid `flowchart` fence, drawn in chat and in the Connect log, C4
roles via `classDef`, no ASCII arrows, no per-run `.drawio`, secret values never
drawn.

**Non-goals**
- No catalog schema change — no per-row diagram or override field
- No change to the c4-diagram skill, `design.md` diagrams, or the
  `architecture-diagrams` capability
- No change to Lock, Operator inputs, Prep, Typed action execution, or Operation
  mode
- No secrets in the agent session; the diagram names secret fields only

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `integration-automation`: the Intro C4 requirement changes from a fixed
  topology to the locked Integration's Configuration topology, with the node
  vocabulary and its derivation sources spelled out.
- `ubiquitous-language`: redefine the Term `Intro C4`; add Terms
  `Configuration topology` and `Identity object`.

## Impact

- `.agents/skills/entro-connect/intro.md` and its lockstep copy
  `skills/entro-connect/intro.md` — replace the fixed fence with the node
  vocabulary, derivation sources, and a worked example.
- `openspec/specs/integration-automation/spec.md` and
  `openspec/specs/ubiquitous-language/spec.md` — via delta specs.
- `entro-microsoft-ecosystem.md` — an existing Connect log holding the old
  fence; redraw so the repo shows the new shape.
- No code, API, or dependency impact; verification is `openspec validate --all`
  plus the repo's pytest suite.
