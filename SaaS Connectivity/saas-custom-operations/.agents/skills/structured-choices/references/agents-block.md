# AGENTS.md blocks

Canonical User gates text for **structured-choices Install**. The ferspec adopters fragment omits User gates — Install owns that content after setup-matt-pocock-skills.

These lines sit in context on every turn, so they name the action and delegate the detail to the skill rather than restating its adapter table.

## Standalone — `## User gates`

Use when the target file has no `## Agent skills` section. Append at end, or update an existing `## User gates` in place.

```markdown
## User gates

At any fork, confirmation, or permission pause, present the choices via the **structured-choices** skill — one gate per message, recommended option first, options carried by the call rather than restated in chat.

A gate is a direct call to the question tool; in Cursor that is built-in `AskQuestion`, invoked like `Read` or `Grep`. Make the call your first move: the call itself is the check, not your reading of the tool list. When a call returns an error, structured-choices carries the alternatives.
```

## Under Agent skills — `### User gates`

Use when `## Agent skills` already exists. Add or update this subsection (after `### Domain docs` when present, else at end of the block).

```markdown
### User gates

Present forks and confirmations via **structured-choices** — a gate is a direct call to the question tool (in Cursor, built-in `AskQuestion`, invoked like `Read` or `Grep`), made as your first move because the call itself is the check, not your reading of the tool list; one gate per message, options carried by the call.
```
