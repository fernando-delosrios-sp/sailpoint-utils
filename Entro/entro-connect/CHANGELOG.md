## 2026-09-05 · v6.5.2

### 🔧 Improvements

- **Connect run files go to `integrationConfig/`** — Connect logs, temporary script copies, and secret-output files now land in `integrationConfig/` instead of the repository root or an `entro-connect/` folder. Skill catalog trees stay separate, and leftover root `entro-*.md` files remain gitignored.

---

## 2026-09-04 · v6.5.1

### 🔧 Improvements

- **One folder for Connect run files** — Connect logs, temporary script copies, and secret-output files now live together in the gitignored `entro-connect/` folder. Skill catalog files remain separate, and secret values still stay out of chat and Connect logs.

---

## 2026-09-04 · v6.5.0

### ✨ New Features

- **Uncataloged Prep steps run in automated Connect** — A Prep step with no Typed action and no authored vendor reason is classified `uncataloged`, not Operator-only. Automated mode looks up the command in vendor documentation, takes one consent gate, then runs and verifies it. The generator no longer stamps a default “operator must do this in the UI” reason on catalog gaps.

---

## 2026-09-04 · v6.4.1

### ✨ New Features

- **Executable Google Cloud Console onboarding** — Console-manual Connect plans now create the reader service account separately, apply the complete Terraform-derived custom role and 12 predefined IAM roles through a checksummed script, enable Terraform-default APIs, and leave organization audit-log setup as an explicit console step. Generated catalogs and scripts fail validation if their source, checksums, or copies drift.

---

## 2026-09-03 · v6.4.0

### ✨ New Features

- **Tile and Integration path catalog** — The Integration index now lists all 58 Select Provider tiles from the live Entro UI. Each tile is one row; mutually exclusive connection-form choices are `integrationPaths` (for example AWS CloudFormation / Terraform / Assume Role, Atlassian Classic vs Scoped tokens). Optional capabilities replace Coverage pre-selection; Connect obtains consent just-in-time during Prep. Thirty-one tiles are `captureRequired` stubs until their forms are captured.

### ⚠️ Breaking Changes

- **Retired `targetSelection`, Setup method, and Authentication method as Lock dimensions** — Lock is tile plus Integration path only. Skill catalog folders are `integrations/<kebab-tile>/` (for example `integrations/github/`, `integrations/amazon-web-services/`). Index fields are `integrationPathNames`, `optionalCapabilityNames`, and `captureRequired`.

---

## 2026-09-03 · v6.3.1

### 🐛 Fixes

- **AWS setup methods** — The Connect method gate no longer offers CloudFormation StackSets as a fourth choice. Org-wide StackSets stays on the documentation census with a waiver; the selectable methods are CloudFormation, Terraform, and Manual Assume Role.
- **AWS CloudFormation stays in the Entro UI** — The CloudFormation path is operator-only: launch the stack from Add New Account → AWS. Connect no longer offers a CLI `create-stack` for that method.

---

## 2026-09-03 · v6.3.0

### ✨ New Features

- **AWS Terraform and CloudFormation StackSets** — The AWS Add New Account row now offers Terraform and organization-wide CloudFormation StackSets alongside the existing CloudFormation stack and manual assume-role paths, including the Operator inputs those methods need (`remote_agent`, `sns_topic_arn_suffix`, `terraform_dir`).
- **Documented methods on the other incomplete rows** — Google Cloud Platform (Terraform automated and Console manual), Microsoft Ecosystem (Manual Policy Creation and Azure Continuous Onboarding), GitLab (group vs personal access tokens), File Shares SMB (manual vs JSON upload), Akeyless (Universal Identity vs API Key), Okta (Custom Entro Role next to Super Administrator), Atlassian (legacy combined Cloud page cited on all four rows), and CrowdStrike (Falcon RTR Terraform EC2 censused on the Coverage).
- **Catalog completeness gate** — Every integration documentation page must be cited or carry a Method waiver with a reason. Cited pages carry a fork census whose quotes are checked against the page. `python -m pytest` fails when a Documented method is dropped; waivers and census stay on the ingest index and out of the Skill catalog.

---

## 2026-09-03 · v6.2.0

### ✨ New Features

- **Authenticate AWS without IAM Identity Center** — Configure once now carries one Authentication route per way into a CLI, each with its own check, prompts, Credential boundary, and sign-in. AWS offers IAM user access keys (`aws configure`, nothing to enable on the tenant) alongside IAM Identity Center. Connect runs every route check: a single suitable route is used with no gate, so an expired SSO token still leads straight to `aws sso login`, and otherwise the operator picks. A route with no sign-in never produces a login request, so access-key operators are no longer told to run `aws sso login`.

### 🔒 Security

- **Secret prompts are relayed, never collected** — The `aws configure` secret access key prompt is marked `secret`: Connect names the label and where to find it, says to type it into the vendor CLI, and never asks for, echoes, or logs the value. Route checks test for key names only and print nothing.

### ⚠️ Breaking Changes

- **Configure once holds `methods`** — The `configureOnce` object no longer has a top-level `command`, `check`, `suitableWhen`, `prompts`, or `docsUrl`; those now live on each entry of `methods`. Consumers reading `toolInstall.aws.configureOnce.command` must read the routes instead. Only `aws` carries the object, and both catalogs regenerate from source.

---

## 2026-09-03 · v6.1.2

### 🔧 Improvements

- **Configure once names where each wizard value comes from** — The Configure once request lists every cataloged prompt with its source and a vendor docs URL before the operator runs the command. AWS fills the nine `aws configure sso` prompts (access portal for start URL and SSO region; `sso:account:access` default for scopes). Wizard answers stay in the vendor CLI, not Operator inputs or the Connect log.

---

## 2026-09-03 · v6.1.1

### 🔧 Improvements

- **Configure once before AWS SSO login** — Tool install may record an optional Configure once check and command. AWS fills it with operator-run `aws configure sso` so an IAM Identity Center profile exists before `aws sso login`. The wizard stays in the operator's terminal in every mode; a valid session still skips both steps.

---

## 2026-09-02 · v6.1.0

### ✨ New Features

- **Local onboarding fork for Microsoft Automated PowerShell** — The Skill-held Azure script is this project's maintained copy. Catalog `checksum` is what Connect runs; `originChecksum` is Entro's last recorded GitBook file. Create-app and the API-permissions menu default to the Entro permission-audit Graph and Defender set (including Optional rows such as `Application.ReadWrite.All`), keep Az.Resources 9 `Actions`/`NotActions`, and use `TeamsAppInstallation.ReadWriteSelfForUser.All`.

### 🔧 Improvements

- **Origin-published maintainer ask** — When Entro publishes new script bytes, ingest keeps the local files, succeeds, and names keep-local (bump `originChecksum` only) versus take-remote (rebase `Entro-Azure-Onboarding.local.patch` onto the new origin, then re-pin). Unforked pins still fail on origin drift. Connect never fetches GitBook and never asks remote versus local.

### 📚 Documentation

- **README and Connect prep** — Describe Local onboarding fork, `originChecksum`, the ingest notice, and that Connect still checksums only the Skill-held file.

---



### ⚠️ Breaking Changes

- **Automated Connect runs the plan itself** — Automated no longer hands commands back to the operator. Before each change it states what it is about to run, then runs it and verifies it, with no per-change Approve gate. Operators who relied on automated pausing per change should choose supervised instead.
- **Supervised hands every command to the operator** — Supervised now discloses each change, gates Approve / Adjust / Stop, and the operator runs the approved command in their own terminal while the agent verifies the non-secret result. This reverses the earlier behavior where supervised ran approved safe actions itself.

### 🔒 Security

- **Secret-producing scripts run through a Secret sink under automated** — A script that prints a Client Secret is now agent-run in automated mode, with its output routed to a file outside the repository and both skill trees. The agent reads back only Client ID, Tenant ID, and the success line, tells the operator where to vault the secret, and deletes the file once they confirm. A command that cannot withhold its secret from terminal output is handed to the operator instead. Signing in stays operator-run in every mode.

### 🔧 Improvements

- **Connect Intro shows what the Integration needs configured** — The Intro diagram is no longer the same seven boxes every run. It now draws the locked Integration's configuration: the identity object Entro authenticates as, the permission grants on it, what those grants reach, the credential the operator carries to Entro, and the Entro-side Connection and Worker Group. Every node comes from the locked catalog row, so all catalog rows draw their own picture with no per-integration authoring.

### 📚 Documentation

- **README and ADR-0001** — Describe the new execution split, the Secret sink, and that checksums run before the action is announced or gated rather than before Approve.

---

## 2026-09-02 · v6.0.0

### ⚠️ Breaking Changes

- **Supervised Connect runs approved safe actions** — After Approve, supervised and automated both run non-secret-producing Typed actions. Playbook still writes the plan only. Operators who expected to type every supervised command themselves now approve, then the skill runs it.

### ✨ New Features

- **Collision retry with a Temporary script copy** — When a script or action would replace an existing destination object, Connect discloses it, proposes a fix, gates Approve / Adjust / Stop, and retries. Hardcoded names or interactive menus use a disposable copy after the original checksum matches; the Skill-held file is never overwritten.

### 🔒 Security

- **Secret-producing actions stay operator-executed** — A script that prints a Client Secret is not run by the agent, because command output would enter agent context. Identifiers go in the Connect log; the secret stays in the operator vault.

---

## 2026-09-02 · v5.0.0

### ⚠️ Breaking Changes

- **Skill catalog is a tree** — Connect reads a thin Skill catalog index (`integrations.json`: tile, targetSelection, summary, method and Coverage names, catalogPath) until Lock, then one Row catalog folder (`integrations/<slug>/catalog.json`) plus Skill-held files beside it. The sibling Tool install file (`tool-install.json`) holds `toolInstall`. Skill-side `vendor/` is retired. Ingest `documentation/integrations.json` stays one file of full rows.

### 📚 Documentation

- **README and ADR-0002** — Describe the Skill catalog tree, index-then-Row-catalog Connect reads, and that ADR-0002 supersedes ADR-0001’s single skill JSON file while keeping one skill and no documentation-tree dependency.

---

## 2026-09-02 · v4.0.0

### ⚠️ Breaking Changes

- **Connect runs Skill-held files only** — entro-connect checksums `script.skillPath` in the skill folder before Approve and does not download GitBook. Catalog pins use path + SHA-256 and an Anonymous origin URL (`?alt=media`, no `token=`) for ingest drift, not runtime fetch.

### ✨ New Features

- **Skill-held onboarding artifacts** — Integration documentation attachments (Azure PowerShell, Azure Continuous zip, AWS templates, GCP Terraform zip, CrowdStrike scanner, Gemini instructions, SailPoint NHI schema, WebGuard zip) and the GCP pre-check snippet are committed under `vendor/` in both `entro-connect` skill trees.
- **Prep coverage** — Every Prep step is a Skill-held action, a Doc-derived Typed action, or Operator-only with reason and evidence. Copilot Studio no longer uses a fake `sha256:verify-after-download` pin; Dataverse provisioning is `pac admin assign-user`. Unpublished Copilot `Entro-Onboard.ps1` and GitHub `onboard-script.zip` are not pinned.

### 📚 Documentation

- **README and Connect Prep** — Describe dual skill catalogs, `vendor/` copies, local checksum before Approve, and that Client Secret stays with the operator.

---

## 2026-09-02 · v3.0.2

### ✨ New Features

- **Pinned Azure onboarding script** — Connect can fetch `Entro-Azure-Onboarding.ps1` from Entro's GitBook attachment, verify SHA-256 `af42cb707a3edce614ba23eed7aa14add8ee336142061dc775edb3d4409666d1`, and run it after Approve. The script stays out of git. Client Secret stays in the operator vault.

---

## 2026-09-02 · v3.0.1

### 🔧 Improvements

- **C4 flowchart as the default** — New Container diagrams are mermaid `flowchart` fences in `design.md` §Architecture. Connect Intro C4 uses the same topology as a mermaid fence. Existing `.drawio` files stay in place.

---

## 2026-09-01 · v3.0.0

### ⚠️ Breaking Changes

- **Protected documentation source** — Documentation ingest now starts at `https://docs.entro.security/` instead of the public GitBook markdown catalog. Operators must log in in a browser, copy the request `Cookie` header, and set `ENTRO_DOCS_COOKIE` in the gitignored `.env`. There is no automatic fallback to `entro.gitbook.io`.

### ✨ New Features

- **Operator-exported session cookie** — Ingest reads only `ENTRO_DOCS_COOKIE` from the process environment or `.env`, sends it as the `Cookie` header, and prints numbered cookie-export steps when the value is missing, empty, or rejected. Cookie and authorization material stay out of logs, errors, and generated files.
- **Atomic documentation publication** — Pages and indexes are staged outside `documentation/` and replace the last valid tree only after a non-empty complete crawl, conversion, redaction, and index validation. Partial page failures still attempt remaining pages, then discard the staged snapshot.

### 📚 Documentation

- **README, CLI help, and generated tree header** — Describe the protected source, cookie export steps, expiry refresh, and atomic publication.

---



### ✨ New Features

- **Persisted Intro before Operation mode** — A Connect run creates the Connect log after Lock, collects Operator inputs, and writes the same Intro brief (purpose, Coverages, topology, prerequisites, tools, names, fields, Prep outline, safety boundary, C4) before offering instructions, supervised, or automated. Instructions-only batches still persist Intro; they skip tools only.
- **Tool probes and Platform identity** — Each `toolInstall` entry carries a presence check, Capability probe, auth-check, and Platform identity query with official source URL and retrieval date. Suitable installs are reused; auth-check runs before login; the Connect log records principal, endpoint, and scope — not tokens.
- **Operator inputs and Typed actions** — Fit `preferred` paths declare Operator inputs and Typed actions (preview, mutation, target, expected change, verification, rollback or impact). Automated is offered only when that plan is complete. Secret-producing steps stay operator-executed. Secrets stay out of agent context, Connect logs, and git.

### 📚 Documentation

- **README, ADR-0001, and documentation-tree header** — Describe Intro-first Connect runs, the complete-plan automated bar, Operator inputs, Typed actions, and `toolInstall` probes.

---



### ✨ New Features

- **Self-contained Connection details and Prep steps** — Each Integration index row now carries a `summary`, vendor `connectionFields` (`name`, `secret`, `obtainedHow`), and ordered `prepSteps` (`title`, `instruction`, `evidence`). Setup methods own their steps when a row has them; Coverages may add steps (Copilot Studio) or inherit (empty list). Worker Group is a global Entro field, not copied onto every row. Secret values stay out of the index, Connect logs, and agent context.
- **Skill catalog copy** — The same catalog writer emits `.agents/skills/entro-connect/integrations.json` beside `documentation/integrations.json`. The skill copy has every target, tools, fields, and steps, and does not include `documentation/` markdown paths. Missing or stale skill JSON fails validation.
- **entro-connect skill** — One model-invoked skill walks a Connect run (Lock, ASCII C4 intro, Operation mode, Connect log). It reads only the Skill catalog. Connect logs are `entro-*.md` at the repo root and are gitignored.

### 📚 Documentation

- **README and documentation-tree header** — Describe `summary` / fields / steps, the Skill catalog path, Connect log gitignore, and that entro-connect does not read the documentation tree. ADR-0001 records the catalog-copy decision.

---

## 2026-08-31 · v2.3.0

### ✨ New Features

- **Hosting on each Integration index row** — Every `integrations.json` target records `hosting` as `public`, `self-hosted`, or `operator-selected` (GitLab and n8n). Connector deployment is derived from that value: public maps to SaaS Perimeter; self-hosted maps to Docker Compose or Kubernetes Helm (Helm preferred when scanning is cluster-native); operator-selected follows the connection form. Rows do not store a topology list. Docker Compose, Kubernetes Helm, and SaaS Perimeter pages stay product-level Entro Connector docs.

### 📚 Documentation

- **Index field guide** — README, the documentation-tree header, and the catalog module docstring name `hosting` and state that topology is derived, not stored.

---



### ✨ New Features

- **MCP as a Configuration tool kind** — Rows may list first-party vendor MCP servers (`kind: mcp`, `id`) beside CLIs. n8n uses `n8n-mcp` (Fit `usable`) instead of portal-only none. Azure, AWS, GitHub Cloud, Atlassian Cloud, and Salesforce list vendor MCP as a secondary usable tool. MCP install uses method `mcp-config` (no OS package command). Community MCP and Entro audit plugins stay out.

---

## 2026-08-31 · v2.1.0

### ✨ New Features

- **Configuration tools on each Integration index target** — Every Add New Account row lists `configurationTools` (`binary` plus Fit: `preferred`, `usable`, `env-backed`, or `none`). Coverages may add extras (GitHub Cloud Enterprise S3 log streaming adds `aws`); SharePoint / OneDrive and Copilot Studio inherit Microsoft Ecosystem `az` and `pwsh` and Copilot Studio stays a Coverage, not a tile.
- **Root Tool install catalog** — `toolInstall` is keyed by binary once (`az` is not copied onto every Microsoft row). Each entry records auth-once, Credential boundary (CLI token cache or gitignored env — never agent context), `docsUrl`, and preferred Windows / macOS / Linux install. `jenkins-cli` is a controller jar, not a winget-only package.

### 📚 Documentation

- **Index field guide** — README, the catalog module docstring, and the documentation-tree header describe `configurationTools` and `toolInstall`.

---

## 2026-08-31 · v2.0.0

### ⚠️ Breaking Changes

- **Index no longer records connector requirement** — `integrations.json` rows omit `connectorRequirement` and `connectorEvidence`. A connector is always required for an Add New Account target. Readers that still look for those keys will not find them.
  - Migration: stop reading those fields; assume a connector. Choose Docker Compose, Kubernetes Helm, or SaaS Perimeter from the product-level Entro Connector pages, not from the target row. Microsoft Teams, Wiz, Salesforce, and Google Workspace (GDrive) are ordinary rows — they are not `unknown`.

### 📚 Documentation

- **Index field guide** — README and the documentation-tree header drop the connector-requirement fields and keep the four Entro Connector topology links.

---

## 2026-08-31 · v1.2.0

### ✨ New Features

- **Coverage on the Integration index** — Each Add New Account row in `integrations.json` lists Coverages: operator-named surfaces that target can unlock after connect, each citing ingested GitBook section pages. Microsoft Ecosystem carries SharePoint / OneDrive and Copilot Studio (Copilot Studio is a Coverage, not a tile). GitHub rows carry Real-time scanning; GitHub Cloud rows also carry Enterprise S3 log streaming. CrowdStrike carries Falcon RTR, Atlassian / Jira Cloud carries Jira real-time scanning, and SailPoint ISC carries aggregating Entro NHIs and AI agents. Permission-group-only surfaces (Copilot chats, Defender, Teams secrets) are omitted.

### 📚 Documentation

- **Index field guide** — README and the documentation-tree header describe Coverages as children of a target row.

---

## 2026-08-31 · v1.1.0

### ✨ New Features

- **Entro OpenAPI snapshot ingest** — Operators can run `ingest_api.py` with a local `ENTRO_API_KEY` to fetch the Entro API catalog from eval (or `--endpoint`) and commit a full OpenAPI 3 YAML file at `documentation/api/openapi.yaml`. GitBook ingest stays a separate, key-free command.

### 📚 Documentation

- **API catalog vs documentation tree** — README describes the snapshot path, default eval endpoint, and that the key must never be committed. Glossary terms cover Entro OpenAPI snapshot and Entro API catalog.

### 🔒 Security

- **PAT-shaped examples redacted in the snapshot** — Catalog examples that look like GitHub PATs are stored as placeholders before write.

---

## 2026-08-31 · v1.0.0

### ⚠️ Breaking Changes

- **Target-keyed integration index** — `integrations.json` is now one row per Add New Account target (`tile` plus optional in-form `targetSelection`), not per setup method or documentation section. Setup and authentication methods are row attributes. Per-row `connectorDeployments` and `connectorDocumentation` are removed; the four Entro Connector topologies are documented once at product level. SharePoint / OneDrive is absorbed into Microsoft Ecosystem (those pages stay on that row). A connector requirement is `required` or `not-required` only with a citation into the ingested docs; otherwise it is `unknown` (including Microsoft Teams Messaging Risks and Wiz). This corrects contradictory AWS, Microsoft Ecosystem, Google Cloud Platform, Google Drive, SharePoint, and Wiz values.

### 📚 Documentation

- **Index field guide** — README and the documentation-tree header describe the target-keyed shape, the evidence rule, and product-level connector topology links.

---

## 2026-08-31 · v0.1.0

### ✨ New Features

- **Cleaned GitBook documentation tree** — Fetch Entro Integration docs from the published markdown catalog into `documentation/` folders that match the sidebar, dropping leftovers while keeping current `-1` pages such as VS Code and GCP.

### 📚 Documentation

- **Integration vocabulary** — Glossary and specs use Integration (Provider as alias); integration-prep and integration-automation capability specs.
- **Curated integration index** — Ingest writes `documentation/integrations.json` with Add New Account variants, connector requirement, deployment options, and local documentation links; excludes IDE plugins, SSO, and Entro tooling docs.
- **Project README** — Repo-root how-to for ingest, `documentation/` vs `docs/`, tests, and secrets.

### 🔒 Security

- **Ingest redacts GitHub PAT-shaped strings** — Page bodies that contain `ghp_` / `github_pat_` tokens are written with placeholders so a re-run does not restore published samples.

---
