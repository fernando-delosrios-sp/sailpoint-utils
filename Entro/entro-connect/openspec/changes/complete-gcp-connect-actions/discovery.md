## Scope

Make Google Cloud Platform Console-manual Connect runs executable through cataloged, generated, checksummed actions for service-account creation, Terraform-derived IAM grants, Terraform-default API enablement, and operator-only audit-log setup; exclude private-key automation, Workload Identity Federation automation, and equivalent AWS or Oracle Cloud Infrastructure gaps.

## Language

No new domain terms are proposed. This change reuses the canonical terms **Skill-held onboarding artifact**, **Doc-derived Typed action**, **Operator-only step**, **Prep step**, **Configuration plan**, and **Typed action**.

## Decisions

Context: an automated Google Cloud Platform Connect run stopped before mutation because its IAM action said to grant “Entro’s read-only roles” without role identifiers or executable commands, even though Entro-published material already contains the missing details.

- Use the full IAM encoding from Entro’s pinned Terraform onboarding archive: its custom organization role permission list plus its 12 predefined `roles/*` bindings.
- Generate checksummed grant and API onboarding artifacts from the pinned Terraform archive during documentation ingest. Generated files and source archive must fail validation when they drift.
- Keep `gcloud iam service-accounts create` as a separate Typed action so the existing service-account collision inspection remains explicit.
- Run IAM grants as one generated, checksummed script after service-account creation instead of exposing one approval per binding.
- Follow the Terraform defaults for API enablement: the archive’s organization-project defaults, host-project defaults, and billing-dependent defaults.
- Keep organization audit-log configuration operator-only in the GCP console. The documented `gcloud` alternative would require replacing the organization IAM policy rather than making a safely isolated update.
- Treat generated onboarding artifacts as committed generator output and update both `entro-connect` skill trees together.

## Open questions

Resolved for this change. Optional API selection is inherited from the pinned Terraform defaults rather than introduced as a new Connect-time fork.

Deferred:

- Automating private-key creation through a Secret sink.
- Automating Workload Identity Federation.
- Repairing similar underspecified AWS and Oracle Cloud Infrastructure actions.
- Redesigning optional GCP features as Coverages.

## Scenarios discussed

- A new service-account name is available: Connect creates it, then grants the exact Entro-derived IAM configuration.
- The service-account name already exists: Connect stops at the existing collision gate before running the grant script.
- Entro changes the Terraform role, permission, or API lists: ingest regeneration changes the generated artifacts and checksums; stale generated output fails validation.
- An operator chooses Console manual in automated mode: the agent executes only cataloged Typed actions, then pauses for the operator-only audit-log console step.
- A run rolls back: remove only bindings and the custom role created by the generated grant action, then delete the service account if this run created it; enabled APIs remain because disabling them may affect other consumers.
