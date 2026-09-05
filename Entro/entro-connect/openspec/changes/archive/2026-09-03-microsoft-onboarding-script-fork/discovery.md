## Scope

Keep a maintained local copy of Entro's Microsoft Ecosystem Automated PowerShell
onboarding script: full Entro permission-audit Graph/Defender grants (docs lists
plus the 2026-09-02 portal gap), Az.Resources 9 role-definition shape, Teams Bot
permission names aligned with docs. Connect still checksums and runs only the
Skill-held file and never fetches GitBook. When ingest sees origin bytes change,
it succeeds with the local file unchanged, tells the maintainer, and asks whether
to switch the pin; choosing remote rebases our patches onto Entro's new file.
Out of scope: Connect-time download, asking a Connect end-user, making the script
non-interactive, Entro API account creation, secrets in agent runtime.

## Language

**Skill-held onboarding artifact** (`conflicts-with-canonical`):
Canonical glossary still says a vendor-published file in the row folder. This
change keeps that home and checksum runtime, but the Microsoft Azure script
bytes are this project's maintained copy, not a byte-identical GitBook fetch.
_Avoid_: treating origin identity as the Connect runtime bytes; Temporary script
copy for durable patches

**Local onboarding fork** (`promote`):
The Skill-held Microsoft Azure onboarding script after this project's permission
and Az.Resources patches. Catalog `checksum` is of these bytes. Anonymous origin
URL still names Entro's published attachment for ingest comparison.
_Avoid_: Temporary script copy; silently overwriting the fork on origin drift

**Maintainer pin choice** (`draft`):
The ingest-time question after origin bytes change: keep the Local onboarding
fork, or take Entro's file as the new base and re-apply the patches. Not a
Connect Operation mode gate.
_Avoid_: asking the Connect end-user; failing ingest solely because origin drifted

**Entro permission audit** (`draft`):
The Graph/Defender permission set Entro expects on the Identity object, taken
from ingested permissions-reference pages, filled from the operator's 2026-09-02
portal screenshot where docs lag (including Optional Not Granted rows).
_Avoid_: inventing scopes Entro does not list; leaving create-app on Mandatory +
Azure Cloud only

## Decisions

**Context**: Automated PowerShell created/selected `eval.entro.security` and
completed menus 1–2. Entro's permission audit then showed almost everything
outside core Graph as Not Granted. Create-app grants only Mandatory + Azure
Cloud. Menu 2 is interactive and pre-selects already-granted groups. Script
"Teams Send Messages" uses `TeamsAppInstallation.ReadWriteForChat.All`; docs/UI
use `TeamsAppInstallation.ReadWriteSelfForUser.All`. Role create already needed
an Az.Resources 9 pin refresh (`Actions`/`NotActions`). Origin drift today fails
ingest. Connect must not GET `originUrl`.

- **Q1: what the local file changes?** Full Entro permission set by default;
  keep Az.Resources 9; align Teams Bot names with docs/UI.
- **Q2: when to notice a new Entro script?** Documentation ingest only.
- **Q3: Connect vs maintainer?** Connect always uses the local Skill-held file.
  The ask is the maintainer at ingest, not a Connect end-user.
- **Q4: ingest on origin change?** Succeed with local unchanged; notify; ask
  whether to switch the pin to remote.
- **Q5: permission source?** Ingested documentation lists as primary; this
  tenant's audit screenshot fills the documented gap (Optional rows such as
  `Application.ReadWrite.All`).
- **Q6: later take-remote?** Rebase: Entro's new file as base, re-apply our
  patches, then pin that.

## Open questions

- Exact catalog field names for origin SHA-256 vs Skill-held checksum — design.
- Whether rebase patches stay as a checked-in diff/patch file or as documented
  edit steps — design.
- Owner: none blocking for proposal.

## Scenarios discussed

- Create-app path grants the full audit set, not only Mandatory + Azure Cloud.
- Menu 2, if it remains, defaults to the same full set (not already-granted only).
- Origin bytes change, maintainer keeps local: ingest succeeds; pin checksum
  still matches the fork; origin comparison is recorded as drifted pending choice.
- Origin bytes change, maintainer takes remote: rebase patches; both skill trees
  and catalog checksum/version update; Connect still never fetches GitBook.
- Checksum mismatch at Connect: still stop; do not fetch origin.
- Temporary script copy remains names/menus for one run only, not this fork.
