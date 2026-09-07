# Domain Docs

How the engineering skills should consume this repo's domain documentation when exploring the codebase.

This repo uses **OpenSpec mode** (`openspec/config.yaml` present). Do not use `CONTEXT.md` or `CONTEXT-MAP.md` — vocabulary lives in the ubiquitous-language spec.

## Before exploring, read these

- **`openspec/specs/ubiquitous-language/spec.md`** — canonical domain vocabulary (replaces `CONTEXT.md`)
- **Relevant capability specs** under `openspec/specs/<domain>/spec.md` for the area you're about to work in
- **`docs/adr/`** — read ADRs that touch the area you're about to work in (create lazily when decisions are resolved)
- **`docs/agents/change-isolation.md`** — how to behave toward a shared working tree before you mutate it; more than one session works this repo

If any of these files don't exist yet, **proceed silently**. Don't flag their absence; don't suggest creating them upfront. The **domain-modeling** skill (reached via **grill-with-docs**) creates capability specs and ADRs lazily when terms or decisions actually get resolved.

## Adding a Documented method or Method waiver

When Entro publishes a new onboarding page under the integration documentation folders:

1. Cite the page on the owning Add New Account row (or on a Setup method, Authentication method, or Coverage).
2. Add a Setup or Authentication method for each Documented method the page names, with prep steps and Typed actions as the row already requires — or record a Method waiver with a reason sentence.
3. Add fork census entries whose `evidence` quotes appear in the page bytes.
4. Run `python -m pytest`. An uncited page, a blank waiver reason, or a stale quote fails validation. Do not leave the regeneration of `documentation/integrations.json` and the Skill catalog trees uncommitted.

## File structure

```
/
├── docs/
│   └── adr/                              ← rationale (why); create lazily
└── openspec/
    ├── config.yaml
    ├── specs/
    │   ├── ubiquitous-language/spec.md   ← canonical vocabulary
    │   └── <domain>/spec.md              ← domain-based capability specs
    └── changes/<change-name>/            ← pending spec deltas
```

**Naming rule:** Path is always `openspec/specs/<capability>/spec.md`. Use domain-based categories (e.g. `overlay-pipeline/`, `skill-catalog/`), not per-skill folders.

## Use the glossary's vocabulary

When your output names a domain concept (in an issue title, a refactor proposal, a hypothesis, a test name), use the term as defined in `openspec/specs/ubiquitous-language/spec.md`. Don't drift to synonyms the glossary explicitly avoids.

If the concept you need isn't in the glossary yet, that's a signal — either you're inventing language the project doesn't use (reconsider) or there's a real gap (note it for **domain-modeling**; terms marked `promote` in discovery become ubiquitous-language deltas during the specs phase).

## Flag ADR conflicts

If your output contradicts an existing ADR, surface it explicitly rather than silently overriding:

> _Contradicts ADR-0007 (event-sourced orders) — but worth reopening because…_
