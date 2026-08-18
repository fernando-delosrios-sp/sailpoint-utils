# AGENTS.md blocks

Canonical User gates text for **structured-choices Install**. The ferspec adopters fragment omits User gates — Install owns that content after setup-matt-pocock-skills.

## Standalone — `## User gates`

Use when the target file has no `## Agent skills` section. Append at end, or update an existing `## User gates` in place.

```markdown
## User gates

When presenting forks, confirmations, or permission pauses, follow the **structured-choices** skill — one gate per message; never duplicate options as numbered lists in chat.

Adapter order (first match wins): **native decision tool** → **`<decision_prompt>` block** → **lettered prose**. Native-tool examples: Cursor `AskQuestion`, `prompt_user_decision`. Full contract and payloads: **structured-choices** skill.
```

## Under Agent skills — `### User gates`

Use when `## Agent skills` already exists. Add or update this subsection (after `### Domain docs` when present, else at end of the block).

```markdown
### User gates

Present forks and confirmations via **structured-choices** — native tool (e.g. Cursor `AskQuestion`), `<decision_prompt>`, or lettered prose per that skill's adapter order.
```
