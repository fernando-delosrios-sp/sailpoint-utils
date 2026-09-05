## Why

Architecture pictures labeled C4 do not draw where operators read them. Design
docs link `.drawio` XML; Connect Intro dumps ASCII arrows. Mermaid `flowchart`
already renders in GitHub and chat. Make that the only C4 format so the next
preview is a diagram, not source.

## What Changes

**Design C4**
- From: c4-diagram writes `diagrams/<change>.drawio`; `design.md` links the file
- To: mermaid `flowchart` (C4 roles via nodes/subgraphs) inline in `design.md` §Architecture
- Reason: Markdown preview never draws draw.io
- Impact: ferspec schema + templates; c4-diagram skill; non-breaking for historical files

**Connect Intro C4**
- From: fixed five-box ASCII in chat and Connect log
- To: the same five boxes as a mermaid fence (Intro C4)
- Reason: same topology, actually renders
- Impact: `entro-connect` intro + integration-automation Intro requirement

**draw.io generation**
- From: default artifact for 3+ containers
- To: not generated
- Reason: operator chose Mermaid-only
- Impact: skill and schema drop XML templates

## Non-goals

No conversion of existing `.drawio`. No native `C4Container` syntax. No PNG/SVG
export. No per-run richer Intro diagrams. No secrets handling. No CLI automation
of Integrations.

## Capabilities

### New Capabilities

- `architecture-diagrams`: C4 flowchart is the only generated Container-level
  picture (ferspec design instruction, c4-diagram skill, no `.drawio`).

### Modified Capabilities

- `ubiquitous-language`: add C4 flowchart and Intro C4.
- `integration-automation`: Intro SHALL show the Intro C4 as mermaid, not ASCII.

## Impact

`.agents/skills/c4-diagram/`, `.agents/skills/entro-connect/intro.md` (and the
`skills/` copy if kept in sync), `openspec/schemas/ferspec/schema.yaml` and
`templates/design.md`, plus openspec-init schema copies in this repo. GitHub
and Cursor mermaid preview become the renderers. Draw.io is no longer a
dependency for new work.
