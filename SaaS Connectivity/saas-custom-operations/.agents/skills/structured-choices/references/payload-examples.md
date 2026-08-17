# Payload examples

Universal `<decision_prompt>` shapes and platform adapter mapping.

## Schema selection

```json
{
  "type": "button_group",
  "question": "Which OpenSpec schema should we install?",
  "options": [
    { "id": "superpowers-bridge", "label": "superpowers-bridge (Recommended)", "detail": "OpenSpec + Superpowers orchestration" },
    { "id": "minimalist", "label": "minimalist", "detail": "Fast spec-to-tasks path" },
    { "id": "behaviour-driven", "label": "behaviour-driven", "detail": "Gherkin-style specs" }
  ],
  "allow_custom_input": true,
  "recommended": "superpowers-bridge"
}
```

## Permission confirm

```json
{
  "type": "confirm_dialog",
  "question": "Install recommended behavioral skills for this schema?",
  "options": [
    { "id": "yes", "label": "Yes, install (Recommended)" },
    { "id": "skip", "label": "Skip — I will install manually" }
  ],
  "allow_custom_input": false,
  "recommended": "yes"
}
```

## Multi-select domains

```json
{
  "type": "multi_select",
  "question": "Confirm the domain specs to create (select all that apply):",
  "options": [
    { "id": "billing", "label": "billing", "detail": "Payments and subscriptions" },
    { "id": "identity", "label": "identity", "detail": "Auth and users" },
    { "id": "catalog", "label": "catalog", "detail": "Products and inventory" }
  ],
  "allow_custom_input": true,
  "recommended": null
}
```

## Grilling round (multi-question)

One gate per round — map each frontier decision to a question. Cursor `AskQuestion` accepts a `questions` array; universal block uses a wrapper when the host has no native multi-question tool.

**Cursor `AskQuestion` (preferred):**

```json
{
  "title": "Grilling — round 1",
  "questions": [
    {
      "id": "auth-strategy",
      "prompt": "How should unauthenticated users reach the dashboard?",
      "options": [
        { "id": "redirect-login", "label": "Redirect to login (Recommended)" },
        { "id": "public-readonly", "label": "Public read-only view", "detail": "Show cached summary without PII" },
        { "id": "block-404", "label": "Return 404", "detail": "Hide existence of dashboard" }
      ]
    },
    {
      "id": "session-store",
      "prompt": "Where should sessions live?",
      "options": [
        { "id": "redis", "label": "Redis (Recommended)", "detail": "Shared across app instances" },
        { "id": "cookie", "label": "Signed cookie", "detail": "Stateless; size limits apply" },
        { "id": "postgres", "label": "Postgres", "detail": "Reuse existing DB; heavier ops" }
      ]
    }
  ]
}
```

**Session completion (`confirm_dialog`):**

```json
{
  "type": "confirm_dialog",
  "question": "Frontier is empty — do we have shared understanding on this plan?",
  "options": [
    { "id": "yes", "label": "Yes, we align (Recommended)" },
    { "id": "no", "label": "No — keep grilling" }
  ],
  "allow_custom_input": false,
  "recommended": "yes"
}
```

Record each answer by question `id` and option `id` before recomputing the frontier.

## Adapter mapping

| Universal field | Cursor `AskQuestion` | Generic decision tool |
| --- | --- | --- |
| `question` | `prompt` | `prompt_text` |
| `options[].id` | option `id` | `options[].value` |
| `options[].label` | option `label` | `options[].label` |
| `options[].detail` | (append to label or omit) | `options[].description` |
| `multi_select` type | `allow_multiple: true` | `input_type: "select"` + multi flag |
| `confirm_dialog` type | two-option `AskQuestion` | `input_type: "confirm_dialog"` |
| `allow_custom_input` | built-in "Other" (always available) | `allow_custom_input` param |
| Multi-question round | `questions` array (one entry per frontier item) | repeat gate or host-specific batch API |

After the user responds, map their selection back to `id` before continuing.
