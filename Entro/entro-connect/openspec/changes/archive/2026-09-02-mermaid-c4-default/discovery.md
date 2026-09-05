## Scope

In: make Mermaid `flowchart` the only C4 format for OpenSpec design, the
c4-diagram skill, and Connect Intro. Out: converting existing `.drawio` files,
native `C4Container` syntax, draw.io sidecars, PNG/SVG export pipelines, and
Connect-run diagrams that differ per Integration.

## Language

**C4 flowchart** (`promote`):
A mermaid `flowchart` whose nodes and subgraphs map to C4 Container roles
(Person, Container, Database, External System, system boundary). It is the
architecture picture that GitHub and chat actually draw.
_Avoid_: C4Container / C4Context as the default syntax; ASCII arrow sketches
called C4; `.drawio` as the default artifact

**Intro C4** (`draft`):
The same five-box topology every Connect run (Operator, Agent + entro-connect,
Skill catalog, Vendor CLI / MCP, Entro UI, Connector → Integration), expressed
as a C4 flowchart in chat and the Connect log.
_Avoid_: a per-run fuller container diagram; a `.drawio` beside the Connect log

## Decisions

Context: `.drawio` C4s do not render in Markdown preview; Connect Intro labeled
ASCII as C4. Operator wants Mermaid as the default, everywhere.

Q1 Surfaces → **all-surfaces**: OpenSpec `design.md`, c4-diagram skill, Connect
Intro.

Q2 Dialect → **flowchart-c4**: mermaid `flowchart` styled as C4, not experimental
`C4Container` (GitHub often leaves that as source).

Q3 `.drawio` → **drop-drawio**: skill and ferspec stop generating draw.io. No
optional sidecar.

Q4 Intro fidelity → **same-five-boxes**: one topology every run, now a mermaid
fence.

Q5 Location → **inline-design**: mermaid fence in `design.md` §Architecture, not
a `diagrams/` sidecar.

Q6 Existing files → **leave-historical**: new work is Mermaid-only; existing
`.drawio` stays.

## Open questions

None. Existing `.drawio` conversion is deferred (never in this change).
Published skill-pack copies of c4-diagram outside this repo follow this repo’s
skill files when those packs are next synced — not a blocking TBD.

## Scenarios discussed

- Operator opens `design.md` on GitHub or in Cursor preview and sees a drawn
  diagram, not XML or a download.
- Agent emits a Connect Intro; chat and `entro-*.md` contain a mermaid fence
  with the five-box topology.
- Agent asked for a C4 during design writes mermaid into `design.md`, not
  `diagrams/<change>.drawio`.
- Viewer without mermaid still sees the source fence (readable), not a broken
  image link.
- Historical `.drawio` links on older changes still open in draw.io; this change
  does not rewrite them.
- Someone asks for an editable draw.io file: out of scope; skill no longer
  produces it.
