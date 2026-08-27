---
name: grilling
description: Grill the user relentlessly about a plan, decision, or idea. Use when the user wants to stress-test their thinking, or uses any 'grill' trigger phrases.
---

Stress-test a plan, decision, or idea until you reach a shared understanding. Map this as a **design tree**: every decision branches into the decisions that hang off it. Work the tree in **rounds**.

## Design tree

Every decision branches into decisions that hang off it. The **frontier** is every decision whose prerequisites are settled — askable now without guessing at unsettled answers.

## Round loop

1. Compute the frontier from settled answers.
2. Present the whole frontier as one structured round (below). Halt until every question is answered.
3. Record answers by option `id` (or custom input when used).
4. Recompute — settled decisions push the frontier outward. A question whose answer depends on another still open in this round belongs to a later round, not this one.
5. Repeat until the frontier is empty.

## Present a round

Follow [structured-choices](../structured-choices/SKILL.md). One gate per round — never numbered prose lists.

**Multi-question round:** one decision-tool call (e.g. Cursor `AskQuestion`) with a `questions` entry per frontier item. The user answers each in sequence within that single gate.

Per question:

- stable `id` for the decision (e.g. `auth-strategy`)
- one-sentence `prompt`; context in option `detail` when needed
- two or more concrete options; mark recommendation `(Recommended)` first
- open branches — supply plausible options; host "Other" captures custom answers

Do not duplicate options in prose after the tool call.

## Facts vs decisions

Finding _facts_ is your job, never the user's. When a frontier question needs a fact from the environment (filesystem, tools, etc.), dispatch a sub-agent to find it; don't ask the user for anything you could look up yourself. Don't block on it: a running exploration is an unsettled prerequisite, so only the questions downstream of it wait for the sub-agent to report; ask the rest of the frontier now. The _decisions_ are the user's: put each to them and wait.

## Done

The session is done when the frontier is empty and the user confirms shared understanding (`confirm_dialog` gate per structured-choices). Do not act on it until confirmed. Every branch of the design tree visited, nothing left silently assumed.
