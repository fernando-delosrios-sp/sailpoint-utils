## Why

<!--
Explain the motivation for this change. What problem does this solve? Why now?

Hard limits: 50 <= character count <= 1000 (OpenSpec zod schema will validate this)
- Too short: Will receive a `Why section must be at least 50 characters` error
- Too long: Will receive a `Why section should not exceed 1000 characters` error

Recommended structure: Current pain points -> Why address it now -> Expected benefits (1-2 sentences each)
-->

## What Changes

<!--
Describe what will change. Be specific about new capabilities, modifications, or removals.

For behavior changes with clear before-and-after contrast, use the From/To format (markdown has no inline diff):

**<Section or Behavior Name>**
- From: <current state / requirement>
- To: <future state / requirement>
- Reason: <why this change is needed>
- Impact: <breaking / non-breaking, who's affected>

This block can be repeated for multiple changes; pure additions or deletions can be described with a simple list.
-->

## Capabilities

### New Capabilities
<!--
Capabilities being introduced. Replace <name> with kebab-case identifier.
Naming rules (see openspec/specs/README.md): Use compound nouns (at least 2 words),
e.g., `user-auth`, `data-export`, `api-rate-limiting`. Do not use single words.
Each creates specs/<name>/spec.md
-->
- `<name>`: <brief description of what this capability covers>

### Modified Capabilities
<!--
Existing capabilities whose REQUIREMENTS are changing (not just implementation).
Only list here if spec-level behavior changes. Each needs a delta spec file.
Use existing spec names from openspec/specs/. Leave empty if no requirement changes.
-->
- `<existing-name>`: <what requirement is changing>

## Impact

<!-- Affected code, APIs, dependencies, systems -->
