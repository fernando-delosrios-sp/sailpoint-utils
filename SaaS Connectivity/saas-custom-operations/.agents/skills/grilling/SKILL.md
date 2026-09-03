---
name: grilling
description: Grill the user relentlessly about a plan, decision, or idea. Use when the user wants to stress-test their thinking, or uses any 'grill' trigger phrases.
---

Stress-test a plan, decision, or idea until shared understanding. Map decisions as a **design tree**; work it in **rounds**.

## Design tree

Every decision branches into decisions that hang off it. The **frontier** is every decision whose prerequisites are settled — askable now without guessing at unsettled answers.

## Round loop

1. Compute the frontier from settled answers.
2. Present the whole frontier as one structured round (below). Halt until every question is answered.
3. Record answers by option `id` (or custom input when used).
4. Recompute — settled decisions push the frontier outward. A question whose answer depends on another still open in this round belongs to a later round, not this one.
5. Repeat until the frontier is empty.

## Present a round

Follow [`structured-choices`](../structured-choices/SKILL.md). One gate per round — never numbered prose lists.

**Multi-question round:** one decision-tool call (e.g. Cursor `AskQuestion`) with a `questions` entry per frontier item. The user answers each in sequence within that single gate.

Per question:

- stable `id` for the decision (e.g. `auth-strategy`)
- one-sentence `prompt`; context in option `detail` when needed
- two or more concrete options; mark recommendation `(Recommended)` first
- open branches — supply plausible options; host "Other" captures custom answers

Do not duplicate options in prose after the tool call.

## Facts vs decisions

Finding facts is your job — dispatch a sub-agent when a frontier question needs environment facts. A running exploration is an unsettled prerequisite; only downstream questions wait — ask the rest of the frontier now. Decisions are the user's.

## Done

Frontier empty and user confirms shared understanding (`confirm_dialog` gate). Every branch of the design tree visited, nothing left silently assumed. Do not act until confirmed.
