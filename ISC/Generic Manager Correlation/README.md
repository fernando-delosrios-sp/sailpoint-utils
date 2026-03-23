# Generic Manager Correlation

Reusable pattern for correlating manager identities across heterogeneous sources in SailPoint ISC.

## Overview

Manager references are often represented differently across systems (for example, email in one source and username in another).  
This implementation standardizes manager lookup by:

1. Building a normalized lookup token with a transform.
2. Resolving that token in a source rule attached to target sources.

The result is deterministic manager correlation using multiple fallback identifiers in priority order.

## Artifacts

- `Manager` transform
  - Produces a value in the format: `attributeName|attributeValue`
  - Uses `firstValid` to evaluate candidate manager identifiers in sequence
  - Supports optional fallback/default values
- Manager correlation rule (source rule)
  - Parses `attributeName|attributeValue`
  - Searches identities where `attributeName == attributeValue`
  - Returns the first valid correlated identity

## Transform Contract

The transform must return:

`<identityAttributeName>|<lookupValue>`

Examples:

- `email|manager@company.com`
- `uid|jdoe`
- `employeeNumber|123456`

This contract decouples identifier selection (transform) from lookup execution (rule).

## Correlation Flow

1. `Manager` transform evaluates manager identifier candidates (ordered by preference).
2. First non-empty/valid candidate is emitted as `attributeName|attributeValue`.
3. Source rule receives the token during correlation.
4. Rule queries identities using the provided attribute name and value.
5. Matching identity is set as manager when found.

## Configuration Guidance

- Prioritize identifiers in `firstValid` from most reliable to least reliable.
- Ensure each candidate maps to an identity attribute indexed/searchable in ISC.
- Keep attribute names in the transform aligned with the identity profile schema.
- Include a safe fallback only when it is operationally meaningful.
- Attach the rule only to sources that require this manager correlation logic.

## Notes

- This pattern is intended for environments where manager identifiers vary by source.
- Behavior depends on data quality and uniqueness of selected identity attributes.
