# VA and clusters

Official: [VA](https://developer.sailpoint.com/docs/tools/cli/va/), [Clusters](https://developer.sailpoint.com/docs/tools/cli/cluster). Flags: `sail va --help`, `sail cluster --help`.

## Intent map

| Intent | Start with |
| --- | --- |
| VA collect / update by IP | `sail va` subcommands per `--help` |
| Parse VA logs locally | `sail va parse` (local file work) |
| List / get clusters | `sail cluster list`, `sail cluster get` |
| Cluster log get/set | `sail cluster` log subcommands per `--help` |

Tenant-facing calls use `--env <name>`. Log level changes and updates are mutating — goal confirm from `SKILL.md`.

## Gotchas

- Some VA operations need network reachability to the appliance IP, not only API auth.
- `parse` is local; still useful after collect.

## Done when

VA/cluster list/get/log action completed, or the operator has the connectivity/auth blocker named.