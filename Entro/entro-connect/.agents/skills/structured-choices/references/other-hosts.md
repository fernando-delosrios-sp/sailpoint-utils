# Hosts other than Cursor

Reached after a question-tool call came back as an error.

A judgement about your tool list is not an error, and neither is a conclusion about which host you are on — both leave this page unreached. Go back and make the call; its result is what sends you here.

Open with the question itself in every form below. A line reporting which tools you have costs the user a read and gives them nothing to act on.

Whatever the host, the gate rules from [`SKILL.md`](../SKILL.md#gate-rules) still hold: one gate per message, two or more fixed options, recommended option first, answer recorded by `id`.

Work down this page in order and use the first form the host supports.

## 1. A question tool under another name

Most hosts expose an equivalent of `AskQuestion` — `prompt_user_decision` is the common one. Same content, different field names:

| Need | Cursor `AskQuestion` | Generic decision tool |
| --- | --- | --- |
| The question | `questions[].prompt` | `prompt_text` |
| Option value | `options[].id` | `options[].value` |
| Option display | `options[].label` | `options[].label` |
| Explanatory detail | fold into `label` | `options[].description` |
| Several answers | `allow_multiple: true` | `input_type: "select"` + multi flag |
| Confirm | two-option question | `input_type: "confirm_dialog"` |
| Free-text answer | built-in "Other" | `allow_custom_input` |
| Round of questions | `questions` array | repeat the gate, or a host batch API |

Cursor payload shapes to map from: [`payload-examples.md`](payload-examples.md).

## 2. A host that parses the contract

A host you know consumes `<decision_prompt>` JSON gets this block, and halts immediately after the closing tag. Every other reader sees unreadable JSON, so it stays out of a human-facing gate.

```markdown
<decision_prompt>
{
  "type": "button_group",
  "question": "<one sentence>",
  "options": [
    { "id": "<value>", "label": "<display> (Recommended)", "detail": "<optional>" }
  ],
  "allow_custom_input": true,
  "recommended": "<id>"
}
</decision_prompt>
```

`type`: `button_group` | `select` | `confirm_dialog` | `multi_select`

## 3. A host with no question tool

Ask in prose: the question on its own line, then one short line per option — `id` first so the user can answer with a single word, recommended option first. Halt and wait.

This page carries no worked example of that shape on purpose. A ready-made prose gate is the artifact agents reach for even where a question tool answers, so the shape is described rather than drafted, and rendered only once a call has actually failed.

Map the answer back to an option `id` before continuing, exactly as with a tool call.
