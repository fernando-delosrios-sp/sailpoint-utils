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

## Value request

Cursor always offers the user an "Other" escape hatch, so a gate accepts a typed answer without any extra field. That is what makes a value request a call: options carry the candidates you can name, `prompt` carries what the value is for, and the typed answer covers the rest. Map whatever they type back to an option `id` where it fits, or take it as the value where it does not.

```json
{
  "questions": [
    {
      "id": "gcp-org-id",
      "prompt": "Which GCP organization ID should this run use? It is the numeric org whose IAM policy receives the read-only role bindings.",
      "options": [
        { "id": "session-org", "label": "123456789012 — the org gcloud organizations list reports for this session (Recommended)" },
        { "id": "other-org", "label": "A different organization — type the numeric ID" }
      ]
    }
  ]
}
```

With nothing to suggest, the gate still goes out: one option restating your best guess, and the user types over it.
