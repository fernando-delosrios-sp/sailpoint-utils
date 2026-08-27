# Private-data scan

Scan **staged diff only** (`git diff --cached`). Never quote secret or PII **values** in findings, gate text, or chat — report `path:line`, signal type, and a one-line context hint only.

## Finding format

| File | Line(s) | Signal type | Context hint |
| ---- | ------- | ----------- | ------------ |
| `config.ts` | 12 | AWS access key | Variable assignment in config block |
| `notes.md` | 8 | Email (PII) | Contact section |
| `script.sh` | 3 | Home-directory path | Absolute path to user home |

Group multiple signals on the same file; never paste the matched value.

## Path / filename signals

Flag staged paths whose basename or extension matches:

| Pattern | Signal type |
| ------- | ----------- |
| `.env`, `.env.*` (except allowlisted below) | Environment secrets file |
| `*.pem`, `*.p12`, `*.pfx`, `*.key` | Private key / certificate |
| `id_rsa`, `id_rsa.*`, `id_ed25519`, `id_ecdsa` | SSH private key |
| `credentials.json`, `credentials*.json`, `secrets.json`, `secrets*.yaml`, `secrets*.yml` | Credentials store |
| `.npmrc`, `.pypirc`, `.netrc`, `.docker/config.json` | Package/registry auth file |
| `*.keystore`, `*.jks` | Java keystore |
| `serviceAccount*.json`, `*-credentials.json` | Cloud service account key |

Also flag paths under: `.ssh/`, `.aws/credentials`, `.gnupg/`.

## Content signals — secrets

Inspect added/changed lines in the staged diff:

| Pattern category | Examples (do not quote values) |
| ---------------- | ------------------------------ |
| AWS access key | `AKIA` + 16 alphanumeric chars |
| GitHub token | `ghp_`, `gho_`, `ghu_`, `ghs_`, `ghr_` prefixes |
| OpenAI / Stripe / generic API keys | `sk-`, `sk_live_`, `sk_test_`, `rk_live_` |
| JWT | Three base64 segments separated by `.` (header.payload.signature) |
| PEM block | `-----BEGIN` … `PRIVATE KEY` / `RSA PRIVATE KEY` / `CERTIFICATE-----` |
| Bearer token | `Bearer ` followed by 20+ chars |
| Connection string password | `password=`, `pwd=`, `pass=` with non-placeholder value on same line |
| JDBC / URI credentials | `://user:password@` in connection URL |
| Generic assignment | `api_key`, `apiKey`, `secret`, `token`, `password`, `private_key` assigned to non-placeholder literal |

## Content signals — PII

| Pattern category | Heuristic |
| ---------------- | --------- |
| Email | `[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}` — skip obvious placeholders (`example.com`, `test@`, `user@example`) |
| Phone | US/international formats with 10+ digits; skip `555-0100`, `000-000-0000` |
| Government ID | SSN pattern `\d{3}-\d{2}-\d{4}`; national ID formats with separators |
| Credit card | 13–19 digit groups with optional separators (Luhn not required — flag for review) |
| Full name + DOB combo | Person name near date-of-birth field in same hunk |

PII hits are **medium confidence** — still gate, but note confidence in context hint.

## Content signals — sensitive paths

| Pattern category | Heuristic |
| ---------------- | --------- |
| macOS / Linux home | `/Users/<name>/`, `/home/<name>/`, `~/` |
| Windows home | `C:\Users\<name>\`, `%USERPROFILE%` with username |
| SSH / key paths | `~/.ssh/`, `.ssh/id_`, references to private key files |
| Cloud config paths | `~/.aws/`, `~/.config/gcloud/` with credential filenames |

Skip paths that are clearly documentation examples (see false positives).

## False positives

Do **not** skip the gate automatically — note reduced confidence in the context hint. User decides via structured-choices.

| Case | Guidance |
| ---- | -------- |
| `.env.example`, `.env.template`, `.env.sample` | Placeholder values only (`your-api-key-here`, `changeme`, `xxx`) — lower confidence |
| Test fixtures | Files under `__tests__/`, `fixtures/`, `testdata/` with fake/synthetic data |
| Redacted content | `<REDACTED>`, `***`, `xxx`, `[REDACTED]`, obvious placeholders |
| Docs / README | Illustrative paths (`/Users/you/...`, `your-email@example.com`) — note "documented example" |
| Public keys only | `-----BEGIN PUBLIC KEY-----` without matching private key material |

When **only** low-confidence PII or doc-example hits exist, mark `(Recommended)` on `proceed` instead of `unstage_conflicts` — user still confirms.

## Optional CLI

If available on PATH, run against staged files and merge into the same finding list (still redacted):

```bash
# gitleaks — scan staged content
gitleaks detect --source . --log-opts="--staged" --redact --no-banner 2>/dev/null

# detect-secrets — audit staged files
git diff --cached --name-only -z | xargs -0 detect-secrets scan 2>/dev/null
```

CLI hits override heuristic confidence. Absence of CLI does not skip the agent scan.

## Gate options

Present via **structured-choices** when any finding exists:

| Option id | Label | Effect |
| --------- | ----- | ------ |
| `unstage_conflicts` | Unstage flagged paths and fix (Recommended) | `git restore --staged <paths>`; return to staging or stop if nothing left |
| `proceed` | Proceed anyway — I accept the risk | Continue to changelog + commit |
| `abort` | Abort — do not commit | Exit without committing |

One gate per message. List every flagged file and signal type before the tool call.
