## ADDED Requirements

### Requirement: Every integration documentation page is cited or waived

Every markdown page under the integration documentation folders SHALL be either cited by an
Add New Account row — on the row, one of its Setup methods, one of its Authentication
methods, or one of its Coverages — or named in that catalog's Method waiver registry with a
non-empty reason. Integration documentation folders SHALL mean the same set the Skill-held
attachment requirement fixes: `documentation/cloud-and-infrastructure/`,
`documentation/collaboration-and-saas/`, `documentation/code-and-ci-cd/`,
`documentation/ai-and-agents/`, `documentation/security-and-identity/`,
`documentation/container-registries/`, and `documentation/gemini-instructions/`. A page that
no row cites MUST NOT be attributed to a row by folder or path proximity; it is an orphan
until cited or waived. Validation MUST fail when any such page is neither cited nor waived.

#### Scenario: Uncited integration page fails validation

- **GIVEN** an integration documentation page that documents an onboarding path
- **AND** no row, Setup method, Authentication method, or Coverage cites it
- **AND** no Method waiver names it
- **WHEN** the catalog is validated
- **THEN** validation MUST fail naming that page

#### Scenario: Multi-account automation page is observable

- **GIVEN** `cloud-and-infrastructure/amazon-web-services/aws-onboarding-steps/aws-multiple-account-automation.md`
- **WHEN** the catalog is validated
- **THEN** the AWS row MUST cite that page or waive it with a reason
- **AND** validation MUST fail when it does neither

#### Scenario: Reverted curation fails rather than passes

- **GIVEN** a row that cites a page and carries a Documented method distilled from it
- **WHEN** that row's citation and its Method waiver are both removed
- **THEN** validation MUST fail because the page is orphaned
- **AND** the catalog MUST NOT validate as though the page did not exist

#### Scenario: Non-integration pages need no citation

- **GIVEN** Entro Connector topology, SSO setup, and IDE plugin pages outside the integration documentation folders
- **WHEN** the catalog is validated
- **THEN** those pages MUST NOT require a citation or a Method waiver

---

### Requirement: Cited pages carry a verified fork census

Each cited integration documentation page SHALL carry a fork census listing the Documented
methods that page names. Each census entry SHALL bind to either the name of a Setup method
or Authentication method the catalog carries, or a Method waiver reason, and SHALL carry an
`evidence` quote of the page text that names that Documented method. Validation MUST confirm
each `evidence` quote occurs in the bytes of the page it is recorded against, and MUST fail
when a quote is absent, when an entry binds to a method name the row does not carry, or when
an entry has neither a method binding nor a waiver reason.

#### Scenario: In-page fork is bound to a method

- **GIVEN** a cited page that documents two ways to authenticate the same target
- **WHEN** the catalog is validated
- **THEN** the census MUST carry one entry per documented way
- **AND** each entry MUST name a method the row carries or a Method waiver reason

#### Scenario: Stale evidence quote fails validation

- **GIVEN** a census entry whose `evidence` quote no longer appears in the cited page
- **WHEN** the catalog is validated
- **THEN** validation MUST fail naming the page and the missing quote

#### Scenario: Census entry cannot name an absent method

- **GIVEN** a census entry that binds to a Setup method name
- **AND** the row does not carry a Setup method with that name
- **WHEN** the catalog is validated
- **THEN** validation MUST fail

#### Scenario: Documented AWS deployment options are censused

- **GIVEN** the AWS multi-account automation page naming CloudFormation StackSets and Terraform
- **WHEN** the catalog is validated
- **THEN** each MUST be a Setup method the AWS row carries or a Method waiver with a reason

---

### Requirement: Method waivers are explicit and reasoned

A Method waiver SHALL record the documentation page it applies to and a non-empty reason
stating why that page or Documented method is deliberately not carried as a Setup or
Authentication method. Validation MUST fail when a waiver has a missing, empty, or
whitespace-only reason, and MUST fail when a waiver names a page that does not exist under
the integration documentation folders. A waiver MUST NOT be expressed as a bare flag.

#### Scenario: Waiver without a reason fails validation

- **GIVEN** a Method waiver whose reason is empty or whitespace
- **WHEN** the catalog is validated
- **THEN** validation MUST fail

#### Scenario: Waiver for a missing page fails validation

- **GIVEN** a Method waiver naming a page that is not present under the integration documentation folders
- **WHEN** the catalog is validated
- **THEN** validation MUST fail

#### Scenario: Reasoned waiver validates

- **GIVEN** a documented path the catalog deliberately does not carry as a method
- **AND** a Method waiver naming that page with a reason sentence
- **WHEN** the catalog is validated
- **THEN** validation MUST pass for that page

---

### Requirement: Curation bookkeeping stays out of the Skill catalog

Method waivers and fork census entries SHALL appear only in the ingest Integration index.
The Skill catalog thin index and every Row catalog MUST NOT carry Method waivers, fork
census entries, or documentation page paths, because Connect never opens `documentation/`.
Validation MUST fail when a Row catalog or the thin index carries any of them.

#### Scenario: Row catalog carries no waivers

- **GIVEN** a row whose curation includes Method waivers and a fork census
- **WHEN** the Skill catalog tree is written
- **THEN** the Row catalog MUST NOT contain waivers, census entries, or documentation paths
- **AND** the ingest Integration index MUST contain them

#### Scenario: Waiver leaking into the Skill catalog fails validation

- **GIVEN** a Skill catalog Row catalog that carries a Method waiver
- **WHEN** the Skill catalog is validated
- **THEN** validation MUST fail

---

### Requirement: Catalog completeness is asserted without vendor credentials

The catalog completeness invariant SHALL be enforced by the same validation function the
catalog writer calls and SHALL additionally be asserted by the repository test suite against
the committed documentation tree. The test suite assertion MUST NOT require
`ENTRO_DOCS_COOKIE` or any network access, so that a change which drops a Documented method
fails on the repository's canonical test command.

#### Scenario: Test suite catches a dropped method without a cookie

- **GIVEN** no `ENTRO_DOCS_COOKIE` in the environment
- **AND** a change that removes a row's citation of a documented onboarding page
- **WHEN** the canonical test command runs
- **THEN** a named test MUST fail

#### Scenario: Catalog writer enforces the same invariant

- **GIVEN** a catalog that violates page citation or fork census
- **WHEN** the catalog writer runs
- **THEN** it MUST return validation errors and MUST NOT write the Integration index or the Skill catalog trees
