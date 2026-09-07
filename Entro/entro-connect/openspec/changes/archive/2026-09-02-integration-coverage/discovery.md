## Scope

Give each Add New Account target a list of Coverages — operator-named surfaces
evidenced by GitBook sections that resolve to that target and are not its core
onboarding docs — and populate every such coverage already visible in the ingested
tree; out of scope is integration-prep distillation, ingest fetch changes, skills,
CLI automation, Git clone scanning, and permission-group-only surfaces that have no
section of their own.

## Language

**Coverage** (`promote`):
An operator-named Entro surface that one Add New Account target can unlock after
connect — SharePoint / OneDrive or Copilot Studio under Microsoft Ecosystem, GitHub
real-time scanning under a GitHub target. Always a child of one target row. Not the
target itself, not a setup method, not a Graph permission group.
_Avoid_: feature, capability, scanning surface, module, optional scope, variant

**Core connection** (`draft`):
The always-on work of a target (Entra NHI / ARM for Microsoft Ecosystem). It is the
target, not a Coverage. No glossary promotion — do not mint a term operators will
not say.
_Avoid_: default coverage, implicit coverage

**Collapsed section** (`draft`):
A GitBook sidebar section (folder or leaf) whose pages resolve to an Add New Account
target other than that section's own tile, or that sits beside the target's core
onboarding tree without being a tile. Evidence that a Coverage exists. Working
discovery term; the glossary needs Coverage, not this phrase.
_Avoid_: documentation section (too broad — onboarding/permissions/troubleshooting
are sections too)

**Add New Account target** (`draft`):
Canonical definition stands. This change does not rename it. What changes is that a
documented navigation path that names a tile the Add New Account provider list does
not have is Coverage evidence, not a new target.
_Avoid_: variant, integration type

## Decisions

**Context** — Collapsing Microsoft Copilot Studio into the Microsoft Ecosystem row
fixed the fake tile, then left no name for what that GitBook section actually is.
SharePoint was already in that bucket (docs, no tile). Azure permission lists name
further surfaces (Copilot chats, Defender) that have no section. GitHub real-time
scanning, CrowdStrike RTR, and Jira real-time scanning are the same shape on other
targets. The index still only answers which form you fill.

**Q1 — What is the unit?** Coverage: what Entro can see or do after connect.
Prep (scopes, extra apps, scripts) hangs off a Coverage; it does not name it.

**Q2 — How fine?** Operator surface — a product or capability an operator would ask
to turn on. Finding types (Azure Functions secrets, app registrations) are not
Coverages. Core NHI/ARM is implicit on the target.

**Q3 — Cardinality?** A Coverage is always a child of one target row. Git clone
scanning spans GitHub, GitLab, and Bitbucket, so it stays product-level docs, not a
Coverage. GitHub real-time scanning is GitHub-specific: attach a copy to each GitHub
row that the page does not exclude.

**Q4 — Copilot chats vs Copilot Studio?** Two different surfaces (Graph AI-interaction
on the Ecosystem app vs Power Platform / Dataverse extra app). Only Studio has a
GitBook section, so only Studio is a Coverage. Chats wait for a section.

**Q5 — What makes a Coverage real?** A GitBook section that resolves to this target
and is not the target's core onboarding / permissions / troubleshooting docs.
Permission-group headings are prep, not identity. No carve-out for Copilot chats.

**Q6 — First-change scope?** Glossary + index field + populate every Coverage the
rule already names in the ingested tree (not Microsoft-only, not glossary-only).

**Q7 — Documented tile vs provider list?** The Add New Account provider list wins.
A section that says "Add New Account → Microsoft Copilot Studio" when that tile is
absent is a Coverage of Microsoft Ecosystem, not a target row.

**Q8 — Azure Hybrid / continuous Key Vault / Okta custom role?** Extra prep for the
core connection (Azure subpages, Okta setup), not Coverages. CrowdStrike's three RTR
pages are one Coverage ("Falcon RTR") — one operator ask, several pages, same as
SharePoint's folder. GitHub Enterprise S3 log streaming is a Coverage of the GitHub
Cloud targets (the page is GitHub-Cloud-specific). Jira real-time scanning is a
Coverage of Atlassian / Jira Cloud only. SailPoint NHI aggregation is a Coverage of
SailPoint ISC.

## Open questions

None blocking. Inventory attachments in Q8 are recorded assumptions from the docs;
design may correct a row if a page names a different target selection.

## Scenarios discussed

- Microsoft Ecosystem lists SharePoint / OneDrive and Copilot Studio, not Copilot chats
- A GitBook section whose navigation path names a missing tile becomes a Coverage, not a row
- Git clone scanning does not appear as a Coverage on GitHub, GitLab, or Bitbucket
- GitHub real-time scanning appears on each GitHub target row (child-of-row copies)
- A permission-only group (Defender, Teams secrets, Copilot chats) is not a Coverage
- Validation fails when a Coverage cites a path absent from `documentation/`
- Core Azure onboarding pages are not a Coverage of Microsoft Ecosystem
