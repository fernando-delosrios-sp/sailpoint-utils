## Context

`documentation/integrations.json` is generated from `integration_catalog.py`. Rows are
Add New Account targets with setup methods, authentication methods, and Coverages.
Nothing records which local binary an operator authenticates once so an agent can do
Integration prep without holding secrets.

Constraint: prefer official CLIs; never put secrets in agent context. This change only
extends the curated index. C4 is omitted: one catalog writer, one JSON file, no new
containers.

## Goals / Non-Goals

**Goals:**

- Name Configuration tools on every target row, with Fit
- Let Coverages add tools without becoming rows
- Install and auth-once live once per binary at the index root
- Validation fails when a used binary is missing from `toolInstall` (except `fit: none`)

**Non-Goals:**

- Executing CLIs, skills, or Integration automation
- A secrets-handling runtime
- Changing GitBook ingest fetch
- Treating Copilot Studio as a tile

## Decisions

### D1: Per-row `configurationTools`, install at root

- **Choice**: Each target lists `{binary, fit}` (optional `name`). Root `toolInstall`
  is keyed by binary and holds `authOnce`, `credentialBoundary`, `docsUrl`, and
  `install.windows|macos|linux` (`method`, optional `command`, `docsUrl`).
- **Reason**: Fit is per target (GitHub App install is `usable` even though `gh` is
  first-class). Install is per binary (`az` reused).
- **Considered alternatives**: Full tool objects on every row — rejected, install
  duplication. Shared registry of fit — rejected, fit is not global. Annotate only
  `setupMethods` — rejected, most rows have an empty list.

### D2: Coverage tools are additive

- **Choice**: Coverage MAY list `configurationTools`. Parent tools always apply.
  Empty list means inherit only.
- **Reason**: GitHub Cloud S3 log streaming needs `aws`; SharePoint and Copilot Studio
  need no extra.
- **Considered alternatives**: Union on the parent only — rejected, every GitHub Cloud
  reader would see `aws`. Notes-only extras — rejected, not machine-checkable.

### D3: Fit enum

- **Choice**: `preferred` | `usable` | `env-backed` | `none`.
  - `preferred`: official CLI; agent can prep after `authOnce`
  - `usable`: official CLI exists but Entro's path is portal or OAuth (GitHub Cloud–New)
  - `env-backed`: REST; token in gitignored env; agent must not print it
  - `none`: portal / human-only; `binary` MAY be omitted; no `toolInstall` key required
- **Reason**: Stops agents inventing a CLI for Wiz or n8n Cloud.
- **Considered alternatives**: Boolean `hasCli` — rejected, GitHub App vs `gh` needs
  three states plus env-backed.

### D4: Install conventions

- **Choice**: One preferred method per OS — Windows `winget`, macOS Homebrew, Linux
  vendor `docsUrl` when distros diverge. `command` MAY be null on Linux. `jenkins-cli`
  records controller-jar download, not a global package.
- **Reason**: Frozen curl one-liners rot; `docsUrl` is the durable pointer.
- **Considered alternatives**: Enumerate winget, choco, scoop, apt, dnf — rejected,
  noise. Docs URLs only with no commands — rejected, operators still want a default.

### D5: Populate every row in apply

- **Choice**: Curated mapping for every catalog target. Microsoft Ecosystem, Teams, and
  Azure DevOps all list `az` and `pwsh`. Package ids pinned against vendor pages at apply.
- **Reason**: Empty tools on a row looks like "not classified" and invites invention.
- **Considered alternatives**: Fill only cloud CLIs first — rejected, `none` is data.

### D6: Source of truth

- **Choice**: Extend `integration_catalog.py` (and Coverage dataclass); regenerate JSON.
  Validation: every non-`none` CLI `binary` and MCP `id` exists in `toolInstall`;
  `toolInstall` keys are referenced at least once.
- **Reason**: Same as Coverages; hand-edits are overwritten.
- **Considered alternatives**: Hand-edit `integrations.json` — rejected.

### D7: MCP is a Configuration tool kind

- **Choice**: Same `configurationTools` list. `kind` is `cli` or `mcp`; omitted
  means `cli`. CLI keys `toolInstall` with `binary`; MCP keys it with `id`. MCP
  Fit is `usable`. First-party vendor MCP only (not Entro audit plugins, not
  community servers). List MCP beside a CLI when both exist. MCP `toolInstall`
  uses method `mcp-config` on Windows, macOS, and Linux with null `command`.
- **Reason**: n8n has no admin CLI but has an instance MCP; Azure/GitHub already
  have CLIs and official MCP. A fake `binary` would lie.
- **Considered alternatives**: Parallel `mcpServers` array — rejected, one list
  per row. Community MCP when vendor has none — rejected, first-party only.

## Risks / Trade-offs

[Risk] Vendor package ids change → Mitigation: `docsUrl` required; pin ids at apply;
tests check shape and referential integrity, not that winget still resolves.

[Risk] `drop-connector-requirement` / `integration-coverage` unarchived → Mitigation:
additive fields; merge JSON shape in apply against current catalog writer.

[Trade-off] Duplicate `{binary, fit}` on Microsoft rows → Reason: each target stays
self-contained; install is not duplicated.

[Trade-off] Linux often has no single `command` → Reason: honest `docsUrl` beats a
Debian-only apt line.

## Migration Plan

N/A — regenerate `documentation/integrations.json`. Acceptance: ingest tests pass;
every target has `configurationTools`; `toolInstall` covers every non-`none` binary;
README describes the new fields.

## Open Questions

None blocking. Package ids deferred to apply (discovery).
