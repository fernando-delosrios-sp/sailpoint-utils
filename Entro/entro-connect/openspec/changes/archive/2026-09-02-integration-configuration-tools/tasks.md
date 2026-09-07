## 1. Catalog model and validation

- [x] 1.1 Add Configuration tool type `{binary?, fit, name?}` on each `IntegrationDefinition` and on Coverage; emit `configurationTools` from `integration_to_dict`
- [x] 1.2 Add root `toolInstall` keyed by binary (`authOnce`, `credentialBoundary`, `docsUrl`, `install.windows|macos|linux`) and write it on the Integration index document
- [x] 1.3 Fail validation on empty `configurationTools`, unknown Fit, non-`none` entry without `binary`, missing `toolInstall` key, or orphan `toolInstall` key
- [x] 1.4 Fail validation if a Tool install entry omits `docsUrl` or any of the three OS install objects

## 2. Curated mapping and install pins

- [x] 2.1 Pin Windows winget / macOS Homebrew / Linux docs URLs against current vendor pages for `az`, `pwsh`, `aws`, `gcloud`, `gh`, `glab`, `vault`, `oci`, `terraform`, `jf`, `sf`, `snow`, and remaining binaries used in 2.2–2.4
- [x] 2.2 Microsoft Ecosystem, Teams, Azure DevOps: `az` and `pwsh` Fit `preferred`; AWS `aws`; GCP and GDrive `gcloud`; GitHub Cloud - New `gh` Fit `usable`; GitHub Cloud S3 Coverage adds `aws`
- [x] 2.3 Fill every other catalog row (preferred / usable / env-backed / none); `jenkins-cli` install is controller jar, not winget-only
- [x] 2.4 Copilot Studio and SharePoint Coverages inherit parent tools (no extra list required); Copilot Studio MUST NOT become a tile
- [x] 2.5 Regenerate `documentation/integrations.json`

## 3. Verification

- [x] 3.1 Confirm canonical test command: `.venv/bin/python -m pytest`
- [x] 3.2 Named tests for: every target lists Configuration tools; preferred cloud CLIs; GitHub App `usable`; portal-only Fit `none`; tools are not rows; shared `az` install once; auth-once without secrets; jenkins-cli not global package; Copilot Studio inherits; GitHub S3 adds `aws`; missing install fails; orphan install fails; Fit none without binary succeeds
- [x] 3.3 Glossary tests: specs use Configuration tool not setup method; Add New Account target Notes say Configuration tool is not a row
- [x] 3.4 Run `openspec validate --all --json` and confirm all items valid

## 4. Documentation

- [x] 4.1 Update repo `README.md` where it describes `integrations.json` fields to include `configurationTools` and `toolInstall`
- [x] 4.2 Skip Entro OpenAPI — no API contract change
- [x] 4.3 Update `documentation/README.md` index blurb and `integration_catalog.py` module docstring; mention Credential boundary (CLI cache / gitignored env, never agent context)

## 5. Changelog

- [x] 5.1 Create or update changelog entry for this change via changelog-generator
- [x] 5.2 Confirm the entry names Configuration tools on each target, Coverage extras, root Tool install catalog with OS install, and that secrets stay out of agent context

## 6. MCP as a Configuration tool kind

- [x] 6.1 Add `kind` `cli`|`mcp` (omit = `cli`); CLI still keys `toolInstall` with `binary`; MCP keys it with `id`
- [x] 6.2 Fail validation on unknown kind, MCP without `id` when Fit is not `none`, and missing/orphan MCP `toolInstall` keys
- [x] 6.3 n8n: replace portal-only `none` with first-party MCP `n8n-mcp` Fit `usable`; `toolInstall` method `mcp-config` on all three OS
- [x] 6.4 Scan remaining rows: first-party MCP beside CLI where it exists (Azure, AWS, GitHub Cloud, Atlassian Cloud, Salesforce); skip community and Entro audit plugins
- [x] 6.5 Named tests for n8n MCP, MCP beside CLI, MCP without id fails; regenerate JSON; changelog; `openspec validate --all --json`

