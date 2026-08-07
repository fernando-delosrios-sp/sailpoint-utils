---
name: openspec-init
description: Use when the user asks to initialize an OpenSpec project.
---

# openspec-init

## 1. Setup & Initialization

- **Check Requirements**: Install the `openspec` CLI if it is not available (`npm install -D openspec` or `-g`).
- **Initialize**: Run `openspec init`. Ask the user to select their preferred AI tools if not automatically inferred. Stop and wait for their response before proceeding.
- **Completion Criterion**: `openspec` CLI is available and `openspec init` has completed.

## 2. Schema Selection & Installation

- **List Schemas**: List the available default schemas from this skill's `schemas/` directory.
- **Select Schema**: Ask the user to choose one. Stop and wait for their choice.
- **Copy Schema**: Copy the chosen schema directory from this skill's `schemas/` folder to the target repository's `openspec/schemas/` directory.
- **Validate**: Run `openspec schema validate <schema-name>`. Attempt to fix errors or ask the user for guidance.
- **Completion Criterion**: The chosen schema directory exists in `openspec/schemas/` and validation passes.

## 3. Schema Instructions

- **Check Instructions**: Check for `INSTALL.md` in the copied schema directory.
- **Execute**: If it exists, read and follow all instructions within it.
- **Completion Criterion**: All instructions in `INSTALL.md` are executed, or no `INSTALL.md` exists.

## 4. Configuration

- **Build Config**: Build `openspec/config.yaml` by following `references/config.md`.
- **Completion Criterion**: `openspec/config.yaml` exists and contains `schema`, `context`, and `rules` sections.

## 5. Initial Spec Generation

- **Mandatory ubiquitous language**: Always create `openspec/specs/ubiquitous-language/spec.md` using `references/ubiquitous-language-spec.md` as the starting template. This spec is required for every project — do not skip it or fold it into another domain.
- **Discover Domains**: Analyze the project structure to infer logical domains. Ask the user to confirm or adjust these domains. Stop and wait for their response.
- **Pre-populate**: Create the confirmed domain subdirectories in `openspec/specs/` and generate an initial `spec.md` for each. Stick to the domain categories found; do not create specs for more particular sub-groupings (e.g., do not create a spec for each individual service within a structural grouping).
- **Completion Criterion**: `openspec/specs/ubiquitous-language/spec.md` exists and `openspec/specs/` contains at least one additional domain subdirectory with an initial `spec.md` file (or only ubiquitous-language if the project is too early to infer domains — ask the user).

## 6. Recommended Skills Installation

- **Install Skills**: Ask the user for permission to install behavioral skills. Install all that apply to the chosen schema:

  **All schemas** (from `fernando-delosrios-sp/skills`):
  ```bash
  npx skills add fernando-delosrios-sp/skills --skill changelog-generator
  npx skills add fernando-delosrios-sp/skills --skill git-commit
  npx skills add fernando-delosrios-sp/skills --skill gherkin-authoring
  npx skills add fernando-delosrios-sp/skills --skill c4-diagram
  ```

  **superpowers-bridge only** — also install Superpowers execution skills:
  ```bash
  npx skills add obra/superpowers
  ```
  Required after install: `brainstorming`, `writing-plans`, `using-git-worktrees`,
  `subagent-driven-development`, `finishing-a-development-branch`
  (plus transitive `test-driven-development`, `requesting-code-review`).

  If the schema has its own `INSTALL.md`, follow its skill list — it is authoritative for schema-specific requirements.

- **Completion Criterion**: Required skills for the chosen schema are installed, or the user explicitly skipped with acknowledgment of which skills are missing.