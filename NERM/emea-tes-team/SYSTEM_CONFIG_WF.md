# Update System Configuration - Other (`853bedf4…`)

## What was broken

Starting on **NE Server** (`22988048…`, `sysconfig_type=NE`) hit **Update System Configuration - NE** page `0d347891…`, which had 13 `PageContent` element refs whose content rows were missing (404) → UI 500 / empty page. Same class of break as Update Assignment Details.

**Other** page `70c93fe5…` contents were intact.

## Live fix applied (2026-10-08)

Recreated the 13 page contents from `pages.json` and retargeted the page elements to the new content ids. NE page headings/paragraphs should render again.

## Condition import (if both forms still run / wrong form)

Workflow has NE + Other request actions but needs branching on `sysconfig_type`:

`NERM_emea-tes-team_import_fix_update_system_configuration.json`

1. Delete existing steps on this workflow in Admin (if any)
2. Configuration Import that file

Steps:

1. `sysconfig_type == NE` → Update System Configuration - NE
2. `sysconfig_type == Other` → Update System Configuration - Other
3. Update profile
