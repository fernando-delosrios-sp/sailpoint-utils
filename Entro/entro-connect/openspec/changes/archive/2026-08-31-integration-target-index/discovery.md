## Scope

Re-key `documentation/integrations.json` rows to Add New Account target selections and
make every `connectorRequirement` value carry a citation into the ingested documentation;
out of scope is any integration-prep or connection-details distillation, any change to how
ingest fetches pages, and all skills and CLI automation.

## Language

**Add New Account target** (`promote`):
The selection in Entro's Add New Account flow that determines which connection form the
operator sees — either a tile on its own, or an explicit in-form target choice under a tile
(`GitHub Cloud - New`, `BitBucket Data Center`, `Slack Enterprise Grid App`). One row in
`integrations.json` is exactly one target.
_Avoid_: variant, tile, integration type

**Setup method** (`promote`):
A documented route for performing Integration prep for one target — CloudFormation stack
versus hand-built IAM role, automated PowerShell versus manual app registration. A setup
method never changes the Entro connection form, so it is never a row.
_Avoid_: onboarding option, onboarding method, variant

**Authentication method** (`promote`):
The credential type a target's form accepts, chosen inside that form — Service Account key
versus Workload Identity Federation, fine-grained versus classic token. An attribute of a
row, never a row of its own.
_Avoid_: auth type, credential variant

**Connector requirement** (`promote`):
Whether a target's connection form requires the operator to pick a Worker Group (Connector).
Values: `required`, `not-required`, `unknown`.
_Avoid_: worker requirement, connector needed

**Requirement evidence** (`promote`):
The citation that justifies a row's connector requirement — an ingested documentation path
plus the form field label or statement on that page which settles the question.
_Avoid_: connector documentation, connector evidence links

**Integration variant** (`conflicts-with-canonical`):
Canonical glossary defines this as "a distinct Add New Account target under one vendor name",
which is what **Add New Account target** now names precisely. The existing data instead used
"variant" for setup methods and form checkboxes as well, which is what produced the defect.
Supersede the term rather than redefine it.

**Connector deployment** (`draft`):
Canonical definition stands and does not change. What changes is placement: the four
topologies are a property of the Entro Connector product, so they leave per-row data.

## Decisions

**Context** — `documentation/integrations.json` is generated from hardcoded constants in
`integration_catalog.py`. AWS is listed twice with contradictory connector requirements: the
CloudFormation row says the form has no Worker Group, while the Manual Assume Role row
documents the Worker Group field on that same form.

**Q1 — Why do two rows for one form disagree?** Because rows were split by setup method, and
each split row then had its connector requirement guessed independently from whether that one
page happened to print a Worker Group row in its field table. Absence on a page was read as
`not-required`. Six rows are wrong on that basis: AWS / CloudFormation, Azure Automated
PowerShell, GCP Service Account Key, Wiz, Google Drive, SharePoint / OneDrive.

**Q2 — What is the correct row identity?** The Add New Account target. Every onboarding page
states its navigation path, so the target is directly readable from the ingested docs. This
collapses AWS to one row, Microsoft Ecosystem to one row (absorbing SharePoint / OneDrive),
GCP to one row, GitLab to one row (self-managed is a form checkbox, `gitlab-onboarding.md:72`),
and the two GitHub token rows to one (`GitHub Cloud - Legacy`). It keeps three File Shares
Scanning rows, since each protocol has a different documented field table.

**Q3 — What replaces `connectorDeployments` and `connectorDocumentation`?** Both are dropped.
Every row carried the same four deployment values and the same four generic connector pages,
so neither field ever distinguished one row from another and the second was evidence in name
only. A single citation field replaces them; the four topologies are documented once at
product level.

**Q4 — What counts as evidence for `not-required`?** A complete, explicitly documented form
field list that omits Worker Group — as on Microsoft Copilot Studio. Page silence is not
evidence and yields `unknown`. This is the rule whose absence caused the defect, so it is
stated positively rather than left implicit.

**Q5 — How is contradiction prevented from recurring?** Validation stops checking only
internal shape. It resolves each citation to a real ingested file and fails when a row's
requirement is not `unknown` and has no citation.

## Open questions

None. The two cases that looked ambiguous during discovery both resolved from the docs:
Slack is two targets (`slack-onboarding-1.md:15` selects `Slack Enterprise Grid App`), and
the File Shares Scanning protocols are three targets with distinct field tables
(`sftp-ssh-onboarding.md:27`).

## Scenarios discussed

- A row whose requirement is `required` but whose citation path does not exist in `documentation/`
- A row whose requirement is `not-required` with no citation — must fail rather than pass silently
- Two setup methods for one target — must produce one row, not two that can disagree
- An auth method selected inside a form — must not create a row
- A target the docs never resolve either way — must be `unknown`, not `not-required`
- The Microsoft Ecosystem tile absorbing rows previously named Azure / Entra / M365 and SharePoint / OneDrive
