---
name: sail
description: >-
  sail CLI against Identity Security Cloud (ISC) tenants: run any sail command,
  call tenant APIs, list/infer/create environments, and set up PAT or OAuth.
  Use when the operator uses sail, manages an ISC tenant via the CLI, or needs
  sail environment selection or auth setup.
---

# sail

Drive `sail` against an ISC tenant. Domain commands cover workflows, transforms, search, SP-Config, connectors, VA, and clusters. Every other tenant call is `sail api` with the path from the collection group file.

Flags come from `sail <cmd> --help`. Paths, methods, query fields, and body examples come from the group file named in [`api/index.md`](api/index.md). Those files are the contract. A **gap** is a flag, path, field, enum, or error the contract does not state. Fetch a SailPoint doc only to close a gap: [CLI](https://developer.sailpoint.com/docs/tools/cli) or [API specs](https://developer.sailpoint.com/docs/api).

## Questions

Forks, confirms, and values the operator must supply go through the host’s interactive question UI (e.g. Cursor `AskQuestion`): fixed options when candidates exist, one prompt per free-text value otherwise. A chat “Reply with:” checklist is out of bounds.

## Steps

1. **Preconditions** — Confirm `sail` is on PATH (`sail -h`). If it is missing, stop and give the operator the install command: macOS `brew install sailpoint-oss/tap/sailpoint-cli`; other systems, the latest release at https://github.com/sailpoint-oss/sailpoint-cli/releases. Wait until `sail -h` works. Then run `sail env list`.

   **Done when:** `sail` runs and you have the environment list (may be empty).

2. **Resolve env** — If the conversation or task names an environment that matches `sail env list`, use that name. Otherwise one interactive question listing the configured environments (include create-new when the list is empty or they need another). Every later `sail` invocation includes `--env <name>`. Pass `--env` on each command so the shell default stays put.

   Zero environments or create-new: open [`env.md`](env.md) and gather create + auth via interactive questions first.

   **Done when:** one environment name is known for this run.

3. **Route** — Open only the disclosed file for the command family:

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
   | rule, report, sanitize, sdk, jsonpath, reassign | [`other.md`](other.md) |

   Tenant REST with no first-class command → [`api.md`](api.md).

   **Done when:** that file is loaded. For raw REST, [`api/index.md`](api/index.md) is loaded and exactly one group file is loaded before the first `sail api` call.

4. **Mutating goal** — Create, update, delete, import, upload, reassign, or any other write: one interactive confirm for the stated goal. The prompt **shows** the resolved env name; it does not ask the operator to re-select or re-confirm the env. After accept, run every call the goal needs under that `--env`.

   Reads (list, get, search, download, status) proceed without that confirm.

   **Done when:** either the goal was read-only, or the operator accepted the mutating confirm.

5. **Execute** — Run `sail … --env <name>` per the disclosed file. For list/search pages, follow [`api.md`](api.md) and [`api/conventions.md`](api/conventions.md). Report outcomes and errors plainly.

   **Done when:** the operator's goal is complete or blocked on a clear error/next step.

## Secrets

PAT client secrets and VA passwords stay out of chat and out of command arguments. Run `sail set pat --env <name>` in the agent terminal so the operator can type the secret there. Never paste, log, or echo the secret.
