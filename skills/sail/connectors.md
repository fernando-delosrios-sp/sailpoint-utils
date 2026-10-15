# SaaS connectors (`conn`)

Flags: `sail conn --help` (command `connectors`, alias `conn`).

## Intent map

| Intent | Start with |
| --- | --- |
| Scaffold a local project | `sail conn init` |
| Create / upload / update / delete in the tenant | `sail conn create`, `upload`, `update`, `delete` |
| Invoke / validate / logs | `sail conn invoke`, `validate`, `logs` |
| List / get | `sail conn list`, `sail conn get` |
| Instances, customizers, tags, versions, stats | the matching subcommand |

`init` is local and needs no `--env`. Every tenant call uses `--env <name>`. Uploads and other writes use the single goal confirm from `SKILL.md`.

The command's default endpoint is `/beta/platform-connectors` (`--conn-endpoint`). Connector objects that this command does not cover use the Connectors group via [`api.md`](api.md).

`npm run debug` inside a connector project is local tooling, not a tenant write.

## Done when

The scaffold exists, the list or get returned, or the upload, invoke, or validate finished with clear output.
