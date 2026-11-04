# Architecture and Workspaces

SailPoint Connect organizes all integration artifacts, secrets (masked), logs, and runbooks under the user's home folder:

```
~/.sailpoint-connect/
```

This ensures that running scripts from different directories or projects never pollutes working trees or repositories.

---

## Directory Layout

```
~/.sailpoint-connect/
├── current.json                       # Points to the currently active project
└── <ProjectName>/
    ├── selection.json                 # Last chosen target & parameters (compressed JSON)
    ├── selections.jsonl               # Historical audit trail of all runs
    ├── operator-actions.md            # Manual tasks requiring human action
    └── <Platform>/
        └── <IntegrationFolder>/
            ├── activity.log           # Timestamped log lines with secret masking
            ├── <script>.ps1           # Generated standalone script (-Action BuildScript)
            ├── <script>-requirements.md # Requirements checklist (-Action BuildRequirements)
            └── entro-gcp-report.md    # GCP Entro run summary (when applicable)
```

---

## Workspace Management

- **Switching Projects**: Use `Set-SailPointConnectProject -Name "<name>"` or pass `-Project "<name>"` on any command.
- **Listing Projects**: Use `Get-SailPointConnectProject` to view all workspaces on disk.
- **Environment Override**: For isolated automated testing or alternate storage locations, set `$env:SAILPOINT_CONNECT_ROOT = '/custom/path'`.

---

## Security & Secret Masking

- Sensitive parameters (such as `ClientSecret`, `PrivateKey`, passwords) are flagged as secrets.
- In `selection.json` and `selections.jsonl`, secrets are replaced with `'***'`.
- Plain-text secrets are only output to the operator console or local file when explicitly necessary for configuration handover.
