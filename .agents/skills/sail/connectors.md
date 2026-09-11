# SaaS connectors (`conn`)

Official: [CLI Connectors](https://developer.sailpoint.com/docs/tools/cli/connectors/), [common CLI commands](https://developer.sailpoint.com/docs/connectivity/saas-connectivity/common-cli-commands). Flags: `sail conn --help` (command `connectors`, alias `conn`).

## Intent map

| Intent | Start with |
| --- | --- |
| Scaffold local project | `sail conn init` (local; no tenant `--env` required for scaffold itself) |
| Create / upload / update / delete in tenant | `sail conn create`, `upload`, `update`, `delete` |
| Invoke / validate / logs | `sail conn invoke`, `validate`, `logs` |
| List | `sail conn list` |

Tenant operations always `--env <name>`. Uploads and other writes use the single goal confirm from `SKILL.md`.

## Gotchas

- Local debug is often `npm run debug` inside the connector project — that is local tooling, not a tenant mutate.
- Upload targets the configured tenant; confirm shows the env.
- For connector config objects only available via REST, fall back to [`api.md`](api.md).

## Done when

The connector lifecycle step finished (scaffold created, list returned, or upload/invoke/validate completed with clear output).