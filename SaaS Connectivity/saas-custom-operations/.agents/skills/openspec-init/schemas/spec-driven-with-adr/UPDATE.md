# spec-driven-with-adr Update

Stub — full migration notes not yet documented for this schema.

> **openspec-init routing:** Invoke **openspec-init** (update path). Follow skill steps U1–U7; this schema uses the generic policy below until a fuller `UPDATE.md` is added.

## Version signals

| Signal | File |
|---|---|
| Graph contract | `schema.yaml` → `version:` |
| Bundle release | `VERSION` (if present) |

**Hard-stop** when bundled graph `version` > local. **Warn-only** on bundle major bump with same graph version.

## What the update touches

| Path | Action |
|---|---|
| `openspec/schemas/spec-driven-with-adr/` | Full replace from bundled copy (diff + ack) |
| `openspec/config.yaml` | Refresh rules; preserve `context:` and custom rules (diff + ack) |
| Agent routing | Section diff/replace if schema ships `templates/adopters/*.fragment.md` |
| Companion skills | Full `INSTALL.md` Skills list when present |
| `openspec/specs/**` | Never modify existing content |
| `openspec/changes/**` | Never modify |

## Verify (update)

1. `openspec schema validate spec-driven-with-adr`
2. Required skills from `INSTALL.md` present (if any)
