# Progressive Disclosure in SailPoint Connect

SailPoint Connect follows a **progressive-disclosure** design philosophy: it reveals complexity only as you need it, avoiding overwhelming the operator with dozens of flags at once.

---

## The Three Layers

### Layer 1: Exploration & Core Choices
Running a platform command with no arguments prints the platform's core capabilities and the next immediate command to run:

```powershell
Connect-SailPointAWS
```
Output:
```
AWS integration wizard
  Connect-SailPointAWS -Wizard              Guided setup, asks every question
  Connect-SailPointAWS -Wizard -SaaSConnector Guided setup, SaaS connector already chosen
  Connect-SailPointAWS -SaaSConnector       Amazon Web Services SaaS connector
  Connect-SailPointAWS -CiemConnector       AWS CIEM connector (CloudFormation)
  Connect-SailPointAWS -Entro               Entro AWS integration
```

### Layer 2: Guided Interactive Questionnaire (`-Wizard`)
Adding `-Wizard` enters step-by-step interactive mode:
- Probes your existing CLI session (e.g. `aws sts get-caller-identity`, `az account show`, `gcloud auth list`).
- Auto-discovers existing resources (IAM roles, CloudTrail buckets, projects).
- Prompts for required fields with sensible defaults.
- On combined platforms (AWS, Azure, GCP), asks whether to attach Entro cloud security onboarding.

### Layer 3: Action Execution (`-Action`)
Every target supports three actions:
1. `Run`: Executes the setup immediately using your authenticated CLI session.
2. `BuildScript`: Renders a standalone, reproducible PowerShell automation script saved under your project directory.
3. `BuildRequirements`: Renders a Markdown checklist detailing the exact IAM roles, API scopes, and permissions needed so you can hand it off to customer cloud admins prior to onboarding.

### Headless Automation (`-NonInteractive`)
Pass all required flags plus `-NonInteractive` for CI/CD pipelines and automated deployments.
