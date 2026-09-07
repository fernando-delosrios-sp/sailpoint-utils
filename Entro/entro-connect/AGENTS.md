# Entro integrations

Tooling to manage SailPoint Entro Integrations: distill vendor docs into Integration prep and Connection details, then (later) CLI Integration automation. The agent never handles secrets — the user authenticates vendor CLIs locally.

Context: `openspec/config.yaml`. Vocabulary: `openspec/specs/ubiquitous-language/spec.md`.

## Agent communication

- Use **plain English** — avoid jargon unless the user already uses it.
- Keep explanations **succinct**. State the conclusion first; add detail only when it helps a decision.
- When a topic could go deep, **offer to develop it further** — do not unprompted long dissertations or essay-length replies.
- When you need input, ask through a gate — **one question at a time**, waiting for the answer before the next.

## Workflow routing (read on session start)

This repo uses the **ferspec** OpenSpec schema. Artifact instructions inject at each `/opsx:*` step; skills carry execution detail.

### Entry routing

| Trigger you observe | What to do |
|---|---|
| User starts a narrative design discussion | Run verbal grilling via **grill-with-docs**, but **do NOT** write repo-root CONTEXT.md. When converged per the 5 criteria below, promote to `/opsx:propose` |
| User invokes `/opsx:new` / `/opsx:ff` / `/opsx:propose` directly | Follow the ferspec schema flow |
| User explicitly says bug fix / typo / config tweak / doc update | Direct PR — **do NOT** open a change |
| User is mid-change | Advance with `/opsx:continue`, `/opsx:apply`, or `/opsx:archive` (archive is manual, never part of apply) |

### When NOT to use opsx (direct PR)

| Scenario | Direct PR? |
|---|---|
| New feature / new capability / architectural change / breaking change | ❌ Use opsx |
| Bug fix (no contract change) / test backfill / linter tweak / non-breaking upgrade / typo / docs / config value tweak | ✅ Direct PR |

Principle: **process ceremony scales with risk**. External contracts / schema / cross-system integration / compliance → opsx. Otherwise → direct PR.

### Verbal discovery → opsx promotion criteria

All 5 must hold before promoting (any missing → keep grilling, **never** write repo-root CONTEXT.md):

1. **Scope locked** — one sentence describes what's in / out
2. **Major design forks resolved** — alternatives weighed; remaining TBDs have an owner and impact-scope statement
3. **Cross-system dependencies mapped** — ready / mockable / genuinely unknown — pick one per dep
4. **Acceptance criteria stateable** — concrete pass conditions (e.g., `./mvnw clean verify` passes + N deliverables)
5. **Conversation converging** — recent turns are confirmations, not new alternatives

When all 5 hold → proactively suggest "ready to `/opsx:propose`?" — wait for user ack. Never auto-trigger.

### Concurrent sessions and uncommitted work

More than one session works this repo. Uncommitted changes you did not create belong to someone else. Spec: `openspec/specs/change-isolation/spec.md`. Procedure: `docs/agents/change-isolation.md`.

| Situation | What to do |
|---|---|
| `git status` shows changes you did not make | Leave them. Report them. Do **not** stash, revert, `checkout --`, `restore`, `reset --hard`, or `clean` |
| You need a clean tree to verify | Isolate — git worktree or your own branch. Never clear the tree you share |
| `git stash list` holds an entry you did not create | Surface its message and file list to the user; let them decide. Never apply, drop, or pop it unilaterally |
| You edited a generator and regenerated committed artifacts | Commit generator edit and regenerated output **together**; never leave the regeneration uncommitted |
| A gate demands empty `git status --porcelain` and the dirt is yours | Commit it. Satisfying the gate by discarding the diff is a defect |

Before any tree-mutating step: read `git status` and `git stash list`, and account for anything you do not recognise.

### Front-door anti-patterns (don't do)

- Writing durable vocabulary to repo-root CONTEXT.md instead of discovery.md / ubiquitous-language spec
- Promoting to opsx with unresolved blocking TBDs
- Opening a change for bug fix / typo
- Stashing, reverting, or checking out over uncommitted work another session created — isolate instead
- Leaving a generator edit and its regenerated artifacts uncommitted, or clearing them to pass a clean-tree gate
- Running archive or spec sync inside apply — user runs `/opsx:archive` after merge or when ready
- Reporting archive complete without committing synced specs and the moved change folder — archive requires commit + post-commit gate (see ferspec README § Archive)

## Agent skills

### Issue tracker

GitHub Issues on `fernando-delosrios-sp/TES` via the `gh` CLI. See `docs/agents/issue-tracker.md`.

### Triage labels

Canonical five: `needs-triage`, `needs-info`, `ready-for-agent`, `ready-for-human`, `wontfix`. See `docs/agents/triage-labels.md`.

### Domain docs

OpenSpec mode. See `docs/agents/domain.md`.

### entro-connect

Walk a Connect run (Orientation prose, Operation mode, Lock the Select Provider tile and Integration path, Intro, inputs after auth, Connect log) using `.agents/skills/entro-connect/`. Stop before Lock when the index marks the tile `captureRequired`. Read only that folder's Skill catalog. Do not open `documentation/` pages for a Connect run.

### User gates

Present forks, confirmations, and every value you need from the user via **structured-choices** — a gate is a direct call to the question tool (in Cursor, built-in `AskQuestion`, invoked like `Read` or `Grep`), made as your first move because the call itself is the check, not your reading of the tool list; one gate per message, options carried by the call.

<!-- context7 -->
Use the `ctx7` CLI to fetch current documentation whenever the user asks about a library, framework, SDK, API, CLI tool, or cloud service — even well-known ones like React, Next.js, Prisma, Express, Tailwind, Django, or Spring Boot. This includes API syntax, configuration, version migration, library-specific debugging, setup instructions, and CLI tool usage. Use even when you think you know the answer — your training data may not reflect recent changes. Prefer this over web search for library docs.

Do not use for: refactoring, writing scripts from scratch, debugging business logic, code review, or general programming concepts.

## Steps

1. Resolve library: `npx ctx7@latest library <name> "<what to look up>"` — use the official library name with proper punctuation (e.g., "Next.js" not "nextjs", "Customer.io" not "customerio", "Three.js" not "threejs")
2. Pick the best match (ID format: `/org/project`) by: exact name match, description relevance, code snippet count, source reputation (High/Medium preferred), and benchmark score (higher is better). If results don't look right, try alternate names or queries (e.g., "next.js" not "nextjs", or rephrase the question)
3. Fetch docs: `npx ctx7@latest docs <libraryId> "<what to look up>"` — run a separate `docs` command per distinct concept if the question spans multiple topics, unless it's about how they interact
4. Answer using the fetched documentation

You MUST call `library` first to get a valid ID unless the user provides one directly in `/org/project` format. Be specific about what to look up in the library's documentation — specific and detailed queries return better results than vague single words, but keep each query to a single concept unless the question is about how concepts interact; combined multi-topic queries dilute ranking and return shallow results for each topic. Do not run more than 3 commands per question. Do not include sensitive information (API keys, passwords, credentials) in queries.

For version-specific docs, use `/org/project/version` from the `library` output (e.g., `/vercel/next.js/v14.3.0`).

If a command fails with a quota error, inform the user and suggest `npx ctx7@latest login` or setting `CONTEXT7_API_KEY` env var for higher limits. Do not silently fall back to training data.
<!-- context7 -->
