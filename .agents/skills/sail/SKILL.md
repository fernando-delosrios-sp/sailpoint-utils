---
name: sail
description: >-
  Drive sail CLI against Identity Security Cloud (ISC) tenants: call APIs,
  query/mutate workflows, transforms, search, connectors, or manage CLI environments.
---

# sail

Drive `sail` against an ISC tenant. Domain commands cover workflows, transforms, search, SP-Config, connectors, VA, and clusters. Every other tenant call is `sail api` with the path from the collection group file.

Flags come from `sail <cmd> --help`. Paths, methods, query fields, and body examples come from the group file named in [`api/index.md`](api/index.md). Fetch a SailPoint doc only to close a gap: [CLI](https://developer.sailpoint.com/docs/tools/cli) or [API specs](https://developer.sailpoint.com/docs/api).

## Interactive Prompts & Environment Source of Truth

`~/.sailpoint/config.yaml` is the single source of truth for environments.

> [!CAUTION]
> Never run bare `sail env list` or `sail env show` to inspect environments. Both commands issue an interactive prompt (`Press Enter to continue`) that hangs non-interactive sessions. Redirecting with `< /dev/null` triggers an infinite loop of EOF warnings. Always read `~/.sailpoint/config.yaml` directly. If `sail env list` must be run via CLI, pipe a newline: `printf "\n" | sail env list`.

Forks, confirms, and values the operator must supply go through the host’s interactive question UI (`AskQuestion`). Fixed options when candidates exist, one prompt per free-text value otherwise.

## Steps

1. **Resolve environment** — Read `~/.sailpoint/config.yaml` to inspect configured environments and `activeenvironment`.
   - If the task or conversation names an environment (e.g. `emea-tes-team`) or matching tenant URL / host, select it.
   - Else if `activeenvironment` is set, select it.
   - Else if multiple environments exist and neither context nor active default resolves it, ask the operator once with an interactive question.
   - If no environments exist, open [`env.md`](env.md) to create one.

   Pass `--env <name>` explicitly on every `sail` invocation.
   If `sail` is missing from PATH, prompt the operator to install: macOS `brew install sailpoint-oss/tap/sailpoint-cli`; others: https://github.com/sailpoint-oss/sailpoint-cli/releases.

   **Done when:** target `--env <name>` is resolved.

2. **Route** — Check the disclosed reference file for the command family only when needed:

   | Family | File | Notes |
   | --- | --- | --- |
   | Environments, auth, `set` | [`env.md`](env.md) | Reads `~/.sailpoint/config.yaml`; avoids CLI prompts |
   | Raw REST (`get`/`post`/`put`/`patch`/`delete`) | [`api.md`](api.md) | Handles stderr/stdout output streams & JSON extraction |
   | Workflows | [`workflow.md`](workflow.md) | `workflow list/get/download/create/update/delete` |
   | Transforms | [`transform.md`](transform.md) | `transform list/create/update/delete/preview/download` |
   | Search | [`search.md`](search.md) | Inline queries via `POST /v3/search` vs file exports |
   | SP-Config | [`spconfig.md`](spconfig.md) | Config export/import jobs |
   | SaaS connectors (`conn`) | [`connectors.md`](connectors.md) | Connector dev & lifecycle |
   | VA / clusters | [`va-cluster.md`](va-cluster.md) | Virtual appliances & cluster management |
   | rule, report, sanitize, sdk, jsonpath, reassign | [`other.md`](other.md) | Subcommands |

   For raw REST: known endpoints (e.g. `/v3/search`, `/v3/sources`, `/transforms/v1`, `/identities/v1`) invoke directly. Consult [`api/index.md`](api/index.md) and a group file only when looking up an unfamiliar path, field, or schema.

   **Done when:** relevant command family file is identified and consulted if necessary.

3. **Mutating goal** — Create, update, delete, import, upload, reassign, or any other write: one interactive confirm for the stated goal. The prompt **shows** the resolved env name; it does not ask the operator to re-select or re-confirm the env. After accept, run every call the goal needs under that `--env`.

   Reads (list, get, search, download, status) proceed immediately without confirm.

   **Done when:** either the goal was read-only, or the operator accepted the mutating confirm.

4. **Execute** — Run `sail … --env <name>` per the disclosed file. For raw REST and JSON handling, strip CLI log headers and status per [`api.md`](api.md). Report outcomes and errors plainly.

   **Done when:** the operator's goal is complete or blocked on a clear error/next step.

## Secrets

PAT client secrets and VA passwords stay out of chat and out of command arguments. Run `sail set pat --env <name>` in the agent terminal so the operator can type the secret there. Never paste, log, or echo the secret.
