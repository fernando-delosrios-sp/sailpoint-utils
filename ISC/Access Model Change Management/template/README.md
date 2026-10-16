# Access Model Change Management

This repository governs ISC entitlements (metadata), access profiles and roles for one tenant through pull requests.

After install, the first successful backup and ledger write regenerates this file. Until then, see the installer documentation in sailpoint-utils under `ISC/Access Model Change Management/README.md`.

## Quick start for contributors

1. Branch from `main`
2. Edit JSON under `access/`
3. Open a PR — CI validates; the governance group approves, then each item owner when that is enabled
4. On approval the PR auto-merges and Actions push the change to ISC

Restore from an `isc-applied/*` tag via **Actions → Restore** (governance group only).
