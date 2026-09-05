AI LLM Usage Policy | SailPoint Entro DocsFor the complete documentation index, see [llms.txt](https://docs.entro.security/llms.txt). This page is also available as [Markdown](https://docs.entro.security/legal-and-privacy/ai-llm-usage-policy.md).

*Last Updated: October 2025*
GitBook Assistant
## Overview[#overview](#overview)

This document explains how Entro Security uses Artificial Intelligence (AI) and Large Language Model (LLM) technologies within its platform. It outlines the purpose, scope, data handling, and governance practices associated with AI-based features, including user controls and compliance with global privacy and transparency standards. This policy supplements the Privacy Policy and Data Retention Policy.
GitBook Assistant
## Scope[#scope](#scope)

Entro Security’s AI functionality currently consists of two opt-in modules:
GitBook Assistant
### AI Classification[#ai-classification](#ai-classification)

#### Purpose[#purpose](#purpose)

Enriches and structures metadata surrounding detected secrets to assist with triage and prioritization. This feature may label findings as True Positive (TP) or False Positive (FP) and provide reasoning.
GitBook Assistant
#### Data Processed[#data-processed](#data-processed)

Only contextual metadata such as filenames, environment variables, repository information, and adjacent lines. Secret values are never processed. Data remains entirely within Entro’s infrastructure.
GitBook Assistant
#### Human Oversight[#human-oversight](#human-oversight)

All AI Classification results are reviewed by Entro analysts or customer personnel before influencing risk scoring or workflows unless the customer explicitly enables automation.
GitBook Assistant
#### Automated Actions and Opt-In Behavior[#automated-actions-and-opt-in-behavior](#automated-actions-and-opt-in-behavior)

When a user enables AI Classification:
GitBook Assistant

- 

True Positive classifications automatically raise generic secrets or keys to the exposed-inventory view.
GitBook Assistant
- 

False Positive classifications are discarded along with related risk records.
GitBook Assistant
- 

All other functions remain advisory unless the customer configures automated triage.
GitBook Assistant

### AI-Powered Mitigation[#ai-powered-mitigation](#ai-powered-mitigation)

#### Purpose[#purpose-1](#purpose-1)

Generates advisory text describing recommended remediation or mitigation steps for risk findings. These outputs are intended to help analysts resolve exposures more quickly and consistently.
GitBook Assistant
#### Data Processed[#data-processed-1](#data-processed-1)

Only anonymized risk metadata such as owner, location, environment, secret type, and related contextual details. No raw secrets are processed. Processing is stateless; the model output is generated and returned without storing input data.
GitBook Assistant
#### Human Oversight[#human-oversight-1](#human-oversight-1)

Mitigation steps are generated for review by a human analyst before any action is taken. A user may attach the proposed mitigation text to a ticket or workflow only after manual approval.
GitBook Assistant
## Model Architecture[#model-architecture](#model-architecture)

## Data Handling and Retention[#data-handling-and-retention](#data-handling-and-retention)

All data retained indefinitely is stored in a form that cannot be used to identify customers or secrets.
GitBook Assistant
## Security Controls[#security-controls](#security-controls)

- 

All data and logs are encrypted at rest and in transit.
GitBook Assistant
- 

Access is restricted to authorized engineering roles following least-privilege principles.
GitBook Assistant
- 

The AI stack is subject to the same formal change-control processes as other production systems.
GitBook Assistant
- 

No external analytics or model vendors have access to Entro AI data.
GitBook Assistant

## Regional and Cross-Border Processing[#regional-and-cross-border-processing](#regional-and-cross-border-processing)

Entro operates a global infrastructure. By default, AI processing may occur in any Entro AWS region. Upon request, Entro can establish regional data boundaries (for example, EU-only processing) to satisfy contractual or regulatory requirements. All cross-border data processing complies with applicable safeguards under GDPR Articles 44–49 and equivalent frameworks.
GitBook Assistant
## Human Oversight and Governance[#human-oversight-and-governance](#human-oversight-and-governance)

**Responsible Role: Chief Technology Officer (CTO)** The CTO ensures periodic reviews of model accuracy, fairness, and compliance. AI outputs are subject to quality-assurance checks and internal audit. AI functionality is incorporated into Entro’s ISO-aligned security governance program.
GitBook Assistant
## Transparency and Explainability[#transparency-and-explainability](#transparency-and-explainability)

Each AI Classification record contains a reasoning field explaining why the model determined a True Positive or False Positive. This supports explainability requirements under the EU AI Act Articles 13 and 50 and similar international standards.
GitBook Assistant
## User Rights and Controls[#user-rights-and-controls](#user-rights-and-controls)

Both AI modules are opt-in. Users may opt out or request deletion of AI-derived data by contacting privacy@entro.security. Opt-out requests will disable future AI processing for that account; existing anonymized data will remain for audit integrity.
GitBook Assistant
## Updates to This Policy[#updates-to-this-policy](#updates-to-this-policy)

This policy may be updated as AI capabilities or regulatory requirements evolve. All changes are version-controlled and timestamped within Entro documentation. Material updates will be communicated through standard product or privacy-notice channels.
GitBook Assistant
## Contact[#contact](#contact)

Questions regarding this policy or Entro’s AI systems should be directed to: privacy@entro.security 
GitBook Assistant[PreviousData Retention Policy](/legal-and-privacy/data-retention-policy)[NextLicense and Service Level Agreement](/legal-and-privacy/license-and-service-level-agreement)

- [Overview](#overview)
- [Scope](#scope)
- [AI Classification](#ai-classification)
- [AI-Powered Mitigation](#ai-powered-mitigation)
- [Model Architecture](#model-architecture)
- [Data Handling and Retention](#data-handling-and-retention)
- [Security Controls](#security-controls)
- [Regional and Cross-Border Processing](#regional-and-cross-border-processing)
- [Human Oversight and Governance](#human-oversight-and-governance)
- [Transparency and Explainability](#transparency-and-explainability)
- [User Rights and Controls](#user-rights-and-controls)
- [Updates to This Policy](#updates-to-this-policy)
- [Contact](#contact)
