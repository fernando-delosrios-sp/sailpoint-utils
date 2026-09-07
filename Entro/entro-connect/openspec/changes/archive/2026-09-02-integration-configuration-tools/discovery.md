## Scope

Add a curated operator Configuration tool catalog to the Integration index: per-row
`configurationTools` (Coverages may add extras), plus a root `toolInstall` map keyed by
binary with Windows, macOS, and Linux install; out of scope is running those tools,
Integration automation skills, ingest fetch changes, and any secrets in agent context.

## Language

**Configuration tool** (`promote`):
A named operator binary or script host used for Integration prep of one Add New Account
target (or an extra needed only by a Coverage), identified by `binary` and a fit value.
_Avoid_: setup method, authentication method, vendor CLI (as the only name)

**Tool install catalog** (`promote`):
The Integration index root object `toolInstall`, keyed by binary, that records auth-once,
credential boundary, and one preferred install per Windows, macOS, and Linux.
_Avoid_: per-row install blob, shared tool registry of fit (fit stays on the row)

**Fit** (`promote`):
How well a Configuration tool can do Integration prep without putting secrets in the
agent session: `preferred`, `usable`, `env-backed`, or `none`.
_Avoid_: support level, maturity, recommended (as a field name)

**Credential boundary** (`promote`):
Where session credentials live after the operator authenticates once — vendor CLI token
cache or a gitignored env file — never agent chat or committed files.
_Avoid_: secret store, vault (unless the vendor product is HashiCorp Vault)

**Coverage** (`conflicts-with-canonical` only if main glossary still lacks the term):
Already defined in the `integration-coverage` change: an operator-named surface a target
unlocks after connect. This change only adds optional extra Configuration tools on a
Coverage; it does not redefine Coverage.
_Avoid_: treating Copilot Studio as a tile

**Setup method** (`draft`):
Canonical definition stands. Configuration tools are not setup methods; Entro may document
PowerShell while the preferred Configuration tool is `az`.

**Integration automation** (`draft`):
Canonical definition stands. This change catalogs tools for a later automation stage; it
does not implement automation.

## Decisions

**Context** — `integrations.json` is generated from `integration_catalog.py`. Rows already
have setup and authentication methods and Coverages, but nothing names which local CLI an
operator or agent should use after a one-time login. Explore locked three forks.

**Q1 — Where do tools live on a target?** Per-row `configurationTools[]` with `binary` and
`fit`. Each Add New Account target stays self-contained. Duplicating `{binary: az, fit:
preferred}` on Microsoft Ecosystem, Teams, and Azure DevOps is accepted.

**Q2 — Can a Coverage add tools?** Yes, additive. Parent tools always apply. Empty Coverage
`configurationTools` means inherit only. GitHub Cloud S3 log streaming may add `aws`;
Microsoft Ecosystem Coverages (SharePoint / OneDrive, Copilot Studio) add none.

**Q3 — Where do install instructions live?** JSON root `toolInstall` keyed by binary — not
copied onto every row. One preferred command per OS (Windows winget, macOS Homebrew, Linux
vendor docs URL when distros diverge). `docsUrl` is mandatory so install scripts do not rot
in the index.

**Q4 — What is the credential rule?** The agent never accepts secrets into session. Auth is
`authOnce` on the tool install entry. Secrets for Entro's connection form stay with the
operator (CLI output they paste, or gitignored env).

**Q5 — Stage intent?** Documentation-ingest catalog only. Not skills, not CLI automation,
not inventing a secrets architecture.

## Open questions

Deferred to apply: exact winget/Homebrew package ids and Linux `command` vs `docsUrl` for
each binary — pin against current vendor pages when filling `toolInstall`. No blocking TBD
on shape.

## Scenarios discussed

- Microsoft Ecosystem Coverages inherit `az` / `pwsh`; Copilot Studio is not a row
- GitHub Cloud–New lists `gh` as `usable` because Entro's GitHub App install is a redirect
- GitHub Enterprise S3 log streaming Coverage adds `aws`
- `jenkins-cli` is not a global package; install is "download jar from the controller"
- Rows with `fit: none` still appear so agents do not invent a CLI
- Regenerating the index without `toolInstall` keys that rows reference must fail validation
- Hand-editing `integrations.json` is not the source of truth
