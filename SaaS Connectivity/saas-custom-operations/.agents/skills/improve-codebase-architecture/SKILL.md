---
name: improve-codebase-architecture
description: Scan a codebase for deepening opportunities, present them as a markdown report, grill through whichever one you pick, then write an OpenSpec change package when capability specs exist.
disable-model-invocation: true
---

# Improve Codebase Architecture

Surface architectural friction and propose **deepening opportunities**: refactors that turn shallow modules into deep ones. The aim is testability and AI-navigability.

This command is _informed_ by the project's domain model and built on a shared design vocabulary:

- Use [LANGUAGE.md](LANGUAGE.md) for architecture vocabulary (**module**, **interface**, **depth**, **seam**, **adapter**, **leverage**, **locality**) and its principles (the deletion test, "the interface is the test surface", "one adapter = hypothetical seam, two = real"). Use these terms exactly in every suggestion, and don't drift into "component," "service," "API," or "boundary."
- Domain terms that name good seams, and decisions this command should not re-litigate, come from the mode below.

## Mode detection

Before domain-model guidance, check whether OpenSpec is present in the target repo (same detection as `domain-modeling`):

- `openspec/config.yaml` exists, or
- `openspec/specs/` exists

If either is true, follow **OpenSpec mode**. Otherwise follow **Legacy mode**.

### OpenSpec mode

- Do **not** reference or write `CONTEXT.md`, `CONTEXT-MAP.md`, or `docs/adr/`.
- Read `openspec/specs/ubiquitous-language/spec.md` for domain terms that name good seams.
- Scan relevant capability specs under `openspec/specs/` for architectural decisions this command should not re-litigate.
- During grilling, run `/domain-modeling` for all domain-model side effects — it handles OpenSpec targets (ubiquitous-language spec, capability specs, change workflow).
- When a candidate contradicts an existing capability spec requirement, surface it only when friction warrants reopening — mark as spec conflict, not ADR.

### Legacy mode

- Read `CONTEXT.md` (or context-specific CONTEXT via `CONTEXT-MAP.md`) and `docs/adr/` in the area being touched.
- During grilling, run `/domain-modeling` for CONTEXT.md and ADR side effects.
- ADR conflict callouts use ADR identifiers.

## Process

### 1. Explore

**Scope before you scan: YAGNI.** Deepening a module pays off by making future changes to it easier, so put extra weight on the parts of the codebase that have recently changed. Decide *where* to look before you look:

- If the user named a direction (a module, a subsystem, a pain point), take it, and skip the inference below.
- Otherwise, walk back a good stretch of the commit history (`git log --oneline`) to find the codebase's hot spots, the files and areas that keep coming up, and let those paths pull your attention first. If the changes are scattered with no clear hot spot, widen the net.

Read the domain glossary and settled architectural decisions for the area you're touching first (OpenSpec or legacy, per mode detection).

Then spawn a sub-agent to walk the codebase. Don't follow rigid heuristics; explore organically and note where you experience friction:

- Where does understanding one concept require bouncing between many small modules?
- Where are modules **shallow**, with an interface nearly as complex as the implementation?
- Where have pure functions been extracted just for testability, but the real bugs hide in how they're called (no **locality**)?
- Where do tightly-coupled modules leak across their seams?
- Which parts of the codebase are untested, or hard to test through their current interface?

Apply the **deletion test** to anything you suspect is shallow: would deleting it concentrate complexity, or just move it? A "yes, concentrates" is the signal you want.

### 2. Present candidates as a markdown report

Render the review as markdown in chat per [MARKDOWN-REPORT.md](MARKDOWN-REPORT.md). Optionally save it as `ARCHITECTURE-REVIEW.md` at the project root. No HTML, CDN, or browser step.

Each candidate gets a **before/after visualisation**. Be visual.

For each candidate, render a card with:

- **Files**: which files/modules are involved
- **Problem**: why the current architecture is causing friction
- **Solution**: plain English description of what would change
- **Benefits**: explained in terms of locality and leverage, and how tests would improve
- **Before / After diagram**: side-by-side, illustrating the shallowness and the deepening
- **Recommendation strength**: one of `Strong`, `Worth exploring`, `Speculative`, rendered as a badge
- **Suggested context** / **Decision conflict** as in MARKDOWN-REPORT

End the report with a **Top recommendation** section: which candidate you'd tackle first and why.

Use the project's domain vocabulary for the domain, and [LANGUAGE.md](LANGUAGE.md) for the architecture. If the glossary defines "Order," talk about "the Order intake module," not "the FooBarHandler," and not "the Order service."

**Decision conflicts**: if a candidate contradicts an existing capability spec requirement (OpenSpec) or ADR (legacy), only surface it when the friction is real enough to warrant revisiting. Mark it clearly in the card. Don't list every theoretical refactor a decision forbids.

Do NOT propose interfaces yet. After the report, ask the user: "Which of these would you like to explore?"

### 3. Grilling loop

Once the user picks a candidate, call the Skill tool with "grilling" to walk the decision tree with them: constraints, dependencies, the shape of the deepened module, what sits behind the seam, what tests survive.

Side effects happen inline as decisions crystallize. Call `/domain-modeling` for all domain-model recording in either mode — it owns when/how to record terms and decisions. Optionally call `/codebase-design` and use its design-it-twice parallel sub-agent pattern when exploring alternative interfaces for the deepened module.

After the user confirms shared understanding (grilling done):

- **OpenSpec mode:** Write `openspec/changes/<slug>/` for the picked candidate per [OPENSPEC-CHANGE.md](OPENSPEC-CHANGE.md). `discovery.md` records grill decisions; `design.md` holds the deepening shape (files, seam, tests that survive); `tasks.md` is the apply plan. Do not implement. Hand off via `/opsx:apply <slug>` or **apply-code-changes**.
- **Legacy mode:** Stop after grill — no change folder.
