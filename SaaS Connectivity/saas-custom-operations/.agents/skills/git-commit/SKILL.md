---
name: git-commit
description: 'Session-scoped git commit with conventional message analysis and staging. Use when user asks to commit changes, create a git commit, or mentions "/commit". Commits only this session''s work — never picks up changes from concurrent sessions on the same branch. Asks for scope clarification when session work is empty or ambiguous.'
license: MIT
allowed-tools: Bash
---

# Git Commit with Conventional Commits

Create standardized, semantic git commits scoped to **this session's work**. Analyze the diff for type, scope, and message — but stage and commit **only in-scope paths**.

## Conventional Commit Format

```
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

## Commit Types

| Type       | Purpose                        |
| ---------- | ------------------------------ |
| `feat`     | New feature                    |
| `fix`      | Bug fix                        |
| `docs`     | Documentation only             |
| `style`    | Formatting/style (no logic)    |
| `refactor` | Code refactor (no feature/fix) |
| `perf`     | Performance improvement        |
| `test`     | Add/update tests               |
| `build`    | Build system/dependencies      |
| `ci`       | CI/config changes              |
| `chore`    | Maintenance/misc               |
| `revert`   | Revert commit                  |

## Breaking Changes

```
# Exclamation mark after type/scope
feat!: remove deprecated endpoint

# BREAKING CHANGE footer
feat: allow config to extend other configs

BREAKING CHANGE: `extends` key behavior changed
```

## Workflow

### 1. Establish session scope

Derive **in-scope paths** from this conversation before touching git:

- Files created, edited, renamed, or deleted in this session
- Paths the user explicitly named as part of this commit
- Paths tied to the issue or feature this session is working on (when stated)

**Scope unclear** — stop and ask the user which files or work belong in this commit. Do not stage or commit until scope is confirmed. Triggers:

- No in-scope paths can be derived (clean session, or commit requested with no prior work in the thread)
- The user's request is vague ("commit my changes", "commit everything") and multiple unrelated changes exist in the working tree
- In-scope paths are ambiguous (e.g. overlapping features, shared files, unclear boundaries)

**Done when:** a concrete list of in-scope paths exists, confirmed by derivation or by the user.

### 2. Partition working tree changes

```bash
git status --porcelain
git diff --staged    # if anything is already staged
git diff             # unstaged working tree
```

Classify every dirty path as **in-scope** or **out-of-scope** against the list from step 1.

- **Out-of-scope** paths are almost certainly from another concurrent session — do not stage or commit them
- Report out-of-scope paths to the user; they can expand scope explicitly if needed
- If a file is in-scope but also contains hunks from outside this session, use `git add -p` for that file or ask the user

**Done when:** every dirty path is classified and out-of-scope paths are surfaced (if any).

### 3. Stage in-scope files only

```bash
git add path/to/in-scope-file1 path/to/in-scope-file2
git add -p path/to/mixed-file   # when only some hunks belong to this session
```

**Never** use `git add -A`, `git add .`, or other catch-all staging when out-of-scope dirty files exist.

**Never commit secrets** (.env, credentials.json, private keys).

**Done when:** the staged diff contains only in-scope changes.

### 4. Changelog gate

When the repo root has `CHANGELOG.md` and it is **not** among staged paths, update the changelog before continuing — do not generate a commit message or commit until this step completes.

```bash
git rev-parse --show-toplevel   # repo root
git diff --cached --name-only   # staged paths
```

Read and follow the **changelog-generator** skill, scoped to the **staged diff** (this commit's changes). Update `CHANGELOG.md` per that skill's format rules when the staged changes include user-visible work. Stage `CHANGELOG.md` when modified.

**Done when:** `CHANGELOG.md` is staged, or changelog-generator confirms the staged diff has no user-visible entry to add.

### 5. Generate commit message

Analyze the **staged** diff (not the full working tree) to determine:

- **Type**: What kind of change is this?
- **Scope**: What area/module is affected?
- **Description**: One-line summary (present tense, imperative mood, <72 chars)

### 6. Execute commit

```bash
# Single line
git commit -m "<type>[scope]: <description>"

# Multi-line with body/footer
git commit -m "$(cat <<'EOF'
<type>[scope]: <description>

<optional body>

<optional footer>
EOF
)"
```

**Done when:** commit succeeds and `git status` shows no staged in-scope changes remaining (out-of-scope dirt may still exist — that is expected).

## Best Practices

- One logical change per commit
- Present tense: "add" not "added"
- Imperative mood: "fix bug" not "fixes bug"
- Reference issues: `Closes #123`, `Refs #456`
- Keep description under 72 characters

## Git Safety Protocol

- NEVER update git config
- NEVER run destructive commands (--force, hard reset) without explicit request
- NEVER skip hooks (--no-verify) unless user asks
- NEVER force push to main/master
- If commit fails due to hooks, fix and create NEW commit (don't amend)
