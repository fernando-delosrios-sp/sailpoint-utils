## MODIFIED Requirements

### Requirement: SDK loopback client factory

The connector SHALL pre-configure `sailpoint-api-client` instances from operation input `apiUrl` and `token`, exposing them on `RequestContext.sdk` for the duration of each custom operation invocation. The factory SHALL include clients for access requests, access profiles, entitlements, roles, identities, governance groups, SOD policies, SOD violations, IAI recommendations, and IAI outliers in addition to accounts.

#### Scenario: Extended ISC clients available on context

- **GIVEN** a custom operation receives valid apiUrl and token
- **WHEN** the handler accesses ctx.sdk for accessRequests, governanceGroups, sodPolicies, sodViolations, iaiRecommendations, or iaiOutliers
- **THEN** each client SHALL share the same apiUrl and token configuration from the invocation input
