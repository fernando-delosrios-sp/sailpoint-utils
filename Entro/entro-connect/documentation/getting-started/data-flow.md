Data Flow | SailPoint Entro DocsFor the complete documentation index, see [llms.txt](https://docs.entro.security/llms.txt). This page is also available as [Markdown](https://docs.entro.security/getting-started/data-flow.md).
#### **Overview**[#overview](#overview)

Entro’s data flow defines how information moves securely from integrated environments into the platform. Every stage ensures minimal exposure, verifiable integrity, and compliance with enterprise-grade security controls.
GitBook Assistant
#### **1. Data Ingestion**[#id-1.-data-ingestion](#id-1.-data-ingestion)

- 

**Sources:** Git repositories, CI/CD systems, cloud providers, secret managers, ticketing systems.
GitBook Assistant
- 

**Collectors:** Each source is connected via a dedicated collector container using read-only credentials.
GitBook Assistant
- 

**Transport:** Data is transmitted over HTTPS with mutual TLS.
GitBook Assistant
- 

**Scope:** Only metadata and potential secret fingerprints are collected-no source code is permanently stored.
GitBook Assistant

#### **2. Data Processing**[#id-2.-data-processing](#id-2.-data-processing)

- 

**Parsing:** Raw data is parsed using context-aware regex and NLP models to extract secrets, tokens, or credentials.
GitBook Assistant
- 

**Normalization:** Each finding is normalized into a common schema with metadata such as source, timestamp, and repository.
GitBook Assistant
- 

**Deduplication:** Identical findings across integrations are merged to avoid false positives.
GitBook Assistant

#### **3. Classification and Enrichment**[#id-3.-classification-and-enrichment](#id-3.-classification-and-enrichment)

- 

**AI Models:** Classify data as valid secrets, configuration noise, or low-confidence tokens.
GitBook Assistant
- 

**Enrichment:** Valid secrets are enriched with additional context (IAM roles, commit authors, environment).
GitBook Assistant
- 

**Ownership Mapping:** The system links secrets to users, services, or non-human identities (NHIs).
GitBook Assistant

#### **4. Risk Scoring**[#id-4.-risk-scoring](#id-4.-risk-scoring)

- 

Each secret is assigned a **risk score** based on:
GitBook Assistant

- 

Exposure vector (public, internal, private)
GitBook Assistant
- 

Privilege level (admin, read-only, service account)
GitBook Assistant
- 

Rotation status and last usage
GitBook Assistant
- 

Source sensitivity (prod vs. dev environment)
GitBook Assistant

#### **5. Storage**[#id-5.-storage](#id-5.-storage)

- 

Processed and scored data is stored in **encrypted PostgreSQL** or **AWS RDS**.
GitBook Assistant
- 

No plaintext secrets are stored-only hashed fingerprints and metadata.
GitBook Assistant
- 

Access to the database is restricted through IAM policies and network segmentation.
GitBook Assistant

#### **6. Visualization and Access**[#id-6.-visualization-and-access](#id-6.-visualization-and-access)

- 

Users interact with findings via the **Entro Web Console** or REST/GraphQL APIs.
GitBook Assistant
- 

Dashboards show:
GitBook Assistant

- 

Secret exposure timelines
GitBook Assistant
- 

Correlation graphs between assets and credentials
GitBook Assistant
- 

Compliance and remediation reports
GitBook Assistant

[PreviousArchitecture](/getting-started/architecture)[NextSmart API Rate Limiting and Backoff Behavior](/getting-started/smart-api-rate-limiting-and-backoff-behavior)
