# VA and clusters

Flags: `sail va --help`, `sail cluster --help` (alias `cl`).

## Intent map

| Intent | Start with |
| --- | --- |
| List / get VAs from the tenant | `sail va list`, `sail va get` |
| Collect files from a VA | `sail va collect <host>` |
| Update a VA over the network | `sail va update` |
| Parse VA logs locally | `sail va parse` |
| List / get clusters | `sail cluster list`, `sail cluster get` |
| Cluster log level | `sail cluster log get`, `sail cluster log set` |

Tenant calls use `--env <name>`. Log-level changes and VA updates are mutating: goal confirm from `SKILL.md`.

`collect` and `update` open SSH (port 22) and SFTP to the VA as the `sailpoint` user. They need network reach to that host, not only API auth. Let the CLI prompt for the VA password. `parse` reads local files after a collect.

## Done when

The list, get, collect, parse, or log action finished, or the operator has the connectivity or auth blocker named.
