## Scope

Redefine the Intro C4 from one fixed run-machinery topology into a per-run
picture of the configuration the locked Integration needs, derived from the
locked catalog row; out of scope are the catalog schema, the c4-diagram skill,
`design.md` diagrams, and any change to Prep or Typed action execution.

## Language

**Intro C4** (`conflicts-with-canonical`):
The Connect Intro architecture picture: one mermaid `flowchart` fence drawing
the Configuration topology of the locked Integration. The canonical Term in
`openspec/specs/ubiquitous-language/spec.md` still defines it as the same
topology every run (Operator, Agent + entro-connect, Skill catalog, Vendor CLI /
MCP, Entro UI, Connector, Integration); this change replaces that definition.
_Avoid_: run diagram, session diagram, five-box topology

**Configuration topology** (`promote`):
What the locked Integration must have configured on the vendor side for Entro to
connect, and how Entro reaches it: the Identity object Entro authenticates as,
the permission grants attached to it, the vendor scopes those grants reach, the
credential the operator carries to Entro, and the Entro-side Connection and
Connector. Derived per run from the locked row's Typed actions, Coverages, and
Connection details.
_Avoid_: integration architecture, deployment topology, connection flow

**Identity object** (`draft`):
The vendor-side principal Entro authenticates as — an Entra app registration, an
AWS IAM role, an Okta API service app. It is the node every other Configuration
topology node hangs off.
_Avoid_: service account, connector identity

## Decisions

Context: the Intro C4 draws the same seven nodes for every Integration, so it
tells the operator nothing about the Integration being connected. Every fact it
could show is already in the locked row.

Q1 — What should the diagram depict? The configuration Entro needs on the vendor
side, not how a Connect run is machined.

Q2 — Derived or authored? **Derived at run time.** `intro.md` fixes a node
vocabulary and the agent fills it from the locked row. Rejected: authoring a
diagram per catalog row (deterministic, but ~38 rows to author before it pays
off) and a hybrid with a catalog override field (adds a schema field before any
row is known to need it).

Q3 — Do Operator, Agent + entro-connect, Skill catalog, and Vendor CLI / MCP
stay? **No — configuration only.** The picture is vendor objects, what they
reach, and the Entro side. Rejected: keeping the Operator as the actor who
creates the objects, and keeping both layers as two subgraphs.

Q4 — Where do the nodes come from? Typed action `expectedChange` and `target`
give the Identity object, the permission grants, and the vendor scopes; locked
Coverages give what the grants reach; `connectionFields` give the credential and
the Entro-side Connection; `hosting` gives the Connector kind.

Q5 — What survives from the current requirement? Mermaid `flowchart` fence, both
in chat and in the Connect log, C4 roles via `classDef`, no ASCII arrows, no
per-run `.drawio`.

## Open questions

None blocking. Deferred: whether a catalog row whose Typed actions are too thin
to name an Identity object needs a catalog override field — revisit if a row
turns up that derives badly.

## Scenarios discussed

- Microsoft Ecosystem with the Copilot Studio Coverage locked: Entra app
  registration, admin-consented Graph permissions, Azure roles over subscriptions
  and management groups, client secret, SharePoint / OneDrive and Dataverse
  environments as reach, Entro Connection (Tenant ID, Client ID, Client Secret)
  behind a SaaS Perimeter Worker Group.
- A skipped Coverage MUST NOT appear as reach.
- A secret Connection detail appears as a node name only; no value is ever drawn.
- A row with a single Prep step and no Coverages still draws Identity object,
  grants, credential, and the Entro side.
- Playbook-only batch persists this Intro, so the Intro C4 is drawn there too.
