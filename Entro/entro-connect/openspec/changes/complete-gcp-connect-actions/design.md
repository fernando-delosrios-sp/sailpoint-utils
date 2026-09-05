## Context

The Google Cloud Platform Console-manual Integration path is marked preferred for
`gcloud`, but its current Configuration plan cannot execute the IAM grant: it
does not identify the required roles or commands. Its API action also covers only
three host-project services, and it omits the documented organization audit-log
step. Entro's pinned Terraform onboarding archive already defines the required
custom organization role, 12 predefined bindings, and default API sets.

The generator owns the Integration index and both `entro-connect` Skill catalog
trees. Connect must consume only cataloged actions and must never handle service
account private keys or other secrets.

## Architecture

```mermaid
flowchart TB
    maintainer[Maintainer]

    subgraph tooling[Entro integration tooling]
        ingest[Catalog ingest generator]
        artifacts[(Generated Integration and Skill catalogs)]
        connect[Connect runtime]
    end

    terraform[Pinned Entro GCP Terraform archive]
    gcp[Google Cloud Platform]

    maintainer -->|Regenerates and validates [CLI/files]| ingest
    terraform -->|Supplies IAM and API defaults [archive/files]| ingest
    ingest -->|Writes actions and checksums [JSON/scripts]| artifacts
    artifacts -->|Provides locked Configuration plan [files]| connect
    connect -->|Executes approved gcloud actions [CLI]| gcp
    maintainer -->|Completes audit-log step [web console]| gcp

    classDef person fill:#08427B,color:#fff,stroke:#052E56;
    classDef container fill:#438DD5,color:#fff,stroke:#2E6295;
    classDef database fill:#438DD5,color:#fff,stroke:#2E6295;
    classDef external fill:#999,color:#fff,stroke:#666;
    class maintainer person;
    class ingest,connect container;
    class artifacts database;
    class terraform,gcp external;
```

## Goals / Non-Goals

**Goals:**

- Distill the pinned Terraform IAM and API definitions into exact, generated
  GCP actions.
- Preserve service-account creation as a separate action and collision gate.
- Keep the generated artifacts, checksums, Integration index, and both Skill
  trees aligned through validation.
- Represent organization audit-log setup as an explicit operator-only step.
- Define verification and rollback evidence for each mutation.

**Non-Goals:**

- Automating private-key creation or moving secrets through the agent.
- Automating Workload Identity Federation.
- Automating organization audit-log policy replacement.
- Changing the pinned Terraform source or redesigning optional APIs as
  Coverages.
- Repairing comparable AWS or Oracle Cloud Infrastructure action gaps.

## Decisions

### D1: Generate executable IAM grants from the pinned Terraform archive

- **Choice**: Extract the custom organization role permission list and all 12
  predefined `roles/*` bindings into one generated, checksummed grant script.
- **Reason**: The archive is the pinned source already used by Entro onboarding,
  while one script gives the operator one review and approval boundary for the
  coherent grant.
- **Considered alternatives**: Hand-maintaining role identifiers would drift
  from the source. One action per binding would fragment one logical change into
  repeated approvals.

### D2: Keep service-account creation separate

- **Choice**: Retain `gcloud iam service-accounts create` as its own Typed action,
  followed by the generated IAM grant action.
- **Reason**: The existing name-collision inspection must complete before any
  grants are attempted, and rollback must know whether this run created the
  account.
- **Considered alternatives**: Folding creation into the grant script would hide
  the collision gate and make ownership during rollback ambiguous.

### D3: Derive enabled APIs from Terraform defaults

- **Choice**: Generate API enablement from the archive's organization-project,
  host-project, and billing-dependent defaults.
- **Reason**: These defaults represent Entro's supported onboarding behavior and
  avoid introducing a new Connect-time selection fork.
- **Considered alternatives**: Keeping only the three current host-project APIs
  leaves the plan incomplete. Asking operators to select optional APIs would
  create policy not present in the source.

### D4: Keep organization audit logging operator-only

- **Choice**: Add an operator-only Prep step with console instructions and
  non-secret evidence.
- **Reason**: The documented `gcloud` route replaces the organization IAM policy
  and is not a safely isolated mutation for Connect to automate.
- **Considered alternatives**: Automating policy replacement has an
  organization-wide blast radius and unsafe merge semantics.

### D5: Treat generated onboarding files as atomic generator output

- **Choice**: Generate scripts, checksums, catalog references, and both Skill
  trees together; validation rejects any byte or metadata mismatch.
- **Reason**: Connect must execute the reviewed bytes named by the catalog, and
  both installed Skill locations must behave identically.
- **Considered alternatives**: Hand-edited generated files or independently
  maintained copies permit silent drift.

## Risks / Trade-offs

- [Risk] Terraform archive layout changes and extraction silently misses data.
  -> Mitigation: fail generation on missing expected role/API structures and
  assert exact derived counts and checksums in tests.
- [Risk] A partial write leaves catalogs and scripts inconsistent.
  -> Mitigation: validate generated bytes and metadata before publishing all
  outputs together.
- [Risk] IAM rollback removes access another process later relies on.
  -> Mitigation: scope rollback to bindings and the custom role created by the
  generated action, and require verification before removal.
- [Trade-off] Enabled APIs remain enabled on rollback.
  -> Reason for acceptance: disabling shared APIs can disrupt unrelated
  consumers and is less safe than leaving them enabled.
- [Trade-off] Audit-log setup requires manual console work.
  -> Reason for acceptance: it avoids replacing an organization-wide IAM policy
  through an unsafe command path.

## Migration Plan

1. Add failing contract and ingest tests for the complete GCP Console-manual
   Configuration plan, generated artifact checksums, and two-tree alignment.
2. Extend extraction and validation for Terraform-derived IAM and API data.
3. Regenerate the Integration index and both Skill catalog trees in one change.
4. Run the canonical test command and OpenSpec validation.
5. Document the operator-visible change in the changelog.

Rollback removes the generated bindings and custom role, then deletes the
service account only when the run created it. It does not disable APIs. Reverting
the code and generated outputs together restores the previous catalog.

Acceptance requires exact custom-role permissions and 12 predefined bindings,
Terraform-default API groups, the operator-only audit-log step, matching
checksums and Skill trees, and a passing canonical test suite.

## Open Questions

None. Private-key handling, Workload Identity Federation, and optional API
modeling remain deferred to separate changes.
