---
name: search
description: >-
  Search developer knowledge. lookup: library, framework, SDK, CLI, or cloud API
  questions — Context7, inline answer. investigate: topic research or reading
  legwork — background agent, findings as a repo Markdown file.
---

Same intent ("look this up"), two depth contracts. Classify once, then follow one branch to completion.

## Route

1. **Classify**
   - **lookup** — a direct answer suffices: one library, one API/config/syntax question, version-specific behavior, setup or CLI usage.
   - **investigate** — reading legwork delegated: multiple sources synthesized, primary-source audit, or findings saved to the repo as Markdown.
   - When unsure, start **lookup**; escalate to **investigate** when lookup exhausts its command budget or the user wants a written artifact.

2. **Follow the branch** — load and run [`LOOKUP.md`](LOOKUP.md) or [`INVESTIGATE.md`](INVESTIGATE.md).

`/find-docs` → lookup. `/research` → investigate.
