<!--
Delta spec — glossary terms promoted from discovery.
-->

## ADDED Requirements

### Requirement: Configuration tool catalog terms

The glossary SHALL define Configuration tool, Tool install catalog, Fit, and
Credential boundary with the definitions in Term entries below. Notes on Add New
Account target SHALL state that a Configuration tool is a row attribute, not a
target.

#### Scenario: Index specs use Configuration tool not setup method

- **GIVEN** a change authors documentation-ingest requirements about operator CLIs for Integration prep
- **WHEN** it names those binaries and their install data
- **THEN** it MUST use Configuration tool, Fit, Tool install catalog, and Credential boundary
- **AND** it MUST NOT call a Configuration tool a Setup method or an Authentication method

#### Scenario: Configuration tools are not targets

- **GIVEN** the glossary entry for Add New Account target
- **WHEN** a reader uses that term after this change archives
- **THEN** the Notes MUST say a Configuration tool is an attribute of a row, not a new Add New Account target

## Term entries

### Term: Configuration tool
**Context**: documentation-ingest
**Definition**: A named operator CLI (`kind` `cli`, identified by `binary`) or first-party vendor MCP server (`kind` `mcp`, identified by `id`) used for Integration prep of one Add New Account target, or an extra needed only by a Coverage, together with a Fit. Omitted `kind` means `cli`.
**Aliases**: vendor CLI, operator CLI, vendor MCP
**Notes**: Prefer Configuration tool in specs and the Integration index. Not a Setup method (Entro's documented prep route), not an Authentication method, not an Add New Account target. Not an Entro MCP Audit plugin. Microsoft Ecosystem Coverages inherit the parent row's Configuration tools unless they list extras.

### Term: Tool install catalog
**Context**: documentation-ingest
**Definition**: The Integration index root object `toolInstall`, keyed by CLI `binary` or MCP `id`, that records auth-once, Credential boundary, and one preferred install per Windows, macOS, and Linux.
**Aliases**: none
**Notes**: Fit stays on the row or Coverage, not in this catalog. One entry per key even when several targets list it. MCP keys use method `mcp-config` on each OS.

### Term: Fit
**Context**: documentation-ingest
**Definition**: How well a Configuration tool can perform Integration prep without putting secrets in the agent session. One of `preferred`, `usable`, `env-backed`, or `none`.
**Aliases**: none
**Notes**: `preferred` means an official CLI after local login; `usable` means the CLI or first-party MCP exists but Entro's path is portal or OAuth; `env-backed` means a gitignored env file; `none` means portal or human-only. Not a Setup method.

### Term: Credential boundary
**Context**: documentation-ingest
**Definition**: Where session credentials live after the operator authenticates once — the vendor CLI token cache or a gitignored env file.
**Aliases**: none
**Notes**: Never agent chat, never committed files. Distinct from HashiCorp Vault the Integration. Specs MUST NOT store secret values.

---

## MODIFIED Requirements

### Requirement: Add New Account target terms

The glossary SHALL define Add New Account target, Setup method, Authentication method,
Connector requirement, and Requirement evidence with the definitions in Term entries below.

#### Scenario: Index specs distinguish target from method

- **GIVEN** a change authors documentation-ingest requirements about the Integration index
- **WHEN** it names a row, a route through Integration prep, or a credential type
- **THEN** it MUST use Add New Account target, Setup method, and Authentication method rather than calling all three a variant

#### Scenario: Connector claims name their evidence

- **GIVEN** a spec or index row states whether a connection form needs a Worker Group
- **WHEN** the statement is recorded
- **THEN** it MUST use Connector requirement for the value and Requirement evidence for its citation

#### Scenario: Configuration tools are not conflated with methods

- **GIVEN** a change authors documentation-ingest requirements about operator binaries
- **WHEN** it names those binaries
- **THEN** it MUST use Configuration tool rather than Setup method or Authentication method

## Term entries

### Term: Add New Account target
**Context**: documentation-ingest
**Definition**: The selection in Entro's Add New Account flow that determines which connection form the operator sees — a tile on its own, or an explicit in-form target choice under a tile such as `GitHub Cloud - New`, `BitBucket Data Center`, or `Slack Enterprise Grid App`.
**Aliases**: target
**Notes**: One row in `integrations.json` is exactly one target, identified by the tile label and the in-form selection together. Read the tile label from the documented Add New Account navigation path, not from the documentation section name. Not a setup method, not an authentication method, not a checkbox inside a form, not a Configuration tool.

### Term: Setup method
**Context**: documentation-ingest
**Definition**: A documented route for performing Integration prep for one target, such as a CloudFormation stack versus a hand-built IAM role, or automated PowerShell versus manual app registration.
**Aliases**: onboarding method
**Notes**: A setup method never changes the Entro connection form, so it is an attribute of a row and never a row itself. Two setup methods for one target MUST NOT be able to disagree about that target's connector requirement. A Configuration tool is not a Setup method; Entro may document PowerShell while the preferred Configuration tool is `az`.

### Term: Authentication method
**Context**: documentation-ingest
**Definition**: The credential type a target's connection form accepts, chosen inside that form — Service Account key versus Workload Identity Federation, fine-grained versus classic token.
**Aliases**: none
**Notes**: An attribute of a row, never a row of its own.

### Term: Connector requirement
**Context**: documentation-ingest
**Definition**: Whether an Add New Account target's connection form requires the operator to select a Worker Group (Connector). One of `required`, `not-required`, or `unknown`.
**Aliases**: none
**Notes**: A property of the target, because it is a property of the form. Distinct from Connector deployment, which describes how an Entro Connector runs.

### Term: Requirement evidence
**Context**: documentation-ingest
**Definition**: The citation that justifies a row's connector requirement — an ingested documentation page plus the form field label or complete field list on that page which settles the question.
**Aliases**: none
**Notes**: `required` is evidenced by a documented Worker Group field; `not-required` by a complete documented field list that omits it. A page that simply does not mention the field is not evidence and leaves the requirement `unknown`. Cite pages, not line numbers, which rot on re-ingest.
