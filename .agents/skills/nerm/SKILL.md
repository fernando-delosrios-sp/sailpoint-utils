---
name: nerm
description: >-
  NERM (Non-Employee Risk Management) tenant APIs via a Sail-associated helper:
  resolve env + NERM URL, mint SHF PAT bearer tokens, and call v1/v2025 REST.
  Use when the operator works a NERM tenant, NERM API, nonemployee.com, or
  Sail-linked NERM auth — not for offline configuration-import JSON authoring.
---

# nerm

Drive live [NERM APIs](https://developer.sailpoint.com/docs/api/nerm/v1) against a tenant associated to an ISC Sail environment. There is no official NERM CLI: the control plane is [`scripts/nerm_api.ps1`](scripts/nerm_api.ps1) (PowerShell Core — auth + HTTP) plus official docs for every path and body.

Offline import-JSON authoring belongs to the separate `nerm-config-import` skill — do not load that skill from here unless the operator is writing TemplateTransfer payloads.

## Questions

Forks, confirms, and values the operator must supply go through the host’s **interactive question** UI (e.g. Cursor `AskQuestion`): fixed options when candidates exist, one prompt per free-text value otherwise. Never a chat “Reply with:” checklist.

## Steps

1. **Preconditions** — Confirm `sail` is on PATH (`sail version` or `sail -h`). If missing, tell the operator to install [SailPoint CLI](https://developer.sailpoint.com/docs/tools/cli) and wait until they have. Confirm `pwsh` is on PATH (`pwsh -NoProfile -Command '$PSVersionTable.PSVersion'`). Confirm the helper runs: `pwsh -NoProfile -File scripts/nerm_api.ps1 -h` from this skill directory (or the absolute path under `skills/nerm/` / `.agents/skills/nerm/`). Then run `pwsh -NoProfile -File scripts/nerm_api.ps1 env list`.

   **Done when:** `sail`, `pwsh`, and the helper run, and you have the association list (may be empty).

2. **Resolve env** — If the conversation or task names a Sail environment that appears in `env list` (or in `sail env list` when associating), use that name. Otherwise one interactive question listing Sail environments that already have a NERM URL (include associate-new when the list is empty or they need another). Every later helper invocation includes `-Env <name>`.

   Zero associations or associate-new: open [`env.md`](env.md) and gather NERM URL + Sail env via interactive questions first. Prefer an existing Sail env with PAT over creating a new one; if no Sail env exists, invoke the `sail` skill to create + set PAT, then return here.

   **Done when:** one Sail environment name with a NERM base URL is known for this run.

3. **Route** — Open only the disclosed file for the goal:

   | Family | File |
   | --- | --- |
   | Association, auth, sidecar | [`env.md`](env.md) |
   | Raw REST (`get`/`post`/`put`/`patch`/`delete`) | [`api.md`](api.md) |

   **Done when:** the matching file is loaded (or the goal is association/auth only and [`env.md`](env.md) covers it).

4. **Mutating goal** — Create, update, delete, or any other write: one interactive confirm for the stated goal. The prompt **shows** the resolved env name and NERM base URL; it does not ask the operator to re-select them. After accept, run every call the goal needs under that `-Env`.

   Reads (list, get, status) proceed without that confirm.

   **Done when:** either the goal was read-only, or the operator accepted the mutating confirm.

5. **Execute** — Run the helper per the disclosed file. Look up the exact method, path, and body on the official [NERM v1](https://developer.sailpoint.com/docs/api/nerm/v1) or [NERM v2025](https://developer.sailpoint.com/docs/api/nerm/v2025/) operation page before each call. For collection pages, follow the pagination rule in [`api.md`](api.md). Report outcomes and errors plainly.

   **Done when:** the operator's goal is complete or blocked on a clear error/next step.

## Secrets

PAT client secrets and bearer tokens stay out of chat. Prefer credentials already stored by `sail set pat`. Never paste, log, or echo secrets or tokens. The helper must not print them either.
