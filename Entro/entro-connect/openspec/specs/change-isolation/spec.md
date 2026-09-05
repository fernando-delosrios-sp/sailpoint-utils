# Change Isolation

## Purpose

Protect concurrent sessions and generated artifacts from accidental loss while changes share a working tree.

## Requirements

### Requirement: A change never discards work it does not own

A change SHALL NOT discard, stash, revert, or check out over uncommitted work in the shared
working tree that it did not itself create. `git stash`, `git checkout -- <path>`,
`git restore`, `git reset --hard`, and `git clean` MUST NOT be used to clear a working tree
merely because the changes present look unrelated to the change in hand. Unrecognized
uncommitted work MUST be treated as another session's in-flight work. When a change cannot
proceed without a clean tree, it SHALL isolate itself — a git worktree or its own branch —
rather than clearing the tree it shares.

#### Scenario: Unrelated uncommitted work is left alone

- **GIVEN** a working tree carrying uncommitted changes a session did not create
- **WHEN** that session needs to run its own work
- **THEN** it MUST leave those changes in place
- **AND** it MUST NOT stash, revert, or check out over them

#### Scenario: Clean tree is obtained by isolation

- **GIVEN** a change whose verification requires a clean working tree
- **AND** uncommitted work from another session is present
- **WHEN** the change proceeds
- **THEN** it MUST create a worktree or branch for itself
- **AND** the shared tree MUST retain the other session's work

#### Scenario: Stashing another session's work is a defect

- **GIVEN** a stash entry whose message describes the stashed work as unrelated to the stashing change
- **WHEN** that stash is discovered
- **THEN** it MUST be reported as a violation of this requirement
- **AND** the stashed work MUST be recoverable and offered back to its owner

---

### Requirement: Generated artifacts are committed with the curation that produced them

When a change edits a generator whose output is committed — the curated catalog modules and
the artifacts they write — it SHALL commit the generator edit and the regenerated artifacts
together. A change MUST NOT leave regenerated artifacts uncommitted in the shared tree,
because an uncommitted regeneration is indistinguishable from stray work and is the state in
which work has been lost. Verification that reports a dirty tree MUST NOT be satisfied by
discarding the diff.

#### Scenario: Generator edit and its output land together

- **GIVEN** a change that edits the curated catalog and regenerates the committed artifacts
- **WHEN** the change reaches a stopping point
- **THEN** the generator edit and every regenerated artifact MUST be in one commit
- **AND** the working tree MUST NOT be left dirty with that regeneration

#### Scenario: Dirty tree is resolved by committing, not clearing

- **GIVEN** a verification gate that requires an empty `git status --porcelain`
- **AND** the dirt is this change's own regenerated artifacts
- **WHEN** the gate is satisfied
- **THEN** the artifacts MUST be committed
- **AND** they MUST NOT be discarded to make the gate pass

---

### Requirement: Concurrent sessions are detected before mutating the tree

Before a change mutates the shared working tree, it SHALL inspect `git status` and
`git stash list` and account for anything it does not recognize. On finding uncommitted work
or a stash it does not own, it MUST report that to the operator and MUST NOT proceed on an
assumption about whose work it is. A recovered stash SHALL be surfaced with its message and
file list so the operator can decide.

#### Scenario: Foreign stash is surfaced, not silently applied

- **GIVEN** a stash entry the current session did not create
- **WHEN** the session inspects repository state
- **THEN** it MUST report the stash message and its file list to the operator
- **AND** it MUST NOT apply, drop, or pop it without the operator's decision

#### Scenario: Unrecognized dirt halts assumptions

- **GIVEN** uncommitted changes the session cannot attribute to its own work
- **WHEN** the session plans a tree-mutating step
- **THEN** it MUST report those changes before proceeding
