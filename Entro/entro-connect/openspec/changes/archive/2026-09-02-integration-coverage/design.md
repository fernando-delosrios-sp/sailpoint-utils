## Context

`documentation/integrations.json` is generated from curated constants in
`integration_catalog.py`. Rows are Add New Account targets. Extra GitBook sections that
are not tiles (SharePoint, Copilot Studio, GitHub real-time scanning) are already
listed as `documentation` paths on the surviving row, or sit unused beside it. There is
no name for those surfaces, so a section whose onboarding path still says "Add New
Account → Microsoft Copilot Studio" is easy to mis-read as a second target.

Constraint: integrations are named as in Entro's onboarding catalog. The Add New
Account provider list, not a documented navigation path, decides whether a section is a
target. This change does not re-fetch GitBook.

C4 is omitted: one catalog writer, one JSON file, no new containers.

## Goals / Non-Goals

**Goals:**

- Name Coverage as a child of one Add New Account target
- Identify Coverages from collapsed GitBook sections, not permission-group headings
- Populate every Coverage the ingested tree already contains
- Fail validation when a Coverage cites a missing documentation path

**Non-Goals:**

- Distilling prep or connection details for a Coverage
- Changing ingest fetching or the documentation-tree layout
- Treating Git clone scanning, Copilot chats, Defender, or Teams secrets as Coverages
- Auto-deriving Coverages by parsing sidebar HTML — the catalog stays curated and cited

## Decisions

### D1: Coverage is a named child on the target row

- **Choice**: `coverages` is a list of `{name, documentation}`. `name` is the operator
  surface (GitBook section title). `documentation` is the ingested pages for that
  section. An empty list means the target has no Coverages, which is valid.
- **Reason**: Child-of-row matches how operators navigate (pick a tile, then a surface)
  and avoids a second top-level index.
- **Considered alternatives**: A many-to-many Coverage table — rejected, Git clone is
  the only cross-target case and is explicitly not a Coverage. A boolean flag per known
  Microsoft surface — rejected, other vendors already have the same shape.

### D2: Collapsed GitBook section is the only evidence rule

- **Choice**: A Coverage exists when a GitBook section (folder or leaf) resolves to this
  target and is not that target's core onboarding, permissions-reference, or
  troubleshooting pages. Permission-group headings are not evidence.
- **Reason**: SharePoint and Copilot Studio are folders; GitHub RTS is a leaf. Both
  are operator surfaces. Azure's numbered Graph bundles are prep for surfaces that may
  not have sections yet.
- **Considered alternatives**: Permission-group identity — rejected, it would mint
  Copilot chats / Defender / Teams secrets without operator-facing docs. Hand-curated
  names with no rule — rejected, repeats the fake-tile mistake.

### D3: Provider list beats documented navigation path

- **Choice**: If a section's Add New Account path names a tile the provider list does
  not offer, that section is a Coverage of the real target, not a row.
- **Reason**: GitBook lagged the UI for Copilot Studio. The glossary Notes for Add New
  Account target must say this, or the old "read the nav path" sentence will recreate
  the row.
- **Considered alternatives**: Trust GitBook nav paths — rejected, that is the defect.

### D4: Core connection is not a Coverage

- **Choice**: Azure / Entra / M365 onboarding pages stay on the Microsoft Ecosystem
  row's `documentation` / setup methods. They are not a Coverage named "Azure NHI".
- **Reason**: Operators do not "turn on" the form they just filled.
- **Considered alternatives**: A default Coverage on every row — rejected, noise.

### D5: Inventory (curated, cited)

- **Choice**: Microsoft Ecosystem: SharePoint / OneDrive, Copilot Studio. GitHub (all
  three targets): Real-time scanning. GitHub Cloud - New and GitHub Cloud - Legacy:
  Enterprise S3 log streaming (page is Cloud-specific; omit Enterprise Server).
  CrowdStrike: Falcon RTR (three RTR pages, one name). Atlassian / Jira Cloud: Jira
  real-time scanning. SailPoint ISC: Aggregating Entro NHIs & AI agents. All other
  rows: empty `coverages`.
- **Reason**: Discovery Q8; GitHub Enterprise Server is not Cloud S3 streaming.
- **Considered alternatives**: Three CrowdStrike Coverages — rejected, one operator
  ask. S3 streaming on all GitHub rows — rejected, the page is Cloud Enterprise logs.

### D6: Validation

- **Choice**: Each Coverage must have a non-empty name and at least one `documentation`
  path that exists under `documentation/`. Duplicate Coverage names on one row fail.
  Paths may also appear on the parent row's `documentation` list (SharePoint already
  does).
- **Reason**: Same citation discipline as connector requirement, without inventing a
  second evidence-basis enum — the section membership *is* the basis.

## Risks / Trade-offs

[Risk] GitBook grows a Copilot chats section later → Mitigation: add a Coverage when
ingest brings that section; do not pre-create from Graph headings.

[Risk] Provider-list knowledge is still curated (a screenshot, not an API) →
Mitigation: D3 is a spec rule; Copilot Studio is the proving example in tests.

[Trade-off] GitHub RTS is duplicated on three rows → Accepted: child-of-row was
chosen over a shared Coverage table.

[Trade-off] Catalog stays hand-maintained → Accepted: auto-parse of GitBook sidebar
is ingest work, out of scope.

## Migration Plan

N/A — no deployment changes. Regenerate `documentation/integrations.json` from the
catalog. Acceptance: `.venv/bin/python -m pytest` green and
`openspec validate --all --json` all valid.

## Open Questions

None.
