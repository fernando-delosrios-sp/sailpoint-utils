# Email Templates

## Purpose

Branded, language-aware replacements for all 116 Identity Security Cloud (ISC) email templates. Every email gets a banner with the tenant owner's name in SailPoint colours (or your own) and a footer in the recipient's language. End-user emails are also rewritten and translated into English, Spanish, French, Italian, German, Portuguese and Arabic.

The default tenant owner is **EMEA TES Team**; the install script sets your own.

## Overview

| Kind | Count | Body | Subject |
|---|---|---|---|
| Rewritten | 59 | New wording in 7 languages | Improved English (User Invitation: 7 languages) |
| Wrapped | 57 | SailPoint's original English wording inside the branded layout | SailPoint's original |

Rewritten templates cover what end users receive: password and account notices, access requests and removals, approvals, certifications, work items, Just-In-Time access, account requests and separation-of-duties conflicts. Wrapped templates are admin and operations alerts, such as virtual appliance health and source errors.

### Settings

Every template body starts with a settings block. The install script fills it in, and the values can be edited later in the ISC template editor:

```velocity
## Email settings: edit the values between quotes. Import-EmailTemplates.ps1 sets them on import.
#set($mailDefaultLanguage = 'en') ## language when preferredLanguage is missing or unsupported (en, es, fr, it, de, pt, ar)
#set($mailOrgName = 'EMEA TES Team') ## tenant owner or team name in the banner, sign-off and footer
#set($mailBannerTagline = 'Identity & Access') ## small text above the tenant owner name in the banner
#set($mailColorPrimary = '#0033A1') ## banner, headings and buttons
#set($mailColorDark = '#011E69') ## start of the banner gradient
#set($mailColorAccent = '#0071CE') ## links, section titles and information boxes
#set($mailColorHighlight = '#CC27B0') ## banner stripe and warning boxes
#set($mailSupportEmail = '') ## support address shown in the footer; empty hides it
```

The tenant owner name also replaces "The SailPoint Team" sign-off in the wrapped templates. A single quote inside a value is written twice (`'O''Neill'`). Subjects are evaluated apart from the body, so a subject that uses a setting (the User Invitation's) carries its own copy of that line.

### Language selection

Each email picks its language when it is sent:

1. It reads the recipient's `preferredLanguage` identity attribute and uses the first two letters, so `es`, `es-ES` and `es_ES` all mean Spanish.
2. If the attribute is missing, or the language is not one of `en`, `es`, `fr`, `it`, `de`, `pt`, `ar`, the email uses `$mailDefaultLanguage`. An unsupported value or a deleted line falls back to English.

Arabic emails are laid out right to left: text, labels and bullets align right, accent bars move to the right edge and button arrows point left. Wrapped templates keep their English body left to right; only their footer follows the recipient's language.

To fill `preferredLanguage` from each identity's country, use the [Country to Language Map transform](#populating-preferredlanguage).

### User Invitation

The install script always imports the standard invitation, `templates/user_invitation-custom.json`: SailPoint's default, with the same content and order, branded and translated. It has the invitation to use the product, the username, a **Register now** button, and the link to sign in afterwards.

The My Apps invitation is a one-off for EMEA TES Team, kept aside and not offered by the install script. `templates/variants/user_invitation-custom.my-apps.json` is the generated version (sign-in email, username, then five steps through Microsoft My Apps). It has two settings of its own, `$mailSignInDomain` and `$mailMyAppsUrl`, edited in the file or in the ISC template editor. `User Invitation/User Invitation.tenant.json` is the copy stored in `emea-tes-team` before that parameterised build.

## Artifacts

| Path | Purpose |
|---|---|
| `templates/*.json` | One import payload per template (`POST /v2026/notification-templates`) |
| `templates/variants/*.json` | One-off versions kept aside from the install script (the EMEA TES Team My Apps invitation) |
| `User Invitation/User Invitation.tenant.json` | The invitation as stored in `emea-tes-team` before the parameterised build |
| `templates/manifest.json` | Languages, settings and their defaults, variants, English fallback subjects, rewritten and wrapped key lists |
| `Import-EmailTemplates.ps1` | Configures and imports `templates/` (or a backup) into a tenant, with backup and verification |
| `Transforms/Country to Language Map.json` | Lookup transform from country name to a two-letter language code, for `preferredLanguage` |
| `build_templates.py` | Generates `templates/` and validates every template with Velocity in every language |
| `catalog_common.py`, `catalog_identity.py`, `catalog_access.py`, `catalog_work.py` | Wording and translations of the rewritten templates |
| `defaults.snapshot.json` | SailPoint's default email templates, the source of the wrapped bodies |
| `push_templates.py` | Development push: imports from `templates/` with `sail` and re-renders the stored copies |
| `tools/Render.java` | Velocity renderer with mock ISC context, used by the build |

## Import

Requires PowerShell 7 and the [sail CLI](https://developer.sailpoint.com/docs/tools/cli). The import script talks to the tenant only through sail; it never asks for a client secret itself.

Run with no parameters and it walks you through the import:

```powershell
./Import-EmailTemplates.ps1
```

1. Ensures sail is installed (`brew tap sailpoint-oss/tap && brew install sailpoint-cli` on macOS).
2. Asks which sail environment to use, or creates one (`sail env create`, then `sail set pat` so the PAT is stored in your OS keyring).
3. Checks that the environment can reach the tenant and read email templates.
4. Asks for the tenant owner, colours, support email and default language.
5. Shows a checklist of templates (Space selects one, the first line selects or clears all).
6. Prints the changes and asks for confirmation before writing anything.

Review the configured templates locally first. This writes them to a folder and does not contact the tenant:

```powershell
./Import-EmailTemplates.ps1 -OrganizationName 'Acme Corp' -PrimaryColor '#1B365D' -AccentColor '#00857C' `
    -SupportEmail it-help@acme.com -OutputPath ./out/acme
```

Preview what an import would change, then import (skipping the prompts you already answered):

```powershell
./Import-EmailTemplates.ps1 -SailEnvironment acme -OrganizationName 'Acme Corp' -UseTenantBranding -WhatIf
./Import-EmailTemplates.ps1 -SailEnvironment acme -OrganizationName 'Acme Corp' -UseTenantBranding
```

For pipelines, pass `-NonInteractive` and a working `-SailEnvironment`:

```powershell
./Import-EmailTemplates.ps1 -NonInteractive -SailEnvironment acme -OrganizationName 'Acme Corp' -UseTenantBranding
```

### Options

Settings you do not pass keep the template defaults shown in [Settings](#settings).

| Option | Sets |
|---|---|
| `-OrganizationName 'Acme Corp'` | `$mailOrgName` |
| `-BannerTagline 'Access Services'` | `$mailBannerTagline` |
| `-PrimaryColor`, `-DarkColor`, `-AccentColor`, `-HighlightColor` (`#RRGGBB`) | Brand colours |
| `-UseTenantBranding` | Primary and accent colours from the tenant's branding (Global > Branding), unless passed explicitly |
| `-SupportEmail it-help@acme.com` | "Need help? Contact …" in every footer |
| `-DefaultLanguage es` | `$mailDefaultLanguage` |
| `-Scope rewritten` / `-Scope wrapped` | Only the translated end-user templates, or only the admin alerts |
| `-Key 'access_request_*'` | Only matching template keys (wildcards allowed) |
| `-Path <folder>` | Import another folder, such as a backup or an `-OutputPath` folder |
| `-OutputPath <folder>` | Write the configured templates instead of importing |
| `-NoBackup` | Skip the backup |

What an import does:

1. Lists the tenant's custom email templates.
2. Saves the current custom versions of the selected templates to `backups/<timestamp>/`. Keys that had no custom version are listed in `_not-customized.json`.
3. Updates existing custom versions in place, and creates custom versions of the SailPoint defaults for the rest.
4. Reads every template back, checks it exists and that its subject matches, then prints a summary. It exits with code 1 if anything failed.

### Rollback

Import the backup folder:

```powershell
./Import-EmailTemplates.ps1 -SailEnvironment acme -Path ./backups/20261014-103000
```

Templates listed in that backup's `_not-customized.json` had no custom version before. To return them to SailPoint's default, delete their custom version under **Global > Email Templates** in the admin UI.

### Subject length

ISC stores at most 255 subject characters when it creates a custom version of a default template. The User Invitation's multilingual subject is longer: it is kept when the invitation is already customized in the tenant, and replaced by its English subject (`subjectFallback` in the manifest, with a warning) when the script has to create it.

## Populating preferredLanguage

`Transforms/Country to Language Map.json` is a `lookup` transform from the tenant. It maps 255 country names (including spelling variants such as `Czechia` / `Czech Republic` and `Curaçao` / `Curacao`) to two-letter ISO 639-1 language codes, with `en` as the default. Use it to set each identity's `preferredLanguage` from the country your HR source provides.

1. **Create the transform** in the target tenant, with the sail CLI or the SailPoint VS Code extension:

   ```bash
   sail api post /v2026/transforms --env acme -f "Transforms/Country to Language Map.json"
   ```

2. **Map `preferredLanguage`** in the identity profile of your authoritative source (**Identity Management > Identity Profiles > Mappings**). Select the source attribute that holds the country name, then the transform **Country to Language Map**. The resulting mapping is:

   ```json
   {
     "identityAttributeName": "preferredLanguage",
     "transformDefinition": {
       "type": "reference",
       "attributes": {
         "id": "Country to Language Map",
         "input": {
           "type": "accountAttribute",
           "attributes": { "sourceName": "Workday", "attributeName": "country" }
         }
       }
     }
   }
   ```

3. **Preview, then save** the identity profile so ISC recalculates `preferredLanguage` for every identity.

Notes:

- **The input must be a country name** as written in the table (`Spain`, `United Kingdom`). Other values return the default `en`. If the source holds an office or city, chain a location-to-country lookup first: in `emea-tes-team`, the Identity Fusion NG profile uses `Location to Country Map` as the input of this transform. If the source holds ISO country codes, add those codes as keys.
- **Countries map to their main language.** Multilingual countries get one language: Belgium `nl`, Switzerland `de`, Canada `en`. Edit the table if your users there should get another.
- **Languages without a translation** (for example `nl`, `zh`, `ja`) are kept as the identity's preference; the emails use `$mailDefaultLanguage` for them.
- In `emea-tes-team`, the OrangeHRM profile maps `preferredLanguage` with this transform from the account's `location`.

## Limitations

- **Subjects are in English** for every template except the User Invitation, because of the [subject length limit](#subject-length). Bodies are fully translated.
- **ISC's test email does not show the language switch.** It does not run the template logic the way a real send does. Check languages with real emails to identities whose `preferredLanguage` is set.
- **Customized templates stop receiving SailPoint's changes** to the defaults. Refresh `defaults.snapshot.json` and rebuild to pick them up.
- **Outlook desktop** shows the banner gradient as solid primary colour and ignores some right-to-left refinements.
- **Box backgrounds are fixed tints** (light blue for information, light pink for warnings); only their accent bars follow your colours.
- **Translations** were written for this project. UI labels such as SailPoint and Microsoft button names stay in English. Have Arabic reviewed by a native speaker before production use.

## Development

The build needs Python 3.10+ and Java 11+ with these jars in `~/.m2`: `velocity-engine-core-2.0`, `slf4j-api-1.7.36`, `commons-lang3-3.5`.

```bash
python3 build_templates.py             # writes templates/, validates English and Spanish
python3 build_templates.py --preview   # validates all languages, writes out/preview/index.html
python3 push_templates.py --env my-tenant --batch identity    # common | identity | access | work | wrapped | all
python3 push_templates.py --env my-tenant --verify-only --batch all
```

`push_templates.py` pushes the template defaults (no install-time settings) and re-renders the copies ISC stored, which catches template logic damaged by ISC's HTML sanitizer. The build guards against the known cases:

- ISC strips HTML attributes such as `width`, `align` and `cellpadding`, and some CSS on non-table tags, so all layout is inline CSS on tables and cells.
- ISC re-quotes tag attributes even inside Velocity strings, so double-quoted `#set` strings may only contain bare tags such as `<strong>`.
- Velocity double-quoted `#set` strings cannot contain `"` or `#`. Settings use single-quoted strings, which are not interpolated.

To change wording, edit the matching `catalog_*.py`; every string is a tuple in the order `en, es, fr, it, de, pt, ar`. To add a language, append it to `LANGUAGES` in `build_templates.py` (and to `RTL_LANGUAGES` if it is written right to left), then add a translation to every tuple; the build fails until all are present. To add a setting, append it to `SETTINGS` in `build_templates.py` and map its parameter in `$Settings` in `Import-EmailTemplates.ps1`.
