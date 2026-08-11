---
name: improve-codebase-architecture
description: Scan a codebase for deepening opportunities, present them as a markdown report, then grill through whichever one you pick. OpenSpec-aware when capability specs exist.
disable-model-invocation: true
---

# Improve Codebase Architecture

Surface architectural friction and propose **deepening opportunities** — refactors that turn shallow modules into deep ones. The aim is testability and AI-navigability.

This command is _informed_ by the project's domain model and built on a shared design vocabulary in [LANGUAGE.md](LANGUAGE.md) (**module**, **interface**, **depth**, **seam**, **adapter**, **leverage**, **locality**) and its principles (the deletion test, "the interface is the test surface", "one adapter = hypothetical seam, two = real"). Use these terms exactly in every suggestion — don't drift into "component," "service," "API," or "boundary."

## Mode detection

Before domain-model guidance, check whether OpenSpec is present in the target repo:

- `openspec/config.yaml` exists, or
- `openspec/specs/` exists with at least one capability spec

If either is true, follow **OpenSpec mode** below. Otherwise follow **Legacy mode**.

When OpenSpec is absent and the user needs to initialize it, suggest the `openspec-init` skill.

### OpenSpec mode

- Read `openspec/specs/ubiquitous-language/spec.md` for domain terms that name good seams.
- Scan relevant capability specs under `openspec/specs/` for architectural decisions this command should not re-litigate.
- Do **not** use `CONTEXT.md`, `CONTEXT-MAP.md`, or `docs/adr/`.

See `/domain-modeling` and [OPENSPEC-MODE.md](../domain-modeling/OPENSPEC-MODE.md) for how terms and decisions are recorded.

### Legacy mode

- The domain language in `CONTEXT.md` (or context-specific `CONTEXT.md` via `CONTEXT-MAP.md`) gives names to good seams.
- ADRs in `docs/adr/` record decisions this command should not re-litigate.

## Process

### 1. Explore

**Scope before you scan — YAGNI.** Deepening a module pays off by making future changes to it easier, so put extra weight on the parts of the codebase that have recently changed. Decide *where* to look before you look:

- If the user named a direction — a module, a subsystem, a pain point — take it, and skip the inference below.
- Otherwise, walk back a good stretch of the commit history (`git log --oneline`) to find the codebase's hot spots — the files and areas that keep coming up — and let those paths pull your attention first. If the changes are scattered with no clear hot spot, widen the net.

Read the project's domain glossary and recorded decisions for the area you're touching — per mode detection above.

Then use the Agent tool with `subagent_type=Explore` to walk the codebase. Don't follow rigid heuristics — explore organically and note where you experience friction:

- Where does understanding one concept require bouncing between many small modules?
- Where are modules **shallow** — interface nearly as complex as the implementation?
- Where have pure functions been extracted just for testability, but the real bugs hide in how they're called (no **locality**)?
- Where do tightly-coupled modules leak across their seams?
- Which parts of the codebase are untested, or hard to test through their current interface?

Apply the **deletion test** to anything you suspect is shallow: would deleting it concentrate complexity, or just move it? A "yes, concentrates" is the signal you want.

### 2. Present candidates as a markdown report

Render the review as markdown in the chat per [MARKDOWN-REPORT.md](MARKDOWN-REPORT.md). Optionally save the same content to `ARCHITECTURE-REVIEW.md` at the project root. No HTML, CDN dependencies, or browser step.

Each candidate gets a **before/after visualisation** (Mermaid and/or ASCII). Be visual.

For each candidate, render a card with:

- **Files** — which files/modules are involved
- **Problem** — why the current architecture is causing friction
- **Solution** — plain English description of what would change
- **Benefits** — explained in terms of locality and leverage, and how tests would improve
- **Before / After diagram** — side-by-side or stacked, illustrating the shallowness and the deepening
- **Recommendation strength** — one of `Strong`, `Worth exploring`, `Speculative`

End the report with a **Top recommendation** section: which candidate you'd tackle first and why.

**Use the project's domain vocabulary for domain nouns, and [LANGUAGE.md](LANGUAGE.md) for architecture.** If the ubiquitous-language spec (OpenSpec) or `CONTEXT.md` (legacy) defines "Order," talk about "the Order intake module" — not "the FooBarHandler," and not "the Order service."

**Decision conflicts**: if a candidate contradicts an existing capability spec requirement (OpenSpec) or ADR (legacy), only surface it when the friction is real enough to warrant reopening the decision. Mark it clearly in the card (e.g. a warning callout: _"contradicts `module-ordering` spec — but worth reopening because…"_ or _"contradicts ADR-0007 — but worth reopening because…"_). Don't list every theoretical refactor a recorded decision forbids.

Do NOT propose interfaces yet. After the report, ask the user: "Which of these would you like to explore?"

### 3. Grilling loop

Once the user picks a candidate, run the `/grilling` skill to walk the decision tree with them — constraints, dependencies, the shape of the deepened module, what sits behind the seam, what tests survive.

Side effects happen inline as decisions crystallize — run the `/domain-modeling` skill to keep the domain model current. It handles OpenSpec vs legacy targets automatically:

- **Naming or sharpening domain terms?** Domain-modeling updates the ubiquitous-language spec (OpenSpec) or `CONTEXT.md` (legacy).
- **User rejects the candidate with a load-bearing reason?** Domain-modeling offers to record it in a capability spec or OpenSpec change (OpenSpec) or as an ADR (legacy) — only when the reason would help a future explorer avoid re-suggesting the same thing.
- **Want to explore alternative interfaces for the deepened module?** Run the `/codebase-design` skill and use its design-it-twice parallel sub-agent pattern.
