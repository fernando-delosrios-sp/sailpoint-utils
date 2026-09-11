---
name: sail
description: >-
  sail CLI against Identity Security Cloud (ISC) tenants: run any sail command,
  call tenant APIs, list/infer/create environments, and set up PAT or OAuth.
  Use when the operator uses sail, manages an ISC tenant via the CLI, or needs
  sail environment selection or auth setup.
---

# sail

Drive the [SailPoint CLI](https://developer.sailpoint.com/docs/tools/cli) against ISC. Control plane is `sail` domain commands plus `sail api` for any REST path. Discover flags with `sail <cmd> --help`; do not invent flags from memory.

## Questions

Forks, confirms, and values the operator must supply go through the host’s **interactive question** UI (e.g. Cursor `AskQuestion`): fixed options when candidates exist, one prompt per free-text value otherwise. Never a chat “Reply with:” checklist. Do not load or require the `structured-choices` skill — match that style only.

## Steps

1. **Preconditions** — Confirm `sail` is on PATH (`sail version` or `sail -h`). If missing, tell the operator to run `brew tap sailpoint-oss/tap && brew install sailpoint-cli` (or the [install path](https://developer.sailpoint.com/docs/tools/cli) for their OS) and wait until they have. Then run `sail env list`.

   **Done when:** `sail` runs and you have the environment list (may be empty).

2. **Resolve env** — If the conversation or task names an environment that matches `sail env list`, use that name. Otherwise one interactive question listing the configured environments (include create-new when the list is empty or they need another). Every later `sail` invocation includes `--env <name>`. Prefer `--env` over changing the active default.

   Zero environments or create-new: open [`env.md`](env.md) and gather create + auth via interactive questions first.

   **Done when:** one environment name is known for this run.

3. **Route** — Open only the disclosed file for the command family, then run:

   | Family | File |
   | --- | --- |
   | Environments, auth, `set` | [`env.md`](env.md) |
   | Raw REST (`get`/`post`/`put`/`patch`/`delete`) | [`api.md`](api.md) |
   | Workflows | [`workflow.md`](workflow.md) |
   | Transforms | [`transform.md`](transform.md) |
   | Search | [`search.md`](search.md) |
   | SP-Config | [`spconfig.md`](spconfig.md) |
   | SaaS connectors (`conn`) | [`connectors.md`](connectors.md) |
   | VA / clusters | [`va-cluster.md`](va-cluster.md) |
   | rule, report, sanitize, sdk, jsonpath, reassign, ui-plugins | [`other.md`](other.md) |

   Tenant REST with no first-class command → [`api.md`](api.md).

   **Done when:** the matching file is loaded (or the goal is env/auth only and [`env.md`](env.md) covers it).

4. **Mutating goal** — Create, update, delete, import, upload, reassign, or any other write: one interactive confirm for the stated goal. The prompt **shows** the resolved env name; it does not ask the operator to re-select or re-confirm the env. After accept, run every call the goal needs under that `--env`.

   Reads (list, get, search, download, status) proceed without that confirm.

   **Done when:** either the goal was read-only, or the operator accepted the mutating confirm.

5. **Execute** — Run `sail … --env <name>` per the disclosed file. For list/search pages, follow the pagination rule in [`api.md`](api.md) (or the family's own notes). Report outcomes and errors plainly.

   **Done when:** the operator's goal is complete or blocked on a clear error/next step.

## Secrets

PAT client secrets stay out of chat. Run `sail set pat --env <name>` in the agent terminal so the operator can type the secret there. Never paste, log, or echo the secret.