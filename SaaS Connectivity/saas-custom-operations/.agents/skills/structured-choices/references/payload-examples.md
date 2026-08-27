# Cursor `AskQuestion` payloads

Call shapes for a gate in Cursor. Each block below is a literal argument object for `AskQuestion`.

An option carries `id` and `label` only, so anything explanatory rides inside the `label` — an unrecognised property can be rejected and cost you the gate.

Running on another host: [`other-hosts.md`](other-hosts.md).

## Single choice

```json
{
  "questions": [
    {
      "id": "schema",
      "prompt": "Which OpenSpec schema should we install?",
      "options": [
        { "id": "superpowers-bridge", "label": "superpowers-bridge — OpenSpec + Superpowers orchestration (Recommended)" },
        { "id": "minimalist", "label": "minimalist — fast spec-to-tasks path" },
        { "id": "behaviour-driven", "label": "behaviour-driven — Gherkin-style specs" }
      ]
    }
  ]
}
```

## Confirm

Two options, recommended first.

```json
{
  "questions": [
    {
      "id": "install-skills",
      "prompt": "Install recommended behavioral skills for this schema?",
      "options": [
        { "id": "yes", "label": "Yes, install (Recommended)" },
        { "id": "skip", "label": "Skip — I will install manually" }
      ]
    }
  ]
}
```

## Multi-select

`allow_multiple` lets the user pick more than one option.

```json
{
  "title": "Domain specs",
  "questions": [
    {
      "id": "domains",
      "prompt": "Confirm the domain specs to create:",
      "allow_multiple": true,
      "options": [
        { "id": "billing", "label": "billing — payments and subscriptions" },
        { "id": "identity", "label": "identity — auth and users" },
        { "id": "catalog", "label": "catalog — products and inventory" }
      ]
    }
  ]
}
```

## Multi-question round

One gate per grilling round — one `questions` entry per frontier decision. The user answers each in sequence inside the single gate.

```json
{
  "title": "Grilling — round 1",
  "questions": [
    {
      "id": "auth-strategy",
      "prompt": "How should unauthenticated users reach the dashboard?",
      "options": [
        { "id": "redirect-login", "label": "Redirect to login (Recommended)" },
        { "id": "public-readonly", "label": "Public read-only view — cached summary, no PII" },
        { "id": "block-404", "label": "Return 404 — hide that the dashboard exists" }
      ]
    },
    {
      "id": "session-store",
      "prompt": "Where should sessions live?",
      "options": [
        { "id": "redis", "label": "Redis — shared across app instances (Recommended)" },
        { "id": "cookie", "label": "Signed cookie — stateless; size limits apply" },
        { "id": "postgres", "label": "Postgres — reuse existing DB; heavier ops" }
      ]
    }
  ]
}
```

Record each answer by question `id` and option `id` before recomputing the frontier.

## Free-text answers

Cursor always offers the user an "Other" escape hatch, so a gate accepts a typed answer without any extra field. Map whatever they type back to an option `id` where it fits, or treat it as a new constraint where it does not.
