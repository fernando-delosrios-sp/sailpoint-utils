Falcon RTR Secrets Scanner | SailPoint Entro DocsFor the complete documentation index, see [llms.txt](https://docs.entro.security/llms.txt). This page is also available as [Markdown](https://docs.entro.security/integrations/security-and-identity/crowdstrike/falcon-rtr-secrets-scanner.md).

The Entro Falcon RTR Secrets Scanner discovers exposed credentials stored in configuration files across all endpoints managed by CrowdStrike Falcon. It uses Falcon Real-Time Response (RTR) to run a read-only scan directly on each host and submits file contents to the Entro Security API for secret detection.
GitBook Assistant
### How it works[#how-it-works](#how-it-works)

The scanner connects to your Falcon tenant, discovers target hosts, and opens parallel RTR sessions. On each host, a built-in shell script (`find` + `curl` on Unix/macOS, PowerShell on Windows) locates config files and posts them directly to the Entro API from the host.
GitBook AssistantGitBook AssistantAskCopy
```
Customer Environment
│
├── Scanner (EC2 or local machine)
│    └── Opens RTR sessions via Falcon API
│
├── CrowdStrike Falcon Cloud
│    └── Executes commands through Falcon Agent
│
└── Endpoint (macOS / Linux / Windows)
     └── find / PowerShell → curl → Entro API
```

No persistent scripts, agents, or binaries are installed on endpoints. All RTR commands originate from the scanner machine. No direct inbound connectivity to endpoints is required.
GitBook Assistant
### Prerequisites[#prerequisites](#prerequisites)

- 

CrowdStrike Falcon with RTR enabled
GitBook Assistant
- 

Falcon API client with **Hosts: Read,** **Real Time Response: Read**** **scopes. Create in Falcon: **Support → API Clients and Keys**.
GitBook Assistant

- 

Available in [https://falcon.<region>.crowdstrike.com/api-clients-and-keys/](https://falcon.crowdstrike.com/api-clients-and-keys/)
GitBook Assistant

- 

Entro Security Scan only API key
GitBook Assistant

- 

Available in [https://app.entro.security/admin/settings?tab=api-keys](https://app.entro.security/admin/settings?tab=api-keys)
GitBook Assistant

- 

Python 3.9+
GitBook Assistant
- 

For the Terraform based deployment:
GitBook Assistant

- 

AWS account, Terraform ≥ 1.5, and AWS CLI configured *(EC2 deployment)*
GitBook Assistant

Current Terraform deployment is AWS based. For any other cloud environmernt please reach out to Entro.
GitBook Assistant
### Setup[#setup](#setup)

#### Download[#download](#download)
[entro-falcon-rtr-secrets-scanner.zip](https://2094737390-files.gitbook.io/~/files/v0/b/gitbook-x-prod.appspot.com/o/spaces%2FdLpzpLCXBV04nzCnCsDJ%2Fuploads%2FYJDu2v5A2YcI5LfkAuE1%2Fentro-falcon-rtr-secrets-scanner.zip?alt=media&token=8e5004db-7483-4580-9185-bd5c54781b21)archive · 25KBDownload[Open](https://2094737390-files.gitbook.io/~/files/v0/b/gitbook-x-prod.appspot.com/o/spaces%2FdLpzpLCXBV04nzCnCsDJ%2Fuploads%2FYJDu2v5A2YcI5LfkAuE1%2Fentro-falcon-rtr-secrets-scanner.zip?alt=media&token=8e5004db-7483-4580-9185-bd5c54781b21)
#### Local run[#local-run](#local-run)
Example .env file[#example-.env-file](#example-.env-file)

Run the scanner:
GitBook Assistant
#### AWS deployment (Terraform → EC2)[#aws-deployment-terraform-ec2](#aws-deployment-terraform-ec2)

> 

**Note:** The provided Terraform configuration targets **AWS** only. If you are deploying on a different cloud platform or on-premises environment, please reach out to Entro for assistance.
GitBook Assistant

The scanner runs as a **systemd oneshot service** on EC2, triggered on a schedule by a **systemd timer**. Credentials are read from **AWS Secrets Manager** at runtime via IAM — no credentials are stored in AMIs or on disk.
GitBook Assistant

**Step 1 — Create the Falcon credentials secret in Secrets Manager**
GitBook Assistant

Create a secret in your AWS account with the following JSON and note its ARN:
GitBook AssistantCrowdStrike regionBase URL

US-1
GitBook Assistant

`https://api.crowdstrike.com`
GitBook Assistant

US-2
GitBook Assistant

`https://api.us-2.crowdstrike.com`
GitBook Assistant

EU-1
GitBook Assistant

`https://api.eu-1.crowdstrike.com`
GitBook Assistant

US-GOV-1
GitBook Assistant

`https://api.laggar.gcw.crowdstrike.com`
GitBook Assistant

**Step 2 — Configure Terraform**
GitBook Assistant

Minimum required fields:
GitBook Assistant

You might need to specify your entro_api_url if instructed to do so
GitBook Assistant

**Step 3 — Deploy**
GitBook Assistant

After `apply`, cloud-init writes `/home/ec2-user/scanner/.env` on the instance and enables the systemd timer. `terraform output` shows the SSH address, CloudWatch log group, and a ready-to-run scan command.
GitBook Assistant

**Step 4 — Verify**
GitBook Assistant

**Updating the script**
GitBook Assistant

Edit `entro_rtr_scanner.py` locally, then run `terraform apply`. This re-copies the file to the instance and refreshes the systemd units.
GitBook Assistant
### Configuration reference[#configuration-reference](#configuration-reference)

All settings are environment variables (`.env` file, or Terraform `terraform.tfvars` which bakes them into the instance `.env` via cloud-init).
GitBook Assistant
#### Credentials[#credentials](#credentials)
VariableRequiredDescription

`CROWDSTRIKE_CLIENT_ID`
GitBook Assistant

Yes
GitBook Assistant

Falcon API client ID
GitBook Assistant

`CROWDSTRIKE_CLIENT_SECRET`
GitBook Assistant

Yes
GitBook Assistant

Falcon API client secret
GitBook Assistant

`CROWDSTRIKE_BASE_URL`
GitBook Assistant

No
GitBook Assistant

Falcon API base URL (default: `https://api.us-2.crowdstrike.com`)
GitBook Assistant

`ENTRO_API_KEY`
GitBook Assistant

Yes
GitBook Assistant

Entro Security API key
GitBook Assistant

`ENTRO_API_URL`
GitBook Assistant

No
GitBook Assistant

Entro scan endpoint (default: `https://api.entro.security/v2/scan`)
GitBook Assistant

`AWS_CS_SECRET_ARN`
GitBook Assistant

No
GitBook Assistant

Secrets Manager ARN for Falcon credentials — overrides the env vars above
GitBook Assistant

`AWS_ENTRO_SECRET_ARN`
GitBook Assistant

No
GitBook Assistant

Secrets Manager ARN for Entro credentials — overrides the env vars above
GitBook Assistant
#### Scan targets[#scan-targets](#scan-targets)
VariableDefaultDescription

`SCAN_ALL_HOSTS`
GitBook Assistant

`true`
GitBook Assistant

Scan every host in the Falcon tenant
GitBook Assistant

`TARGET_HOST` / `TARGET_HOSTS`
GitBook Assistant

—
GitBook Assistant

Specific hostname(s) when `SCAN_ALL_HOSTS=false`
GitBook Assistant

`SCAN_OS_TYPES`
GitBook Assistant

*(all)*
GitBook Assistant

Comma-separated OS filter: `mac`, `linux`, `windows`
GitBook Assistant
#### File selection[#file-selection](#file-selection)
VariableDefaultDescription

`SCAN_FILE_TYPES`
GitBook Assistant

`*.json,*.env,*.yaml,*.yml,*.conf,*.config,*.properties,*.toml,*.ini,*.tfvars,...`
GitBook Assistant

Glob patterns to match
GitBook Assistant

`SCAN_PATHS_UNIX`
GitBook Assistant

`/home,/Users`
GitBook Assistant

Directories searched on macOS/Linux
GitBook Assistant

`SCAN_PATHS_WIN`
GitBook Assistant

`C:\Users,C:\inetpub,C:\app,C:\ProgramData`
GitBook Assistant

Directories searched on Windows
GitBook Assistant

`SCAN_MAX_SIZE_KB`
GitBook Assistant

`250`
GitBook Assistant

Skip files larger than this (KB)
GitBook Assistant

`SCAN_MAX_DEPTH`
GitBook Assistant

`3`
GitBook Assistant

Directory traversal depth
GitBook Assistant

`SCAN_EXCLUDE_UNIX`
GitBook Assistant

`*/node_modules/*,*/.npm/*,*/.cache/*,...`
GitBook Assistant

Paths excluded on macOS/Linux
GitBook Assistant

`SCAN_EXCLUDE_WIN`
GitBook Assistant

`*\node_modules\*,*\AppData\Local\*,...`
GitBook Assistant

Paths excluded on Windows
GitBook Assistant
#### Performance[#performance](#performance)
VariableDefaultDescription

`MAX_WORKERS`
GitBook Assistant

`20`
GitBook Assistant

Concurrent host scans
GitBook Assistant

`SCAN_PARALLEL`
GitBook Assistant

`10`
GitBook Assistant

Concurrent curl calls per host
GitBook Assistant

`MAX_WAIT_TIME`
GitBook Assistant

`1800`
GitBook Assistant

Per-host scan budget in seconds
GitBook Assistant

`POLL_INTERVAL`
GitBook Assistant

`5`
GitBook Assistant

RTR command-status check interval (seconds)
GitBook Assistant
#### Scheduled scans (EC2 only)[#scheduled-scans-ec2-only](#scheduled-scans-ec2-only)
Terraform variableDefaultDescription

`scanner_timer_enabled`
GitBook Assistant

`true`
GitBook Assistant

Install and enable the systemd timer
GitBook Assistant

`scanner_on_calendar`
GitBook Assistant

`*-*-* 02:00:00`
GitBook Assistant

systemd OnCalendar value (UTC) — see `systemd.time(7)`
GitBook Assistant

`scanner_randomized_delay_sec`
GitBook Assistant

`300`
GitBook Assistant

Jitter added to each timer fire (seconds)
GitBook Assistant

`scanner_run_on_deploy`
GitBook Assistant

`true`
GitBook Assistant

Trigger one background scan immediately after `terraform apply`
GitBook Assistant
### Scan output[#scan-output](#scan-output)

Each run produces a timestamped directory next to `entro_rtr_scanner.py`:
GitBook Assistant

Each per-host file contains host metadata (hostname, IP, OS), the list of findings returned by Entro (secret type, file path, owner, timestamps), and scan statistics (files found, files scanned, duration).
GitBook Assistant
### AWS resources created by Terraform[#aws-resources-created-by-terraform](#aws-resources-created-by-terraform)
ResourcePurpose

EC2 instance (`t3.micro`)
GitBook Assistant

Runs the scanner
GitBook Assistant

IAM role + instance profile
GitBook Assistant

Grants Secrets Manager and CloudWatch access
GitBook Assistant

Security group
GitBook Assistant

SSH from `allowed_ssh_cidr` only; all outbound allowed
GitBook Assistant

Secrets Manager secret
GitBook Assistant

Stores Entro API credentials (when `create_entro_secret = true`)
GitBook Assistant

CloudWatch log group
GitBook Assistant

Receives scanner logs; retention set by `log_retention_days` (default 30 days)
GitBook Assistant
### Troubleshooting[#troubleshooting](#troubleshooting)
ErrorCauseResolution

`CROWDSTRIKE_CLIENT_ID not set`
GitBook Assistant

Missing `.env` or Secrets Manager ARN
GitBook Assistant

Confirm `.env` exists next to the script, or set `AWS_CS_SECRET_ARN`
GitBook Assistant

`ENTRO_API_KEY not set`
GitBook Assistant

Missing Entro key
GitBook Assistant

Set `ENTRO_API_KEY` in `.env` or `AWS_ENTRO_SECRET_ARN`
GitBook Assistant

`401 Unauthorized` (Falcon)
GitBook Assistant

Invalid or expired credentials
GitBook Assistant

Regenerate Client ID and Secret in Falcon → Support → API Clients and Keys
GitBook Assistant

`403 Forbidden` (Falcon)
GitBook Assistant

Insufficient API scopes
GitBook Assistant

Confirm **Hosts: Read** and **Real Time Response (Admin): Write** are granted
GitBook Assistant

RTR session timeout
GitBook Assistant

Host offline or Falcon agent not running
GitBook Assistant

Verify the Falcon agent is active on the target endpoint
GitBook Assistant

No findings returned
GitBook Assistant

Scan paths or file types too restrictive
GitBook Assistant

Broaden `SCAN_PATHS_UNIX` / `SCAN_FILE_TYPES` and re-run
GitBook Assistant

Logs are written to `logs/scan_YYYYMMDD_HHMMSS.log` next to the script, and to CloudWatch when running on EC2.
GitBook Assistant
### Security notes[#security-notes](#security-notes)

- 

Use AWS Secrets Manager for production deployments. Never commit `.env` or `terraform.tfvars` containing real credentials.
GitBook Assistant
- 

Scope the Falcon API client to the minimum required permissions.
GitBook Assistant
- 

Restrict `allowed_ssh_cidr` to a specific IP or VPN egress — avoid `0.0.0.0/0`.
GitBook Assistant
- 

All RTR sessions are logged in the CrowdStrike console and are fully auditable.
GitBook Assistant
- 

Rotate Falcon client secrets and the Entro API key on your standard rotation cadence.
GitBook Assistant
[PreviousCrowdStrike Permissions Reference](/integrations/security-and-identity/crowdstrike/crowdstrike-permissions-reference)[NextAI Security RTR Integration](/integrations/security-and-identity/crowdstrike/ai-security-rtr-integration)

Last updated 2 months ago

- [How it works](#how-it-works)
- [Prerequisites](#prerequisites)
- [Setup](#setup)
- [Configuration reference](#configuration-reference)
- [Scan output](#scan-output)
- [AWS resources created by Terraform](#aws-resources-created-by-terraform)
- [Troubleshooting](#troubleshooting)
- [Security notes](#security-notes)
GitBook AssistantAskCopy
```
python3 -m venv venv
source venv/bin/activate      # Windows: venv\Scripts\activate
pip install -r requirements.txt

cp .env.example .env
# Fill in Falcon and Entro credentials — see Configuration below
```
GitBook AssistantAskCopy
```
# =============================================================================
# entro_rtr_scanner.py — environment file (.env)
# =============================================================================
#
# WHEN YOU NEED THIS FILE
# -----------------------
# • Terraform + EC2 (default deploy): you do NOT copy this to your laptop for production.
#   Terraform / cloud-init writes /home/ec2-user/scanner/.env on the scanner instance.
# • Local machine, CI, or any host where YOU run: python3 entro_rtr_scanner.py
#   → copy this file to `.env` in the same directory as entro_rtr_scanner.py
#
# HOW CREDENTIALS ARE RESOLVED (in order)
# ----------------------------------------
# 1) If AWS_CS_SECRET_ARN / AWS_ENTRO_SECRET_ARN are set, boto3 loads Secrets Manager
#    (needs AWS credentials on that machine + IAM permission to read those secrets).
# 2) Else CROWDSTRIKE_* and ENTRO_* variables below are used.
#
# =============================================================================

# ── CrowdStrike Falcon API (your tenant) ─────────────────────────────────────
# CROWDSTRIKE_CLIENT_ID     — OAuth2 client ID from Falcon → Support → API clients and keys
# CROWDSTRIKE_CLIENT_SECRET — OAuth2 secret for that client (rotate like a password)
# CROWDSTRIKE_BASE_URL      — REST base URL for your Falcon cloud (must match region)

CROWDSTRIKE_CLIENT_ID=your-client-id-here
CROWDSTRIKE_CLIENT_SECRET=your-client-secret-here
CROWDSTRIKE_BASE_URL=https://api.us-2.crowdstrike.com

# Other regions (examples):
# US-1:   https://api.crowdstrike.com
# EU-1:   https://api.eu-1.crowdstrike.com
# US-GOV: https://api.laggar.gcw.crowdstrike.com

# ── Which Falcon-managed hosts to scan ───────────────────────────────────────
# SCAN_ALL_HOSTS=true  — query every host visible to this API client (mac + linux + windows)
# SCAN_ALL_HOSTS=false — use a single host or list instead (set one of the following)

SCAN_ALL_HOSTS=true
# TARGET_HOST=one-hostname-only
# TARGET_HOSTS=host1,host2,host3

# ── Entro Security API (your Entro tenant) ───────────────────────────────────
# ENTRO_API_KEY — API key from Entro (treat as secret)
# ENTRO_API_URL — Scan API base (include /v2/scan pathL)

ENTRO_API_KEY=your-entro-api-key-here
ENTRO_API_URL=https://api.entro.security/v2/scan

# ── What to scan on each remote host (RTR-side behavior) ─────────────────────
# SCAN_FILE_TYPES   — comma-separated globs for filenames to consider
# SCAN_PATHS_UNIX   — comma-separated roots on macOS/Linux endpoints
# SCAN_PATHS_WIN    — comma-separated roots on Windows endpoints
# SCAN_MAX_SIZE_KB  — skip larger files (approximate cap per file)
# SCAN_MAX_DEPTH    — max directory depth under each root
# SCAN_OS_TYPES     — optional filter: mac,linux,windows (comma-separated); empty = all

SCAN_FILE_TYPES=*.crt,*.key,*.pem,*.json,*.env,*.env.*,*.yaml,*.yml
SCAN_PATHS_UNIX=/home,/Users
SCAN_PATHS_WIN=C:\Users,C:\ProgramData,C:\inetpub
SCAN_MAX_SIZE_KB=250
SCAN_MAX_DEPTH=3
# SCAN_OS_TYPES=mac,linux

# ── Concurrency ──────────────────────────────────────────────────────────────
# MAX_WORKERS — max parallel host scans in entro_rtr_scanner.py (thread pool)

# MAX_WORKERS=20

# ── AWS Secrets Manager (optional; typical on EC2 when .env only has ARNs) ─────
# AWS_REGION          — region for Secrets Manager API
# AWS_CS_SECRET_ARN   — secret JSON: clientId, clientSecret, baseUrl
# AWS_ENTRO_SECRET_ARN — secret JSON: entroApiKey, entroApiUrl

# AWS_REGION=us-east-1
# AWS_CS_SECRET_ARN=arn:aws:secretsmanager:us-east-1:123456789012:secret:your-falcon-api-secret
# AWS_ENTRO_SECRET_ARN=arn:aws:secretsmanager:us-east-1:123456789012:secret:your-entro-secret

```
GitBook AssistantAskCopy
```
python3 entro_rtr_scanner.py --all                                   # every host in tenant
python3 entro_rtr_scanner.py host1 host2                             # specific hosts
python3 entro_rtr_scanner.py --all --filter "platform_name:'Linux'"  # OS-filtered
```
GitBook AssistantAskCopy
```
{
  "clientId": "your-falcon-client-id",
  "clientSecret": "your-falcon-client-secret",
  "baseUrl": "https://api.us-2.crowdstrike.com"
}
```
GitBook AssistantAskCopy
```
cd terraform
cp terraform.tfvars.example terraform.tfvars
```
GitBook AssistantAskCopy
```
crowdstrike_secret_arn = "arn:aws:secretsmanager:us-east-1:123456789012:secret:..."
entro_api_key          = "your-entro-api-key"
entro_api_url          = "entro.api.domain/v2/scan"
ssh_key_name           = "my-keypair"
ssh_private_key_path   = "~/.ssh/my-keypair.pem"
allowed_ssh_cidr       = "203.0.113.42/32"
```
GitBook AssistantAskCopy
```
terraform init
terraform plan
terraform apply
```
GitBook AssistantAskCopy
```
ssh -i ~/.ssh/my-keypair.pem ec2-user@<instance-ip>

systemctl status entro-rtr-scanner.timer
journalctl -fu entro-rtr-scanner.service

# Trigger an immediate scan (non-blocking)
systemctl start --no-block entro-rtr-scanner.service
```
GitBook AssistantAskCopy
```
scan_YYYYMMDD_HHMMSS/
├── <hostname>.json     # per-host findings and scan metadata
└── _report.json        # aggregate report across all hosts
```
