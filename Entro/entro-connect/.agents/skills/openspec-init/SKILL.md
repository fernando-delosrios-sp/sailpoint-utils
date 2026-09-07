---
name: openspec-init
description: Use when the user asks to initialize or update an OpenSpec project — schema refresh, config/rules sync, agent routing fragments, and companion skills. Triggers include "update openspec", "upgrade schema", and "refresh ferspec".
---

# openspec-init

## Decision gates

Steps that say "stop and wait" are **_gates_**. At each gate:

1. Build options from discovered candidates (schemas/, inferred domains, yes/no).
2. Present them per the **structured-choices** skill — one gate per message, recommended option first, multi-select for domain lists.

Record the chosen option by `id` (schema dir name, domain slug, yes/no/skip).

## 0. Front door

- **Detect**: If `openspec/config.yaml` exists in the target project, this is an **existing** OpenSpec project.
- **_Gate_** — when existing:
  - **Update existing** (recommended) — run [Update path](#update-path) below.
  - **Re-init from scratch** — wipe `openspec/schemas/<schema>/` and refresh `openspec/config.yaml`; **preserve** `openspec/specs/` and `openspec/changes/` unless the user gives separate explicit confirmation to delete those. Single gate with clear wording before any destructive action.
- **Fresh init**: When `openspec/config.yaml` is absent, run [Init path](#init-path) (steps 1–6).

On update, read active schema from `openspec/config.yaml` → `schema:` key for U2 recommendation. U1 checks CLI availability only. U2 lists all bundled schemas with diff status; graph-version migration hard-stops run at **Apply selection** for the **chosen** schema before any full replace.

**Never auto-touch on update:** existing `openspec/specs/**` content (except optional missing-only ubiquitous-language backfill) and `openspec/changes/**`.

Per-schema overwrite scope, migration notes, and verify details live in `schemas/<name>/UPDATE.md`. Generic steps below; follow the active schema's `UPDATE.md` where it adds or overrides.

---

## Update path

Run in order. Each diff step requires user ack before write.

### U1. Preflight

- Confirm `openspec` CLI is available (`openspec --version`).
- Read active schema from `openspec/config.yaml` → `schema:` for U2 recommendation only — do **not** run per-schema graph-version or migration checks here (those run in U2 for the schema the user chooses).

### U2. Schema selection & refresh

Same schema picker as [init step 2](#2-schema-selection--installation), with per-schema diff status for update.

- **List schemas**: Read subdirectories under this skill's `schemas/` (skip non-schema entries like `README.md`).
- **Diff status**: For each schema, `diff -ruN` local `openspec/schemas/<name>/` vs bundled `schemas/<name>/`. Record: **identical**, **not installed locally**, or a one-line summary (e.g. "adds UPDATE.md only", "3 files differ").
- **_Gate_** — one option per bundled schema (`id` = directory name; `detail` = README summary + diff status). Recommend the active schema from `config.yaml`; when it has a non-empty diff, suffix the label with `(Recommended)`.
- **Apply selection** — set working `<schema>` to the chosen id:
  - **Migration preflight** (before any copy — applies to the **chosen** schema, not only the previously active one):
    - If the chosen schema's README documents a **Compatibility** table (min OpenSpec CLI), block when CLI is below that schema's minimum; otherwise warn.
    - **Local schema dir absent** (`openspec/schemas/<schema>/` missing): skip graph-version checks — fresh install.
    - **Local schema dir present**:
      - Read bundled and local `VERSION` and `schema.yaml` → `version:` (graph contract).
      - **Hard-stop** when bundled graph `version` > local — read migration notes in `schemas/<schema>/UPDATE.md`; require ack before continuing.
      - **Warn-only** when bundle `VERSION` major bumps but graph version is unchanged (prose/template changes; in-flight changes usually safe).
      - Show both version numbers in the pre-overwrite summary.
  - Local missing or differs from bundled → full replace: copy bundled directory to `openspec/schemas/<schema>/`.
  - **Identical** → skip copy.
  - Chosen schema ≠ active `schema:` in config → **schema change**; U3 updates `schema:` to the chosen name.
- Run `openspec schema validate <schema>`.
- **Completion criterion:** User chose a schema from the list; local dir matches bundled copy (after copy) or was already identical; validation passes.

### U3. Config refresh

- Build a refreshed `openspec/config.yaml` following `references/config.md`:
  - Set `schema:` to the schema chosen in U2.
  - **Preserve** existing `context:` verbatim.
  - **Preserve** user-added rule lines not present in the template.
  - **Add** missing artifact keys from the schema's `schema.yaml`.
  - **Refresh** template-owned default rules where the schema artifact set changed.
- Show diff vs current file. **_Gate_** — wait for ack before write.

### U4. Agent routing refresh

Follow `schemas/<schema>/UPDATE.md` for fragment paths. Default behavior:

- Detect existing agent config (`AGENTS.md`, `CLAUDE.md`, `.cursor/rules/`, etc.) per schema `INSTALL.md` / `UPDATE.md`.
- If an adopters fragment section exists → diff against `templates/adopters/*.fragment.md` → **_Gate_** — replace section on ack.
- If no section exists → **_Gate_** — offer to append fragment on ack.
- Never replace entire agent files — section-level only.

### U5. Companion skills

- **_Gate_** — "Refresh companion skills?" (recommended: yes).
- Run the full authoritative list from the schema's `INSTALL.md` **Skills** section (idempotent `npx skills add …`).
- Report any skills still missing after install if the user skipped.

### U6. Optional ubiquitous-language backfill

- If `openspec/specs/ubiquitous-language/spec.md` is **missing** only → **_Gate_** — offer one-time seed from `references/ubiquitous-language-spec.md`.
- If it exists → do not modify.

### U7. Verify

Follow `schemas/<schema>/UPDATE.md` **Verify** section (default: `openspec schema validate` + required skills present; smoke test only when `UPDATE.md` specifies).

**Completion criterion:** Schema validates, config and agent routing refreshed (or explicitly skipped with ack), skills refreshed (or skipped with missing list noted), verify checks pass.

---

## Init path

### 1. Setup & Initialization

- **Check Requirements**: Install the `openspec` CLI if it is not available (`npm install -D openspec` or `-g`).
- **Initialize**: Run `openspec init`. **_Gate_** — present inferred or default AI tool options; stop and wait for their response before proceeding.
- **Completion Criterion**: `openspec` CLI is available and `openspec init` has completed.

### 2. Schema Selection & Installation

- **List Schemas**: Read subdirectories under this skill's `schemas/` (skip non-schema entries like `README.md`).
- **Select Schema**: **_Gate_** — one option per schema (`id` = directory name; `detail` from schema README when available). Stop and wait for their choice.
- **Copy Schema**: Copy the chosen schema directory from this skill's `schemas/` folder to the target repository's `openspec/schemas/` directory.
- **Validate**: Run `openspec schema validate <schema-name>`. Attempt to fix errors or ask the user for guidance.
- **Completion Criterion**: The chosen schema directory exists in `openspec/schemas/` and validation passes.

### 3. Schema Instructions

- **Check Instructions**: Look for `INSTALL.md` in the copied schema directory.
- **Execute**: If it exists, follow the **Post-copy setup** section only. Skip **Standalone manual install**, **Skills**, **Verify**, and **Upgrading** — those belong to README/UPDATE.md (standalone use), step 6, step 6 after step 5, or the [Update path](#update-path) respectively.
- **Completion Criterion**: Post-copy setup in `INSTALL.md` is complete, or no `INSTALL.md` exists.

### 4. Configuration

- **Build Config**: Build `openspec/config.yaml` by following `references/config.md`.
- **Completion Criterion**: `openspec/config.yaml` exists and contains `schema`, `context`, and `rules` sections.

### 5. Initial Spec Generation

- **Mandatory ubiquitous language**: Always create `openspec/specs/ubiquitous-language/spec.md` using `references/ubiquitous-language-spec.md` as the starting template. This spec is required for every project — do not skip it or fold it into another domain.
- **Discover Domains**: Analyze the project structure to infer logical domains. **_Gate_** — multi-select over inferred domains; stop and wait for their response.
- **Pre-populate**: Create the confirmed domain subdirectories in `openspec/specs/` and generate an initial `spec.md` for each. Stick to the domain categories found; do not create specs for more particular sub-groupings (e.g., do not create a spec for each individual service within a structural grouping).
- **Completion Criterion**: `openspec/specs/ubiquitous-language/spec.md` exists and `openspec/specs/` contains at least one additional domain subdirectory with an initial `spec.md` file (or only ubiquitous-language if the project is too early to infer domains — ask the user).

### 6. Recommended Skills Installation

- **Install Skills**: **_Gate_** — confirm before installing.
- **Skill list**: If the chosen schema's `INSTALL.md` has a **Skills** section, follow that list (authoritative). Otherwise install the default bundle below.

  **Default bundle — schemas without an INSTALL.md Skills section** (from `fernando-delosrios-sp/skills`):
  ```bash
  npx skills add fernando-delosrios-sp/skills --skill structured-choices
  npx skills add fernando-delosrios-sp/skills --skill changelog-generator
  npx skills add fernando-delosrios-sp/skills --skill git-commit
  npx skills add fernando-delosrios-sp/skills --skill gherkin-authoring
  npx skills add fernando-delosrios-sp/skills --skill c4-diagram
  ```

- **Verify**: If `INSTALL.md` has a **Verify** section, run it now (after step 5). Otherwise confirm `openspec schema validate <schema-name>` still passes and required skills are available.

- **Completion Criterion**: Required skills for the chosen schema are installed (or the user explicitly skipped with acknowledgment of which skills are missing), and verify checks pass.
