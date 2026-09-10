---
name: structured-choices
description: Present user gates as structured interactive choices at forks, confirmations, and permission pauses.
---

## Gates (runtime)

At each **_gate_** — a fork, confirmation, or permission pause before you proceed — the choices reach the user as buttons they click, through the host's question tool.

### When to gate

- Named-option forks (schema, library, strategy, path among candidates)
- Destructive or irreversible actions (delete, overwrite, force push)
- Permission pauses (install packages/skills, modify config)
- Ambiguous requirements the request or codebase cannot resolve

**Skip the gate** when only one sensible path exists, the question is genuinely open-ended ("What should I call you?"), or no user is available to answer (a CI or scheduled run) — pick a documented default and state the assumption in one line.

The test there is whether a user is present, not which tools you can see. A gate you tried and could not render is the failed call below, not a skip.

### Options already written as a list

Most skills predate this one, so a skill you are running will often spell its choices out as a bulleted list, a blockquoted question, or a "then ask the user" line — sometimes phrased as though you were about to type it into chat.

Read that as **option data for a call**: it describes the fork rather than drafting your message. Take one option per entry, an `id` from the entry's key or a slug of its label, and fold each entry's explanation into its `label`. A wording like "so they can accept it in a word" describes the click, not a request for prose.

A skill that never mentions gates still gets one. Nothing needs to opt in.

### Gate rules

- **One gate per assistant message** — halt until the user responds. A gate may contain multiple questions when another skill composes it (e.g. grilling rounds).
- **Two or more fixed options** — a real fork, carrying the alternatives the user would actually weigh.
- **Record by `id`** — proceed using the option `id`, not paraphrased label text.
- **Recommended first** — list the suggested option first and suffix its `label` with `(Recommended)`.
- **One rendering per gate** — the call carries the options; the message beside it says only why you are asking.

**Candidate count:** 1 match → inline one-line confirm; 2+ matches → full gate.

### Emit the gate

Call the question tool. In Cursor it is **`AskQuestion`**, built in: invoke it directly, the way you invoke `Read` or `Grep`.

**The call is the check.** Make it your first move. Its result is the only evidence about the tool that exists — a reading of your tool list is not evidence, and neither is a conclusion about which host you are on.

```json
{
  "questions": [
    {
      "id": "issue-tracker",
      "prompt": "Where should issues live for this repo?",
      "options": [
        { "id": "github", "label": "GitHub — the remote already points there (Recommended)" },
        { "id": "local-md", "label": "Local markdown — files under .scratch/" }
      ]
    }
  ]
}
```

An option carries `id` and `label`; explanatory detail rides inside the `label`. Halt after the call and let the user answer.

More shapes — confirm, multi-select, grilling rounds: [`payload-examples.md`](references/payload-examples.md).

### When the call comes back an error

Then, and only then, [`other-hosts.md`](references/other-hosts.md) carries the alternatives: the field mapping for a question tool under another name, a JSON contract for hosts that parse one, and the prose form for a host with no question tool at all.

Whichever form you land on, open with the question itself. Your tool situation is yours to handle, not the user's to read about.

### Carve-outs

- **Grilling rounds** — [`grilling`](../grilling/SKILL.md) composes this skill: one multi-question gate per round (native tool `questions` array or equivalent). Not a prose-list exception.
- Async questionnaires for third parties — use [`to-questionnaire`](../to-questionnaire/SKILL.md), not this skill.

## Install

When the user asks to **install** or **set up** structured-choices, read [INSTALL.md](./INSTALL.md).
