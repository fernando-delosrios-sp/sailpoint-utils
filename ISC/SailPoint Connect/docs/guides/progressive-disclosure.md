# Progressive Disclosure in SailPoint Connect

SailPoint Connect follows a **progressive-disclosure** design philosophy: it reveals complexity only as you need it, avoiding overwhelming the operator with dozens of flags at once. It also does not change a tenant until you choose `Run` and confirm. The longer explanation is [What SailPoint Connect changes](what-it-changes.md).

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
Adding `-Wizard` enters step-by-step interactive mode. The first question is what the session should produce: a checklist, a read-only check, a script, or an apply. Every later question is in service of that choice.
- Shows the current CLI session, if there is one, and asks how you want to supply values.
- You can type every value. Signing in is optional. A signed-in CLI can offer names that already exist (IAM roles, CloudTrail buckets, projects). That list is a convenience. It does not create those objects.
- Prompts for required fields with sensible defaults.
- On combined platforms (AWS, Azure, GCP), asks whether to attach Entro cloud security onboarding.

### Layer 3: Action Execution (`-Action`)
Every target supports four actions. The interactive default is `BuildRequirements`.

1. `BuildRequirements`: Renders a Markdown checklist of the identity and permissions needed, so you can hand it to the team that owns the tenant. Nothing is created.
2. `Check`: Reads an identity that already exists (an IAM role, an Entra app registration, or a Google service account) and writes a gap report. Nothing is created. Where the grant cannot be read from the CLI, the report says what a person should open.
3. `BuildScript`: Renders a standalone PowerShell script saved under your project directory. Review it, then run it under your change process.
4. `Run`: The only action that creates or updates anything, and only after the plan summary and a yes/no. `-WhatIf` prints the steps and does not write.

### Headless Automation (`-NonInteractive`)
Pass all required flags plus `-NonInteractive` for CI/CD pipelines and automated deployments. `-Action` is required. `Check` exits with an error when the existing identity does not meet the requirements, and still does not change it.
