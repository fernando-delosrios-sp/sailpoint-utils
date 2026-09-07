# Change Isolation

More than one session works this repo at a time. This page is the procedure behind the `AGENTS.md` § Concurrent sessions and uncommitted work table. The requirements live in `openspec/specs/change-isolation/spec.md`.

## The rule

Uncommitted work you did not create belongs to another session. You may not clear it to make room for yours.

Forbidden as a way to get a clean tree: `git stash`, `git checkout -- <path>`, `git restore`, `git reset --hard`, `git clean`. Wanting a tidy tree is not a reason. "These changes look unrelated to my task" is not a reason — it is the exact reasoning that has already destroyed work here twice.

When you genuinely need a clean tree, isolate yourself: a git worktree, or your own branch. The tree you share stays as you found it.

## Before you mutate the tree

Read `git status` and `git stash list`. Account for every entry. Anything you cannot attribute to your own work in this session is someone else's until the user says otherwise.

## Finding a stash you do not own

1. Read its message and file list — `git stash show --stat stash@{n}`. Do not apply, pop, or drop it.
2. Report both to the user, along with what the stash appears to contain.
3. Let the user decide. Recovery options worth offering: `git stash branch <name> stash@{n}` to isolate it onto its own branch, or applying it once the concurrent session has finished.
4. If the stash is your own from earlier in this session, say so plainly and recover it.

A stash whose message describes its contents as unrelated to the change that created it is a violation of this spec, not a housekeeping note. Report it as such.

## Generated artifacts

This repo commits generator output: the curated catalog modules (`integration_catalog.py`, `catalog_contracts.py`) write `documentation/integrations.json` and both `entro-connect` Skill catalog trees. Those artifacts are committed alongside the curation that produced them, in one commit.

An uncommitted regeneration is indistinguishable from stray work, which is how it gets swept away. Do not leave one behind.

## Clean-tree gates

Verification gates that require an empty `git status --porcelain` are satisfied by **committing** your work. Discarding the diff to turn the gate green is a defect, not a pass.

## Why this exists

The AWS Terraform setup method was distilled, generated into both skill trees, and verified green — twice. Both times a concurrent session working an unrelated change ran `git stash` and swept it aside, leaving a stash entry reading `wip: unrelated terraform catalog (not configure-once-prompts)`. Nothing failed, because nothing checked; the catalog simply lost a documented onboarding path and the operator stopped being offered Terraform.

The catalog completeness invariant is the backstop that makes such a loss fail `python -m pytest` instead of passing silently. This page is the part that stops it happening at all.
