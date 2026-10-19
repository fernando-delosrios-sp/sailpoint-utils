# Access Model Change Management

This repository governs ISC entitlements (metadata), access profiles and roles for one tenant through pull requests.

After install, the first successful backup and ledger write regenerates this file. Until then, see the installer documentation in sailpoint-utils under `ISC/Access Model Change Management/README.md`.

## Quick start for contributors

1. Branch from `main`
2. Edit JSON under `access/`
3. Open a PR — CI validates; the governance group approves
4. On approval the PR auto-merges and Actions push the change to ISC

Restore the whole access model with **Actions → Restore**: pick the branch or tag to restore from and run it — there are no inputs. Approval goes to the governance group only.

**Actions → Init** wipes git history, issues, tags, and the rest of the repository record, then commits a fresh ISC backup as the new baseline. It does not change ISC. Type `RESET` to confirm. Deleting previous workflow runs needs the GitHub App repository permission **Actions: Read and write**.
