# Ubiquitous Language

## Purpose

Shared domain vocabulary for this project. All specs, design docs, code identifiers,
and user-facing copy MUST align with the terms defined here.
## Requirements
### Requirement: Glossary maintenance

The project SHALL maintain an authoritative glossary of domain terms with unambiguous
definitions, preferred spellings, and known aliases. When a term is superseded by a more
precise one, the glossary SHALL record the superseding term rather than silently broadening
the old definition.

#### Scenario: New term introduced in a change

- **GIVEN** a change proposal introduces a new domain concept or renames an existing one
- **WHEN** the change is approved for implementation
- **THEN** the term MUST be added or updated in this spec before the change archives

#### Scenario: Term used in a spec

- **GIVEN** a capability spec references a domain noun or verb
- **WHEN** the term is not yet defined in this glossary
- **THEN** the author MUST add the definition here or reuse an existing term instead

#### Scenario: Term superseded by a more precise one

- **GIVEN** an existing term is used for several distinct concepts in implementation artifacts
- **WHEN** a change introduces precise terms for those concepts
- **THEN** the old term MUST be marked as superseded, naming the terms that replace it

### Requirement: Consistent naming

Implementation artifacts (types, functions, API fields, database columns, UI labels)
SHALL use glossary terms verbatim unless a documented alias applies.

#### Scenario: Code review against glossary

- **GIVEN** an implementation uses a domain label visible to other systems or users
- **WHEN** the label differs from the glossary preferred spelling without an alias entry
- **THEN** the implementation MUST be corrected or the glossary MUST be updated first

### Requirement: Bounded context boundaries

When the same word means different things in different areas, each meaning MUST be
listed as a separate entry with its bounded context noted.

#### Scenario: Homonym disambiguation

- **GIVEN** two subsystems use the same word with different meanings
- **WHEN** both meanings appear in specs or code
- **THEN** each meaning MUST have its own glossary entry naming the bounded context

### Requirement: Entro API catalog terms

The glossary SHALL define Entro OpenAPI snapshot and Entro API catalog with the definitions in Term entries below. Documentation ingest Notes SHALL state that ingest covers both the GitBook markdown catalog and the Entro API catalog, and that the Entro OpenAPI snapshot is not a documentation-tree page.

#### Scenario: API ingest specs use canonical catalog terms

- **GIVEN** a change authors documentation-ingest requirements for the product API
- **WHEN** it names the committed OpenAPI file or the `{endpoint}/v1/docs` document
- **THEN** it MUST use Entro OpenAPI snapshot and Entro API catalog rather than swagger dump, portal HTML, or GitBook markdown catalog

#### Scenario: Documentation ingest names both sources

- **GIVEN** the glossary entry for Documentation ingest
- **WHEN** a reader uses that term after this change archives
- **THEN** the Notes MUST mention GitBook Integration pages and the Entro API catalog as ingest sources
- **AND** the Notes MUST NOT treat `documentation/api/openapi.yaml` as a documentation-tree page

### Requirement: Tile and Integration path terms

The glossary SHALL define Integration, Integration path, Optional capability,
and Capture required with the definitions in Term entries below. Add New Account
target, Setup method, Authentication method, and Coverage SHALL be marked
superseded as Lock dimensions.

#### Scenario: Catalog and Connect specs use tile-path vocabulary

- **GIVEN** a spec describes catalog identity, a mutually exclusive connection-form choice, an additional feature, or an uncaptured tile
- **WHEN** it names that concept
- **THEN** it MUST use Integration, Integration path, Optional capability, or Capture required respectively
- **AND** it MUST NOT use Add New Account target, Setup method, Authentication method, or Coverage as Lock dimensions

#### Scenario: Connector claims name their evidence

- **GIVEN** a spec or index row states whether a connection form needs a Worker Group
- **WHEN** the statement is recorded
- **THEN** it MUST use Connector requirement for the value and Requirement evidence for its citation

#### Scenario: Configuration tools are not conflated with methods

- **GIVEN** a change authors documentation-ingest requirements about operator binaries
- **WHEN** it names those binaries
- **THEN** it MUST use Configuration tool rather than Setup method or Authentication method

### Requirement: Hosting terms

The glossary SHALL define Hosting with the definition in Term entries below.
Notes MUST state that Connector deployment is derived from Hosting and MUST NOT
be stored on an Integration index row.

#### Scenario: Index specs name hosting not connector type

- **GIVEN** a change authors documentation-ingest requirements about the Integration index
- **WHEN** it describes how an operator picks Docker Compose, Kubernetes Helm, or SaaS Perimeter
- **THEN** it MUST use Hosting for the row attribute and Connector deployment for the derived topology
- **AND** it MUST NOT require a stored topology list on the row

### Requirement: Connector requirement terms are superseded

The glossary SHALL mark Connector requirement and Requirement evidence as superseded.
Notes MUST state that a connector is always required for an Integration and
that runtime topology is Connector deployment, documented at product level.

#### Scenario: Index specs do not use Connector requirement

- **GIVEN** a change authors documentation-ingest requirements about the Integration index
- **WHEN** it describes a target row
- **THEN** it MUST NOT require `connectorRequirement` or `connectorEvidence`
- **AND** it MUST NOT use Connector requirement or Requirement evidence as live terms

### Requirement: C4 flowchart terms

The glossary SHALL define C4 flowchart and Intro C4 with the definitions in Term
entries below.

#### Scenario: Specs use C4 flowchart not draw.io as the default

- **GIVEN** a change authors design or skill requirements about a Container-level
  architecture picture
- **WHEN** it names that picture
- **THEN** it MUST use C4 flowchart
- **AND** it MUST NOT treat `.drawio` or mermaid `C4Container` as the canonical
  format

#### Scenario: Specs use Intro C4

- **GIVEN** a change authors entro-connect requirements about the diagram in
  Intro
- **WHEN** it names that diagram
- **THEN** it MUST use Intro C4
- **AND** it MUST NOT call ASCII arrows the Intro C4
- **AND** it MUST NOT define the Intro C4 as one fixed topology repeated every
  run

### Requirement: Configuration topology terms

The glossary SHALL define Configuration topology and Identity object with the
definitions in Term entries below.

#### Scenario: Specs use Configuration topology

- **GIVEN** a change authors entro-connect requirements about what a locked
  Integration must have configured for Entro to connect
- **WHEN** it names that shape
- **THEN** it MUST use Configuration topology
- **AND** it MUST NOT call it the integration architecture or the connection flow

#### Scenario: Specs use Identity object

- **GIVEN** a change authors requirements about the vendor-side principal Entro
  authenticates as
- **WHEN** it names that principal
- **THEN** it MUST use Identity object
- **AND** it MUST NOT call it a service account or a connector identity

### Requirement: Skill-held onboarding terms

The glossary SHALL define Skill-held onboarding artifact, Anonymous origin URL,
Local onboarding fork, Doc-derived Typed action, Operator-only step, Uncataloged
Prep step, Runtime Doc-derived action, Temporary script copy, Announcement, and
Secret sink with the definitions in Term entries below. Specs that describe
Connect script runtime SHALL use Skill-held onboarding artifact rather than
treating a GitBook URL as the bytes that run.

#### Scenario: Specs use Skill-held onboarding artifact

- **GIVEN** a change authors documentation-ingest or integration-prep requirements about vendor scripts, zips, or captured snippets
- **WHEN** it names the file Connect executes
- **THEN** it MUST use Skill-held onboarding artifact
- **AND** it MUST NOT describe GitBook download as Connect runtime

#### Scenario: Specs use Anonymous origin URL

- **GIVEN** a change authors ingest requirements about the remote address used to detect drift
- **WHEN** it names that address
- **THEN** it MUST use Anonymous origin URL
- **AND** it MUST NOT treat a URL that contains `token=` as valid

#### Scenario: Specs distinguish Doc-derived Typed action and Operator-only step

- **GIVEN** a Prep step that is not covered by a Skill-held file
- **WHEN** a spec names how that step is owned
- **THEN** it MUST use Doc-derived Typed action, Operator-only step, or Uncataloged Prep step
- **AND** it MUST NOT leave the step unnamed

#### Scenario: Specs use Uncataloged Prep step for a missing reason

- **GIVEN** a Prep step with no Typed action whose author recorded no reason for withholding one
- **WHEN** a spec names that step
- **THEN** it MUST use Uncataloged Prep step
- **AND** it MUST NOT call it an Operator-only step

#### Scenario: Specs use Runtime Doc-derived action for a derived command

- **GIVEN** a change authors requirements about a mutation the agent derives during a run to cover an Uncataloged Prep step
- **WHEN** it names that mutation
- **THEN** it MUST use Runtime Doc-derived action
- **AND** it MUST NOT describe it as an invented or ad-hoc command
- **AND** it MUST NOT call it a Typed action

#### Scenario: Specs use Temporary script copy

- **GIVEN** a change authors Connect runtime requirements about changing names or skipping a menu on a pinned script
- **WHEN** it names that disposable file
- **THEN** it MUST use Temporary script copy
- **AND** it MUST NOT describe an in-place edit of the Skill-held file

#### Scenario: Specs use Announcement not approval for automated

- **GIVEN** a change authors requirements about what automated says before it runs a change
- **WHEN** it names that message
- **THEN** it MUST use Announcement
- **AND** it MUST NOT describe it as an Approve gate

#### Scenario: Specs use Secret sink for agent-run secret output

- **GIVEN** a change authors requirements about where a secret-producing command's output goes under automated
- **WHEN** it names that destination
- **THEN** it MUST use Secret sink
- **AND** it MUST NOT describe the secret as entering agent context, chat, or the Connect log

#### Scenario: Minting a credential does not make a step Operator-only

- **GIVEN** a Prep step whose Typed action is `secretProducing`
- **WHEN** a spec names who executes it under automated
- **THEN** it MUST NOT classify that step as an Operator-only step
- **AND** Operator-only step MUST remain reserved for steps carrying an authored reason

### Requirement: Local onboarding fork term

The glossary SHALL define Local onboarding fork with the definition in Term
entries below. Specs that describe the maintained Microsoft Azure onboarding
script SHALL use Local onboarding fork rather than Temporary script copy.

#### Scenario: Specs use Local onboarding fork

- **GIVEN** a change authors documentation-ingest or integration-prep requirements about the maintained Microsoft Azure onboarding script
- **WHEN** it names those Skill-held bytes
- **THEN** it MUST use Local onboarding fork
- **AND** it MUST NOT call that file a Temporary script copy

### Requirement: Documentation ingest path terms

The glossary SHALL define Documentation tree, GitBook markdown catalog, and Cleaned nav with the definitions in Term entries below.

#### Scenario: Ingest specs use canonical tree terms

- **GIVEN** a change authors documentation-ingest requirements
- **WHEN** it names the local file layout, the published index, or the leftover filter
- **THEN** it MUST use Documentation tree, GitBook markdown catalog, and Cleaned nav rather than crawl dump, HTML BFS index, or drop-all-`-1`

### Requirement: Retired Lock-dimension terms

The glossary SHALL mark Add New Account target, Setup method, Authentication
method, and Coverage as superseded Lock dimensions and name Integration,
Integration path, and Optional capability as their replacements.

#### Scenario: Existing Lock vocabulary is superseded

- **GIVEN** an artifact describes the choices confirmed during Connect Lock
- **WHEN** it names the catalog row or mutually exclusive form route
- **THEN** it MUST use Integration and Integration path
- **AND** optional features MUST be named Optional capabilities and consented during Prep

### Requirement: Configuration tool catalog terms

The glossary SHALL define Configuration tool, Tool install catalog, Fit, and
Credential boundary with the definitions in Term entries below. Notes on
Integration path SHALL state that Configuration tools are path-owned.

#### Scenario: Index specs use Configuration tool not setup method

- **GIVEN** a change authors documentation-ingest requirements about operator CLIs for Integration prep
- **WHEN** it names those binaries and their install data
- **THEN** it MUST use Configuration tool, Fit, Tool install catalog, and Credential boundary
- **AND** it MUST NOT call a Configuration tool a Setup method or an Authentication method

#### Scenario: Configuration tools are not targets

- **GIVEN** the glossary entry for Integration path
- **WHEN** a reader uses that term after this change archives
- **THEN** the Notes MUST say a Configuration tool is owned by the path, not a new Integration

### Requirement: Connect run catalog terms

The glossary SHALL define Connect log, Connect run folder, Operation mode, Prep
step, Lock, Skill catalog, Operator input, Typed action, Platform identity,
Configuration plan, and Capability probe with the definitions in Term entries
below. Notes on Connection details SHALL state that vendor-specific fields live
on the locked Integration path as `connectionFields` (`name`, `secret`,
`obtainedHow`), shared tile fields may be added, and Worker Group is a global
field-map rule.

#### Scenario: Specs use Connect log not session file

- **GIVEN** a change authors skill or ingest requirements about the markdown file a Connect run writes
- **WHEN** it names that file
- **THEN** it MUST use Connect log
- **AND** it MUST NOT treat the Connect log as the Integration index

#### Scenario: Specs use Connect run folder not repo root dump

- **GIVEN** a change authors skill requirements about where a Connect run writes files
- **WHEN** it names that directory
- **THEN** it MUST use Connect run folder
- **AND** it MUST NOT treat a Skill catalog tree as the Connect run folder

#### Scenario: Specs use Operation mode

- **GIVEN** a change authors skill requirements about instructions, supervised, or automated
- **WHEN** it names those paths
- **THEN** it MUST use Operation mode
- **AND** it MUST NOT use manual as the canonical name for instructions

#### Scenario: Specs use Prep step not setup method

- **GIVEN** a change authors documentation-ingest requirements about ordered target-side actions
- **WHEN** it names those catalog items
- **THEN** it MUST use Prep step
- **AND** it MUST NOT call a Prep step a Setup method

#### Scenario: Specs use Lock not tile alone

- **GIVEN** a change authors skill requirements about which Integration a run configures
- **WHEN** it names the confirmed selection
- **THEN** it MUST use Lock
- **AND** it MUST NOT treat an Optional capability as an Integration

#### Scenario: Specs use Skill catalog

- **GIVEN** a change authors skill requirements about which JSON file entro-connect reads
- **WHEN** it names that file
- **THEN** it MUST use Skill catalog
- **AND** it MUST NOT require the skill to open `documentation/` markdown

#### Scenario: Specs use Operator input not guessed labels

- **GIVEN** a change authors skill requirements about names the operator supplies
- **WHEN** it names those catalog items
- **THEN** it MUST use Operator input
- **AND** it MUST NOT infer required names only from `obtainedHow` prose

#### Scenario: Specs use Typed action not ad-hoc command

- **GIVEN** a change authors automation requirements about executable Integration prep
- **WHEN** it names those catalog items
- **THEN** it MUST use Typed action
- **AND** it MUST NOT store a `command` field on a Prep step

#### Scenario: Specs use Platform identity

- **GIVEN** a change authors skill requirements about which environment a Configuration tool is authenticated to
- **WHEN** it names that evidence
- **THEN** it MUST use Platform identity
- **AND** it MUST NOT treat a token cache as the recorded evidence

#### Scenario: Specs use Configuration plan not Intro outline

- **GIVEN** a change authors skill requirements about the ordered mutations to execute
- **WHEN** it names that list
- **THEN** it MUST use Configuration plan
- **AND** it MUST NOT treat the Intro outline as the executable plan

#### Scenario: Specs use Capability probe

- **GIVEN** a change authors skill requirements about whether a Configuration tool is already suitable
- **WHEN** it names that check
- **THEN** it MUST use Capability probe
- **AND** it MUST NOT treat any on-PATH executable as automatically suitable

#### Scenario: Connection details notes name the index

- **GIVEN** the glossary entry for Connection details
- **WHEN** a reader uses that term after this change archives
- **THEN** the Notes MUST say vendor-specific fields are `connectionFields` (`name`, `secret`, `obtainedHow`) on the locked Integration path
- **AND** the Notes MUST say Worker Group is a global field-map rule

### Requirement: Skill catalog layout terms

The glossary SHALL define Skill catalog, Skill catalog index, Row catalog,
catalogPath, and Tool install file with the definitions in Term entries below.
Notes on Skill-held onboarding artifact MUST name the row folder, not `vendor/`.
Notes on Integration MUST say the ingest Integration index keeps one full row per
exact tile in `documentation/integrations.json`, while the Skill catalog uses one
Row catalog folder per exact tile at `integrations/<kebab(tile)>/`.

#### Scenario: Specs use Skill catalog for the tree

- **GIVEN** a change authors skill or ingest requirements about Connect-run catalog data
- **WHEN** it names that data
- **THEN** it MUST use Skill catalog for the generated tree
- **AND** it MUST NOT require the skill to open `documentation/` markdown

#### Scenario: Specs distinguish index from Row catalog

- **GIVEN** a change authors requirements about what Lock reads versus what Intro reads
- **WHEN** it names those files
- **THEN** it MUST use Skill catalog index and Row catalog
- **AND** it MUST NOT call the thin index a full Integration index row

#### Scenario: Specs use catalogPath

- **GIVEN** a change authors requirements about how Lock finds a folder
- **WHEN** it names the pointer
- **THEN** it MUST use catalogPath
- **AND** it MUST NOT require the skill to derive the path from a slug rule at run time

#### Scenario: Specs use Tool install file

- **GIVEN** a change authors requirements about where `toolInstall` lives on disk
- **WHEN** it names that file
- **THEN** it MUST use Tool install file
- **AND** it MUST NOT require `toolInstall` on the Skill catalog index

#### Scenario: Skill-held home is the row folder

- **GIVEN** a change authors requirements about Skill-held onboarding artifacts
- **WHEN** it names their location
- **THEN** it MUST place them in the row folder
- **AND** it MUST NOT use `vendor/` as the live home

### Requirement: Configure once term

The glossary SHALL define Configure once, Configure once prompt, and
Authentication route with the definitions in the Term entries below. Specs that
name the prior session-config step on a Tool install entry MUST use Configure
once rather than habilitator, sessionConfig, or authPrerequisite. Specs that
name one question the vendor command asks, together with where the operator
obtains that value, MUST use Configure once prompt. Specs that name one of the
several ways a single Configuration tool can be authenticated MUST use
Authentication route, and MUST NOT call it an Authentication method, which is a
superseded Lock dimension.

#### Scenario: Specs use Configure once not habilitator

- **GIVEN** a change authors skill or ingest requirements about writing local CLI session config before `authOnce`
- **WHEN** it names that catalog object
- **THEN** it MUST use Configure once
- **AND** it MUST NOT treat Configure once as a Prep step, Typed action, or Capability probe

#### Scenario: Specs use Configure once prompt not hint

- **GIVEN** a change authors requirements about the questions a Configure once command asks
- **WHEN** it names those catalog entries
- **THEN** it MUST use Configure once prompt
- **AND** it MUST NOT treat a Configure once prompt as an Operator input

#### Scenario: Specs use Authentication route not auth method

- **GIVEN** a change authors requirements about the alternative ways to authenticate one Configuration tool
- **WHEN** it names one entry in a Configure once `methods` list
- **THEN** it MUST use Authentication route
- **AND** it MUST NOT use Authentication method, a superseded Lock dimension

### Requirement: Catalog completeness terms

The glossary SHALL carry Documented method, Method waiver, and Fork census, and
SHALL keep them distinct from Integration paths and Optional capabilities.
Documents and code MUST use these terms as defined here.

- **Documented method** — a distinct way Entro's published documentation says one
  Integration can be set up or authenticated. It exists in legacy documentation
  whether or not the curated catalog binds it to an Integration path. A Documented
  method MUST bind to an Integration path or have a Method waiver.
- **Method waiver** — an explicit catalog record that a Documented method or an integration
  documentation page is deliberately not bound to an Integration path,
  carrying the reason it is out of scope. Absence without a waiver is a validation failure,
  not a decision.
- **Fork census** — the per-page list of Documented methods a cited page names, each bound
  to an Integration path or a Method waiver, and each quoting the page text that names it.

Optional capability MUST mean an additional surface of an Integration, never
catalog completeness. "Completeness" or "census" are the terms for bookkeeping.

#### Scenario: Documented method binds to a path

- **GIVEN** an onboarding path Entro's documentation describes
- **WHEN** the catalog does not bind it to an Integration path
- **THEN** it MUST still be called a Documented method
- **AND** it MUST have a Method waiver or validation MUST fail

#### Scenario: Waiver is a reasoned record

- **GIVEN** a Documented method the catalog deliberately omits
- **WHEN** that omission is recorded
- **THEN** it MUST be a Method waiver carrying a reason sentence
- **AND** it MUST NOT be described as an exception, ignore list, or skip list

#### Scenario: Optional capability is not reused for completeness

- **GIVEN** a requirement or identifier about catalog completeness
- **WHEN** it is named
- **THEN** it MUST NOT use "coverage"
- **AND** Optional capability MUST keep meaning an additional surface of an Integration

## Term entries

### Term: Entro
**Context**: global
**Definition**: SailPoint Entro (Entro Security) — the product that connects to customer integrations to discover and monitor secrets and related assets.
**Aliases**: Entro Security, SailPoint Entro
**Notes**: Not the same as SailPoint Identity Security Cloud; ISC is one integration Entro can connect to. Vendor pages that say "Entro Platform" mean this product, not an Integration catalog entry.

### Term: Integration
**Context**: global
**Definition**: One exact Entro Select Provider tile label. The catalog row identity.
**Aliases**: provider tile, Select Provider tile
**Notes**: Exactly one full ingest row and one `integrations/<kebab(tile)>/` Row catalog folder exist per tile. Not a documentation section, setup route, Optional capability, or Connector deployment.

### Term: Integration path
**Context**: documentation-ingest, integration-automation
**Definition**: A mutually exclusive connection-form choice visible on an Integration tile. It owns Configuration tools, connection fields, Prep steps, Operator inputs, and Typed actions for that route.
**Aliases**: connection path, preparation route (when visible on the form)
**Notes**: A singleton path is implicit and needs no Lock gate. Replaces Add New Account target selection, Setup method, and Authentication method as Lock dimensions.

### Term: Optional capability
**Context**: integration-automation, integration-prep
**Definition**: A non-core surface or feature the operator may enable after Lock.
**Aliases**: optional surface, optional feature
**Notes**: Additional instructions or Typed actions run only after just-in-time consent, including in automated mode. Not selected at Lock. Differs from mandatory baseline capabilities on the Integration tile or path.

### Term: Capture required
**Context**: documentation-ingest, integration-automation
**Definition**: A tile row reserved before its connection form and Integration paths are evidenced.
**Aliases**: stub tile, uncaptured tile
**Notes**: Connect stops before Lock and requests screenshots. The row MUST NOT invent paths, fields, prep steps, or Typed actions.

### Term: Add New Account target
**Context**: documentation-ingest
**Definition**: Superseded — use Integration for the exact tile and Integration path for a visible mutually exclusive form choice.
**Aliases**: target selection, in-form target
**Notes**: Retired as a Lock and catalog identity dimension. Historical documentation may still use the phrase.

### Term: Setup method
**Context**: documentation-ingest
**Definition**: Superseded as a Lock dimension — a form-visible route is an Integration path; a documentation-only route remains a Documented method bound to a path or waiver.
**Aliases**: onboarding route
**Notes**: Fork census may cite this historical documentation-era name.

### Term: Documented method
**Context**: documentation-ingest
**Definition**: A distinct way Entro's published documentation says one Integration can be set up or authenticated.
**Aliases**: none
**Notes**: It MUST bind to an Integration path or have a Method waiver. Legacy evidence may use old setup or authentication names.

### Term: Method waiver
**Context**: documentation-ingest
**Definition**: An explicit ingest-only record that a Documented method or page is deliberately not bound to an Integration path, carrying the reason.
**Aliases**: none
**Notes**: Absence without a waiver is a validation failure, not a decision. Do not call this an exception, ignore list, skip list, or coverage waiver. Emitted on the ingest Integration index only; stripped from Skill catalog Row catalogs.

### Term: Fork census
**Context**: documentation-ingest
**Definition**: The per-page list of Documented methods a cited page names, each bound to an Integration path or a Method waiver, and each quoting the page text.
**Aliases**: none
**Notes**: Completeness and census are the terms for this check. Optional capability MUST NOT be reused for catalog completeness.

### Term: Authentication method
**Context**: documentation-ingest
**Definition**: Superseded as a Lock dimension — a form-visible credential route is an Integration path or part of a compound path name.
**Aliases**: credential type
**Notes**: Connection fields bind to the locked path. Fork census may cite this historical documentation-era name.

### Term: Coverage
**Context**: documentation-ingest, integration-automation
**Definition**: Superseded as a Lock dimension — use Optional capability for operator-consented additional surfaces.
**Aliases**: surface, optional coverage
**Notes**: Mandatory behavior stays on the Integration or path baseline. Historical specs used Coverage for surfaces that may now be their own exact tiles.

### Term: Hosting
**Context**: documentation-ingest
**Definition**: Whether an Integration path's connection endpoint is internet-reachable (`public`), inside the customer's private network (`self-hosted`), or chosen by the operator on the connection form (`operator-selected`).
**Aliases**: reachability, instance type
**Notes**: One value per row. GitLab and n8n are `operator-selected` because their forms document both cloud and self-hosted. Not Connector deployment, not category, not a stored topology list.

### Term: Connector requirement
**Context**: documentation-ingest
**Definition**: Superseded — a connector is always required for an Integration. Do not record `required`, `not-required`, or `unknown` on the Integration index. Runtime topology is Connector deployment.
**Aliases**: none
**Notes**: Previously meant whether the connection form had a Worker Group field. That mixed form fields with Entro Connector deployment. Worker Group, if documented, is a connection-detail for later prep.

### Term: Requirement evidence
**Context**: documentation-ingest
**Definition**: Superseded — the Integration index no longer cites a page to justify a connector requirement.
**Aliases**: none
**Notes**: Previously a page plus quote (Worker Group present or omitted). Dropped with Connector requirement.

### Term: Integration variant
**Context**: documentation-ingest
**Definition**: Superseded — use Integration for a catalog row, Integration path for a form-visible route, and Optional capability for an additional surface.
**Aliases**: deployment variant, onboarding variant
**Notes**: The term conflated tiles, paths, documentation-era methods, and form checkboxes. That conflation is retired rather than redefined.

### Term: Connector deployment
**Context**: documentation-ingest
**Definition**: How an Entro Connector runs when an Integration requires one: Entro cloud (default managed connector), SaaS perimeter (static-IP connector), self-managed Docker Compose, or self-managed Kubernetes (Helm).
**Aliases**: worker group deployment, connector topology
**Notes**: Derived from Hosting: `public` → SaaS Perimeter; `self-hosted` → Docker Compose or Kubernetes Helm (Helm preferred when scanning is cluster-native); `operator-selected` follows the form choice. Documented in `entro-connector/` pages. Not a JSON key on the Integration row. Entro cloud remains a product-level page, not a hosting mapping.

### Term: Integration prep
**Context**: integration-prep
**Definition**: Actions taken on the Integration target (roles, apps, keys, scopes, URLs) so Entro is allowed to connect.
**Aliases**: provider prep, platform prep, vendor setup
**Notes**: Distinct from entering values in Entro's UI.

### Term: Connection details
**Context**: connection-details
**Definition**: The fields Entro requires to complete an Integration (base URL, tenant, identifiers, and references to credentials the user supplies).
**Aliases**: connection fields, Entro connection form
**Notes**: The field map combines shared tile fields, locked-path `connectionFields` (`name`, `secret`, `obtainedHow`), enabled Optional capability fields, and global Worker Group. It MUST NOT merge other paths or store secret values.

### Term: Documentation ingest
**Context**: documentation-ingest
**Definition**: Fetching Entro's published integration documentation and turning it into structured, agent-usable source material.
**Aliases**: doc crawl, vendor doc extract
**Notes**: Covers GitBook Integration pages (GitBook markdown catalog → documentation tree) and the Entro API catalog (Entro OpenAPI snapshot at `documentation/api/openapi.yaml`). The snapshot is a sibling of the documentation tree, not a documentation-tree page. Raw crawl files are source material, not the published skill or spec.

### Term: Entro OpenAPI snapshot
**Context**: documentation-ingest
**Definition**: The committed OpenAPI 3 document of Entro’s product API, stored at `documentation/api/openapi.yaml` inside the documentation folder.
**Aliases**: none
**Notes**: Sibling of the documentation tree, not a cleaned-nav GitBook page. Do not call it a swagger dump or a portal scrape.

### Term: Entro API catalog
**Context**: documentation-ingest
**Definition**: The machine-readable API definition Entro serves at `{endpoint}/v1/docs` (OpenAPI 3 JSON), which the API docs portal loads after login.
**Aliases**: none
**Notes**: Not the GitBook markdown catalog, `llms.txt`, or HTML from apidocs.entro.security.

### Term: Integration automation
**Context**: integration-automation
**Definition**: Scripted or CLI-driven Integration prep that the user runs after authenticating the vendor CLI locally.
**Aliases**: provider automation, platform automation, CLI automation, automated configuration
**Notes**: The agent MUST NOT hold or inject secrets; the user's authenticated CLI session is the credential boundary.

### Term: C4 flowchart
**Context**: architecture-diagrams
**Definition**: A mermaid `flowchart` whose nodes and subgraphs map to C4
Container roles (Person, Container, Database, External System, system
boundary). It is the architecture picture GitHub and chat draw.
**Aliases**: mermaid C4, container diagram
**Notes**: Default for ferspec `design.md` §Architecture and the c4-diagram skill.
Not mermaid `C4Container` / `C4Context`. Not a `.drawio` file.

### Term: Intro C4
**Context**: integration-automation
**Definition**: The Connect Intro architecture picture: one mermaid `flowchart`
fence drawing the locked Integration's Configuration topology, derived from the
locked path and enabled Optional capabilities.
**Aliases**: none
**Notes**: Written in chat and the Connect log. Varies per Integration; the node
roles are fixed, the nodes are not. Does not draw the Connect run machinery
(Operator, Agent + entro-connect, Skill catalog, Vendor CLI / MCP). Not a per-run
`.drawio`.

### Term: Configuration topology
**Context**: integration-automation
**Definition**: What a locked Integration must have configured on the vendor side
for Entro to connect, and how Entro reaches it: the Identity object, the
permission grants attached to it, the vendor scopes and enabled Optional capabilities those
grants reach, the credential the operator carries to Entro, and the Entro-side
Connection and Connector.
**Aliases**: none
**Notes**: Derived per run from the locked Integration path — Typed action
`expectedChange` and `target`, enabled Optional capabilities,
`connectionFields`, `hosting`. Pre-mutation
intent, not probed state. Not the Connect run machinery. Not a deployment
topology.

### Term: Identity object
**Context**: integration-automation
**Definition**: The vendor-side principal Entro authenticates as — an Entra app
registration, an AWS IAM role, an Okta API service app — that permission grants
attach to.
**Aliases**: none
**Notes**: The node every other Configuration topology node hangs off. Named from
Typed action `expectedChange` / `target`, never invented. Not a Connector, not an
Operator identity.

### Term: Skill-held onboarding artifact
**Context**: documentation-ingest
**Definition**: A file or in-page onboarding snippet stored in the Integration's row folder in both `entro-connect` skill trees, identified by skill-relative path and SHA-256. It MAY be vendor-published bytes or a Local onboarding fork.
**Aliases**: vendor script copy, skill-local script
**Notes**: Connect executes these bytes only, or a Temporary script copy of them. GitBook is not the runtime source. Live home is the row folder, not `vendor/`. Not an Operator input.

### Term: Anonymous origin URL
**Context**: documentation-ingest
**Definition**: The GitBook `files.gitbook.io` object URL with `?alt=media` and no `token` query, used by ingest to detect origin change.
**Aliases**: none
**Notes**: Invalid if it contains `token=`. A 200 JSON metadata body (URL without `alt=media`) is not a successful file fetch. Unforked pins compare origin GET to the Skill-held copy. A Local onboarding fork compares origin GET to `originChecksum`. Not used at Connect time.

### Term: Local onboarding fork
**Context**: documentation-ingest
**Definition**: A Skill-held onboarding artifact whose committed bytes are this project's maintained copy of a vendor-published file, identified by `localFork`, Skill-held `checksum`, and `originChecksum` of the last recorded anonymous origin GET.
**Aliases**: none
**Notes**: Connect runs `checksum` bytes only. Ingest compares origin GET to `originChecksum`. Not a Temporary script copy. This change applies the term to `Entro-Azure-Onboarding.ps1`.

### Term: Doc-derived Typed action
**Context**: integration-prep
**Definition**: A Typed action whose mutation, verification, and rollback come from the vendor's documented CLI or API operation when no Skill-held onboarding artifact covers the Prep step.
**Aliases**: none
**Notes**: MUST NOT invent commands the vendor does not document. MUST NOT wrap an unpublished customer-supplied script as a pinned checksum.

### Term: Operator-only step
**Context**: integration-prep
**Definition**: A Prep step the project does not automate because the platform exposes it only through its UI, or because its documented command route is merge-sensitive enough that Connect declines to run it, carrying an authored reason and the evidence the operator reports.
**Aliases**: none
**Notes**: An authored reason is necessary for this classification. Absence of a Typed action alone is an Uncataloged Prep step, not this. Minting a credential does not make a step Operator-only: a `secretProducing` Typed action is agent-run under automated through a Secret sink, and operator-run under supervised.

### Term: Uncataloged Prep step
**Context**: integration-prep, documentation-ingest
**Definition**: A Prep step carrying neither a Typed action nor an authored Operator-only reason, emitted with an `uncataloged` classification that carries `evidence`.
**Aliases**: none
**Notes**: Describes the Skill catalog, not the vendor. Under automated the agent covers it with a Runtime Doc-derived action after one consent gate; under supervised the operator runs the disclosed derived command. The catalog writer MUST NOT convert one into an Operator-only step by supplying a default reason.

### Term: Runtime Doc-derived action
**Context**: integration-prep, integration-automation
**Definition**: A mutation the agent derives from vendor documentation during a Connect run to cover an Uncataloged Prep step, disclosed with its documentation source and consented once before it runs.
**Aliases**: none
**Notes**: Not a Typed action: it is derived per run rather than cataloged, and it is the only mutation automated gates. MUST NOT be composed from anything but vendor documentation; when documentation covers no command, the step falls back to operator execution with that absence recorded. A secret-producing one uses a Secret sink like any other.

### Term: Connect run folder
**Context**: integration-automation
**Definition**: The directory named `integrationConfig` under the current working directory that holds every file a Connect run writes.
**Aliases**: none
**Notes**: Falls back to the repository-root `integrationConfig` directory when the current working directory is inside a Skill catalog tree. Gitignored as `/integrationConfig/`. Not `.agents/skills/entro-connect` and not `skills/entro-connect`.

### Term: Connect log
**Context**: integration-automation
**Definition**: A gitignored markdown file in the Connect run folder (`entro-<tile-slug>` with an optional Integration-path slug) that records one Lock's Intro, Operator inputs, Configuration plan, Platform identity, and Prep evidence.
**Aliases**: session file
**Notes**: Created after Lock and updated as the run proceeds. Secret field values are never stored. Not the Integration index. Re-runs append. One file per Lock slug.

### Term: Temporary script copy
**Context**: integration-prep
**Definition**: A disposable copy of a pinned Skill-held onboarding artifact, used only to bind names or skip an interactive menu for one Connect run.
**Aliases**: none
**Notes**: Created after the original checksum matches. Lives in the Connect run folder with a `tmp-` filename prefix. Discarded after the step. MUST NOT be committed or written over `script.skillPath`. Not a Local onboarding fork.

### Term: Announcement
**Context**: integration-prep
**Definition**: The message automated sends immediately before it runs a change — the same disclosure supervised puts above its gate (step, target, exact command, expected change, verification, rollback or impact), plus a statement that the agent is running it now.
**Aliases**: none
**Notes**: It asks for nothing and waits for nothing. Not an Approve gate. Supervised has no Announcement; automated has no per-change gate.

### Term: Secret sink
**Context**: integration-automation
**Definition**: The file in the Connect run folder that an agent-run secret-producing command writes its output to instead of the terminal, so the secret never enters agent context, chat, or the Connect log.
**Aliases**: none
**Notes**: Filename prefix `sink-`. The agent reads back only named non-secret identifiers from it, discloses the path in chat so the operator vaults the secret, and deletes it once they confirm. The path MUST NOT be written to the Connect log. Not a vault and not a Temporary script copy. Not a Skill catalog tree file.

### Term: Configure once
**Context**: documentation-ingest
**Definition**: An optional Tool install catalog object (`configureOnce`) holding the Authentication routes by which an operator can get that Configuration tool authenticated.
**Aliases**: none
**Notes**: Omitted on CLIs whose sign-in creates their own session config. Lives on the shared Tool install entry, not on a Row catalog. Not a Prep step, not a Typed action, not a Capability probe. Chat may say habilitator; specs MUST NOT. Credentials from a route's command MUST NOT enter chat or the Connect log. When the object exists it MUST carry a non-empty `methods` list.

### Term: Authentication route
**Context**: documentation-ingest
**Definition**: One entry in a Configure once `methods` list: a named way to get a Configuration tool authenticated, carrying `whenToPick`, its own non-secret presence `check` and `suitableWhen`, an operator-run `command`, its Configure once prompts, its Credential boundary, its `docsUrl`, and an `authOnce` that MAY be null when the route has no sign-in step.
**Aliases**: none
**Notes**: Distinct from Authentication method, a superseded Lock dimension; an Authentication route is about the operator's local CLI session. Routes on one tool may differ in Credential boundary — for `aws`, long-lived keys in the shared credentials file versus the vendor CLI token cache. The skill selects a route when exactly one check is suitable and otherwise gates the choice, marking none of them recommended, because which route applies depends on the operator's organization.

### Term: Configure once prompt
**Context**: documentation-ingest
**Definition**: One entry in an Authentication route's `prompts` list: `prompt`, the label the vendor command displays, `whereToFind`, a non-secret statement of where the operator obtains that value, and optional `secret`, marking a value that is typed straight into the vendor CLI.
**Aliases**: none
**Notes**: Listed in the order the route's command asks. Relayed verbatim in the Configure once request so the operator can answer without leaving the run. Answered inside the vendor CLI, so it is never an Operator input, never bound to `connectionFields`, and never written to the Connect log. A `secret` prompt is relayed by label and source only and MUST NOT be requested or accepted in chat.

### Term: Lock
**Context**: integration-automation
**Definition**: The confirmed Integration tile and, only when that tile has more than one Integration path, the selected path.
**Aliases**: confirmed selection
**Notes**: Optional capabilities are not part of Lock. A capture-required tile stops before Lock.

### Term: Skill catalog index
**Context**: documentation-ingest, integration-automation
**Definition**: The thin `integrations.json` used for Orientation and Lock.
**Aliases**: thin index
**Notes**: Each of its 58 tile entries contains only `tile`, `summary`, `integrationPathNames`, `optionalCapabilityNames`, `catalogPath`, and `captureRequired`.

### Term: Row catalog
**Context**: documentation-ingest, integration-automation
**Definition**: The complete Skill catalog object for one exact Integration tile.
**Aliases**: tile catalog
**Notes**: Lives at `integrations/<kebab(tile)>/catalog.json`; path-owned data stays under its Integration path.

### Term: catalogPath
**Context**: documentation-ingest, integration-automation
**Definition**: The skill-root-relative pointer from one Skill catalog index tile entry to its Row catalog.
**Aliases**: row pointer
**Notes**: Connect opens it only after Lock and opens only the locked Integration's Row catalog.
