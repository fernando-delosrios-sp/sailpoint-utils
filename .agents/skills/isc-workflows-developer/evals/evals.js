{
  "_copyright": "Copyright (c) 2026 SailPoint Technologies, Inc. All rights reserved.",
  "skill_name": "isc-workflows-developer",
  "evals": [
    {
      "id": 1,
      "skill_path": "core/teams/workflows/skills/isc-workflows-developer",
      "prompt": "Review this ISC workflow design and give prioritized, actionable recommendations. An external-HTTP workflow queries up to 100 non-requestable shared-mailbox entitlements, loops over them, marks each requestable, finds a related identity and that identity's manager, patches the entitlement owner, replaces its request configuration, and finally calls its own external trigger to process more records. The self-call has no batch counter. The query has no explicit limit. The workflow checks only whether the query response body is present before entering the loop. The owner patch reads body[0].manager.id after checking only that the identity-search response body exists. PATCH actions contain both a dynamic jsonPatchRequestBody and an old static jsonRequestBody. Update actions have no catch paths, and all HTTP actions use sp:http version 2. Should this remain a workflow, and what should change if it does?",
      "expected_output": "A severity-ordered review that recognizes bulk entitlement maintenance as a likely external automation use case and, if retained as a workflow, addresses bounded recursion, empty-result and manager guards, bounded queries, conflicting request bodies, failure handling, action-version verification, and a concrete validation plan.",
      "assertions": [
        "The response recommends external API automation or another bounded external process for production-scale bulk entitlement maintenance.",
        "The response identifies the unbounded recursive self-call as a high-priority production risk and proposes an explicit stop condition or batch limit.",
        "The response distinguishes a present response body from a non-empty result and requires validation before reading body[0].manager.id.",
        "The response recommends removing the conflicting static request body and adding visible catch or failure paths.",
        "The response does not claim an exact current HTTP action version or workflow limit without verification.",
        "The response includes validation cases for empty results, missing managers, update failures, bounded batches, and recursion termination."
      ],
      "checks": [
        {
          "text": "Recommends bounded external bulk processing",
          "type": "regex",
          "pattern": "external (API|automation|process|script|orchestration|job)|outside (of )?(ISC )?workflow|bounded external"
        },
        {
          "text": "Flags the recursive self-call",
          "type": "regex",
          "pattern": "recursi|self-?call|self-?invoc"
        },
        {
          "text": "Requires a stop condition or batch bound",
          "type": "regex",
          "pattern": "stop condition|batch (counter|limit|size)|terminat|max(imum)? (batch|iteration|page)"
        },
        {
          "text": "Guards the indexed manager read",
          "type": "regex",
          "pattern": "body\\[0\\]|empty (result|array|response)|non-?empty|no (results|matches)"
        },
        {
          "text": "Removes the conflicting static request body",
          "type": "regex",
          "pattern": "jsonRequestBody|static (request )?body|conflicting"
        },
        {
          "text": "Adds visible failure handling",
          "type": "regex",
          "pattern": "catch (path|branch)|failure path|error path"
        },
        {
          "text": "Defers exact version and limit claims to verification",
          "type": "regex",
          "pattern": "verif|confirm (the )?current|check (the )?current"
        }
      ]
    },
    {
      "id": 2,
      "skill_path": "core/teams/workflows/skills/isc-workflows-developer",
      "prompt": "Review a four-workflow ISC process that maintains role segments. Workflow A finds candidate roles. Workflow B starts once per access profile or entitlement to determine its source. Workflow C reads the expected segment names for that source. Workflow D starts once per expected segment, looks up that segment by name, checks whether the role already has it, and patches one segment. Several access items on a role often belong to the same source, so source and role lookups repeat. The role-search workflow also recursively pages using the previous page's last created timestamp. Propose a target design and migration priorities.",
      "expected_output": "A review that identifies excessive fan-out and repeated work, changes the unit of work to role plus unique source, recommends deduplicating sources and applying missing segments together, treats the per-segment child workflow as unnecessary, and addresses safer pagination and external-processing alternatives.",
      "assertions": [
        "The response identifies one child execution per access item and per segment as the central scale problem.",
        "The target design groups work by role and unique source before calculating expected segments.",
        "The response recommends retrieving current role segments once and applying missing updates together where supported.",
        "The response recommends retiring, inlining, or externally replacing the per-segment update workflow.",
        "The response flags timestamp-boundary pagination as potentially duplicative and recommends an API-supported pagination strategy.",
        "The response separates immediate migration steps from the preferred end state."
      ],
      "checks": [
        {
          "text": "Identifies per-item fan-out as the scale problem",
          "type": "regex",
          "pattern": "fan-?out|per access item|per segment|one (child )?(execution|workflow) per"
        },
        {
          "text": "Regroups work by role and unique source",
          "type": "regex",
          "pattern": "unique source|dedup|group(ed)? by role|role (plus|and) source"
        },
        {
          "text": "Retrieves current segments once and applies them together",
          "type": "regex",
          "pattern": "once|single (lookup|call|request)|batch|together"
        },
        {
          "text": "Retires or inlines the per-segment child workflow",
          "type": "regex",
          "pattern": "inline|retire|remove|eliminat|collapse"
        },
        {
          "text": "Flags timestamp-boundary pagination",
          "type": "regex",
          "pattern": "timestamp|paginat|duplicat|boundary"
        },
        {
          "text": "Separates immediate migration steps from the end state",
          "type": "regex",
          "pattern": "immediate|short-?term|end state|target (design|state)|migration"
        }
      ]
    },
    {
      "id": 3,
      "skill_path": "core/teams/workflows/skills/isc-workflows-developer",
      "prompt": "Review this ISC leaver workflow. It triggers when cloudLifecycleState becomes inactive. An HTTP GET to /v2025/workgroups places `filters: memberships.identityId eq \"<leaver id>\"` in requestHeaders instead of query parameters. The result feeds one of two nearly identical loops; both compare each group's owner.id with the leaver id and PATCH /owner. The branches differ only in whether the replacement owner is the leaver's manager or a fixed fallback. Each loop passes the full Get Identity output as context. The current trigger filter checks newValue == inactive but not the previous value. What are the highest-value corrections and any remaining product limitation?",
      "expected_output": "A review that moves the API filter to a supported query parameter, notes the membership-versus-ownership coverage limitation, calculates the replacement owner once, consolidates duplicate loops, minimizes loop context, tightens the lifecycle transition filter, and proposes validation.",
      "assertions": [
        "The response identifies the request-header filter as incorrectly placed and moves it to URL or query parameters.",
        "The response notes that filtering by memberships.identityId may not find every group owned by the leaver.",
        "The response recommends determining replacementOwnerId before a single shared loop.",
        "The response recommends passing only leaverId and replacementOwnerId or similarly minimal loop context.",
        "The trigger filter recommendation checks a transition into inactive rather than only newValue.",
        "The response recommends external pagination or processing if complete owner-based discovery cannot be done efficiently in the workflow."
      ],
      "checks": [
        {
          "text": "Moves the filter out of request headers",
          "type": "regex",
          "pattern": "query param|URL param|requestHeaders|header"
        },
        {
          "text": "Notes the membership-versus-ownership coverage gap",
          "type": "regex",
          "pattern": "memberships\\.identityId|ownership|owner\\.id|may not find"
        },
        {
          "text": "Computes the replacement owner once before the loop",
          "type": "regex",
          "pattern": "replacementOwnerId|replacement owner|before the (single |shared )?loop"
        },
        {
          "text": "Minimizes loop context",
          "type": "regex",
          "pattern": "leaverId|minimal (loop )?context|only .{0,40}(id|IDs)"
        },
        {
          "text": "Tightens the lifecycle transition filter",
          "type": "regex",
          "pattern": "oldValue|previous value|transition"
        },
        {
          "text": "Considers external pagination or processing",
          "type": "regex",
          "pattern": "paginat|external"
        }
      ]
    },
    {
      "id": 4,
      "skill_path": "core/teams/workflows/skills/isc-workflows-developer",
      "prompt": "Review an identity-attributes-changed workflow that sends password-expiration reminders for four brands. Its trigger filter matches changes to four `*PwdExpirationRemainingDays` attributes. The trigger payload can also include expiration-date and email-subject changes. The workflow loops over all `$.trigger.changes`, passes the full Get Identity attributes object into every iteration, and then branches by attribute name. The user-facing email actions currently send to an administrator distribution list instead of the affected user's brand-specific email. A defined variable named Email is created but never used. If an account lookup is empty or disabled, the branch silently ends as success. Give prioritized corrections and test cases.",
      "expected_output": "A review that preserves trigger-level admission while explaining that it does not trim the payload, narrows the loop input, fixes user recipients, minimizes context, removes dead work, makes missing or disabled accounts visible, and supplies matching and non-matching tests.",
      "assertions": [
        "The response explicitly states that a trigger filter controls workflow admission but does not remove unrelated entries from the delivered changes array.",
        "The response narrows loop input to the four remaining-days attributes instead of removing all workflow branching.",
        "The response changes user-facing recipients to defined recipient-list arrays based on the affected user's brand email.",
        "The response recommends a small defined email context instead of the full identity attributes object.",
        "The response removes the unused Email variable and adds an administrator-visible path for missing or disabled accounts.",
        "The validation plan includes an event containing both a relevant remaining-days change and unrelated changes."
      ],
      "checks": [
        {
          "text": "States a trigger filter gates admission without trimming the payload",
          "type": "regex",
          "pattern": "admission|admitt?|does\\s*\\**n[o']*t\\** (trim|remove|reshape|filter)|still (contains|includes)|payload can (also )?(contain|include)"
        },
        {
          "text": "Narrows loop input to the remaining-days attributes",
          "type": "regex",
          "pattern": "PwdExpirationRemainingDays|four attribute|narrow"
        },
        {
          "text": "Fixes user-facing recipients",
          "type": "regex",
          "pattern": "recipient|brand|affected user"
        },
        {
          "text": "Uses a small defined email context",
          "type": "regex",
          "pattern": "defined variable|minimal context|small context|only the fields"
        },
        {
          "text": "Surfaces missing or disabled accounts and removes dead work",
          "type": "regex",
          "pattern": "unused|dead|disabled|missing account"
        },
        {
          "text": "Validates an event with relevant and unrelated changes",
          "type": "regex",
          "pattern": "unrelated change|alongside|multi-?attribute|simultaneous|both"
        }
      ]
    },
    {
      "id": 5,
      "skill_path": "core/teams/workflows/skills/isc-workflows-developer",
      "prompt": "Troubleshoot and review an ISC leaver notification workflow. It triggers on cloudLifecycleState changing to terminated, gets the identity and accounts, then gets the manager and emails the manager. If manager lookup fails, the catch path fetches the same accounts a second time and routes to an operations email. That fallback email still uses `{{$.getManagerDetails.email}}` as its recipient. The workflow calls Get Manager using managerRef.id without first checking that it exists. Email context includes complete account objects even though the template uses only sourceName and disabled. Send-email actions have no catch paths. Recommend a corrected flow.",
      "expected_output": "A corrected flow that preserves and validates the lifecycle trigger, checks manager presence, reuses account data, sends fallback mail to a shared operations recipient, uses correctly shaped recipient lists, retains only needed account fields, and exposes email failures.",
      "assertions": [
        "The response identifies the fallback recipient as unavailable on the manager-failure path.",
        "The corrected flow checks managerRef.id before invoking the manager lookup and retains a catch path for lookup failure.",
        "The response removes the duplicate account lookup and reuses the original account output.",
        "The response recommends a shared operations mailbox or distribution list for fallback notifications.",
        "The response limits account output to sourceName and disabled or the exact fields rendered by the email.",
        "The response adds visible send-email failure handling."
      ],
      "checks": [
        {
          "text": "Identifies the unavailable fallback recipient",
          "type": "regex",
          "pattern": "getManagerDetails\\.email|fallback (recipient|email)|unavailable"
        },
        {
          "text": "Checks managerRef.id before the manager lookup",
          "type": "regex",
          "pattern": "managerRef\\.id|manager.{0,30}(exists|present)"
        },
        {
          "text": "Removes the duplicate account lookup",
          "type": "regex",
          "pattern": "duplicat|re-?use|second (call|lookup|fetch)|fetched twice|twice|again in the catch"
        },
        {
          "text": "Routes fallback mail to a shared operations recipient",
          "type": "regex",
          "pattern": "operations (mailbox|email|address)|distribution list|shared mailbox"
        },
        {
          "text": "Limits account output to the rendered fields",
          "type": "regex",
          "pattern": "sourceName|disabled|only the fields"
        },
        {
          "text": "Adds send-email failure handling",
          "type": "regex",
          "pattern": "catch|failure path|error path"
        }
      ]
    },
    {
      "id": 6,
      "skill_path": "core/teams/workflows/skills/isc-workflows-developer",
      "prompt": "Perform a security and design review of an idn:account-created workflow. It currently starts for every source, gets the identity and manager immediately, then uses a long Choice chain to continue only when source.name starts with RemovedWMI, APS, HBI, ACI, or Active. Employee notification branches are duplicated by source. If employee email is missing, manager email is used. Several emails explain a deterministic temporary-password formula derived from first name, last name, employee number, and a fixed suffix. Missing employee and manager recipients end in a generic failure, and send-email actions have no operational catch path. Provide prioritized findings and a safer target design.",
      "expected_output": "A security-first review that removes deterministic password formulas, converts the initial source gate to a validated trigger filter, defers and guards manager lookup, normalizes recipient arrays, consolidates duplicate email actions, and adds operational visibility.",
      "assertions": [
        "The deterministic temporary-password formula is identified as a critical or high security concern and removed from email content.",
        "The response proposes a trigger filter using a verified raw-event source identifier or name path and does not include $.trigger in that filter.",
        "The response retains workflow branching for employee-versus-manager recipient logic rather than claiming all Choices belong in the trigger.",
        "The response fetches the manager only when employee email cannot be used and checks managerRef.id first.",
        "The response consolidates duplicated notification actions using defined context and recipient-list variables.",
        "The response adds administrator notification or catch paths for missing recipients and delivery failures."
      ],
      "checks": [
        {
          "text": "Identifies the deterministic password formula as a security concern",
          "type": "regex",
          "pattern": "password (formula|derivation|pattern)|deterministic|temporary password"
        },
        {
          "text": "Removes the formula from email content",
          "type": "regex",
          "pattern": "remove|do\\s*\\**n[o']*t\\** (include|send)|never (include|send)|stop (including|sending)"
        },
        {
          "text": "Converts the source gate into a validated trigger filter",
          "type": "regex",
          "pattern": "trigger filter|source\\.name|raw event"
        },
        {
          "text": "Retains branching for employee-versus-manager recipients",
          "type": "regex",
          "pattern": "branch|Choice|employee.{0,40}manager"
        },
        {
          "text": "Defers and guards the manager lookup",
          "type": "regex",
          "pattern": "managerRef\\.id|only (when|if)|defer"
        },
        {
          "text": "Adds operational visibility for missing recipients",
          "type": "regex",
          "pattern": "catch|missing recipient|failure path|administrator"
        }
      ]
    },
    {
      "id": 7,
      "skill_path": "core/teams/workflows/skills/isc-workflows-developer",
      "prompt": "Review an idn:post-provisioning workflow that notifies administrators about failed account creation. It currently starts for every post-provisioning event, gets the recipient identity, loops over every accountRequest, and inside the loop checks provisioningResult == failed and accountOperation == Create before emailing. The loop context is `$`, so every iteration carries the full workflow state. Failure details are in the top-level trigger `errors` array. The workflow uses three individual administrator addresses. One event can contain multiple failed Create requests, but stakeholders have not decided whether they want one email per account or one summary per tracking number. Recommend improvements without inventing that missing requirement.",
      "expected_output": "A review that adds and validates a failed-Create trigger filter, preserves the verified top-level error path, creates a minimal loop context, recommends a shared recipient, and explicitly asks for or branches on the unresolved notification-volume decision.",
      "assertions": [
        "The response proposes a raw-event trigger filter requiring action Access Request plus a failed Create account request.",
        "The response keeps the top-level trigger errors path because the supplied evidence places errors there.",
        "The response replaces full-state loop context with a defined context containing only recipient name, employee identifier, tracking number, and other email fields.",
        "The response recommends a distribution list or shared mailbox instead of individual recipients.",
        "The response does not choose one-email-per-account versus one-summary-per-tracking-number without acknowledging the unresolved business decision.",
        "The validation plan covers successful Create, failed non-Create, failed Create, and multiple failures in one event."
      ],
      "checks": [
        {
          "text": "Proposes a failed-Create trigger filter",
          "type": "regex",
          "pattern": "Access Request|accountRequest|failed"
        },
        {
          "text": "Keeps the verified top-level errors path",
          "type": "regex",
          "pattern": "trigger\\.errors|top-?level errors|errors array"
        },
        {
          "text": "Replaces full-state loop context with a minimal context",
          "type": "regex",
          "pattern": "full (workflow )?state|minimal context|defined context|tracking number"
        },
        {
          "text": "Recommends a shared recipient",
          "type": "regex",
          "pattern": "distribution list|shared mailbox|group (email|address)"
        },
        {
          "text": "Acknowledges the unresolved notification-volume decision",
          "type": "regex",
          "pattern": "unresolved|stakeholder|clarif|business decision|confirm"
        },
        {
          "text": "Covers the four validation scenarios",
          "type": "regex",
          "pattern": "successful Create|non-?Create|multiple (failed|failures)"
        }
      ]
    },
    {
      "id": 8,
      "skill_path": "core/teams/workflows/skills/isc-workflows-developer",
      "prompt": "Review an identity-attributes-changed workflow that creates ServiceNow tickets when codigoCargo changes to one of 13 supported values. The workflow currently starts for broad identity changes, searches for the identity, loops over all changed attributes, passes a complete search result object through loop context, and uses 13 chained string comparisons. Each code branch duplicates one ticket HTTP request and one ISC logging HTTP request. The ticket request has no idempotency key. Several branches map `question_system_service` from `question_perfil`, and one log path contains `attributes.attributes.cpf`. Recommend an implementation order that reduces execution volume without hiding correctness bugs.",
      "expected_output": "A prioritized review that gates admission with a validated codigoCargo trigger filter, removes the broad loop, minimizes identity data, consolidates routing and HTTP actions, adds idempotency, corrects bad field paths, and sequences mitigation before refactoring.",
      "assertions": [
        "The implementation order adds a trigger filter requiring attribute codigoCargo and a supported new value before consolidating the workflow's duplicated branches.",
        "The response removes or narrows the loop over all changed attributes and explains that workflow JSONPath must be validated separately from trigger-filter JSONPath.",
        "The response replaces the full search result context with a small defined variable or narrower identity lookup.",
        "The response consolidates duplicated ticket and log actions around a selected mapping or recommends moving mapping to an external endpoint.",
        "The response adds a stable idempotency or correlation value to protect against duplicate tickets on retry.",
        "The response explicitly corrects both question_system_service and the duplicated attributes segment in the CPF path."
      ],
      "checks": [
        {
          "text": "Gates admission with a codigoCargo trigger filter first",
          "type": "regex",
          "pattern": "codigoCargo"
        },
        {
          "text": "Narrows or removes the loop over all changed attributes",
          "type": "regex",
          "pattern": "loop|narrow|remove"
        },
        {
          "text": "Separates workflow JSONPath from trigger-filter JSONPath validation",
          "type": "regex",
          "pattern": "separately|trigger filter|different evaluator|validate"
        },
        {
          "text": "Replaces the full search result context",
          "type": "regex",
          "pattern": "search result|defined variable|narrower|minimal"
        },
        {
          "text": "Adds an idempotency or correlation value",
          "type": "regex",
          "pattern": "idempoten|correlation|dedup"
        },
        {
          "text": "Corrects the question_system_service mapping",
          "type": "regex",
          "pattern": "question_system_service"
        },
        {
          "text": "Corrects the duplicated attributes segment in the CPF path",
          "type": "regex",
          "pattern": "attributes\\.attributes"
        }
      ]
    },
    {
      "id": 9,
      "skill_path": "core/teams/workflows/skills/isc-workflows-developer",
      "prompt": "Review an ISC workflow that reacts to identity attribute changes and updates profiles in an external NERM service. The trigger currently has no filter even though the workflow only uses tenantid, departmentCode, countryCode, dowVendorCode, companyCode, locationCode, firstname, lastname, uid, accountType, and sourceSystem. Multiple sp:http version 2 actions contain a literal Authorization header. Several later PATCH actions read `profiles[0]` from lookup responses without checking whether a profile exists. One defined variable stores getIdentity.meta.created but has no downstream references. Give concise, severity-ordered recommendations and state what needs current-product verification.",
      "expected_output": "A review that treats the literal authorization value as a security issue, adds a trigger filter for relevant attributes, guards every indexed lookup, removes dead work, and avoids unsupported certainty about action-version migration or secret-storage behavior.",
      "assertions": [
        "The literal Authorization header is the highest-severity finding and the response recommends rotating it if exposed plus moving it to a supported secret-storage mechanism.",
        "The response recommends upgrading HTTP actions only after confirming the currently supported version and migration requirements.",
        "The trigger filter uses raw event changes and includes only the attributes consumed by the workflow.",
        "The response adds a non-empty or count guard before every use of profiles[0].",
        "The unused created variable is removed only after confirming it has no references.",
        "The response calls for post-migration verification of authentication, request fields, output paths, and persisted trigger configuration."
      ],
      "checks": [
        {
          "text": "Treats the literal Authorization header as the top finding",
          "type": "regex",
          "pattern": "Authorization header|hardcoded|literal"
        },
        {
          "text": "Recommends rotating the exposed credential",
          "type": "regex",
          "pattern": "rotat"
        },
        {
          "text": "Moves the secret to supported storage",
          "type": "regex",
          "pattern": "Parameter Storage|secret (storage|manage)|externaliz"
        },
        {
          "text": "Guards every indexed profiles lookup",
          "type": "regex",
          "pattern": "profiles\\[0\\]|non-?empty|exists|length"
        },
        {
          "text": "Adds a trigger filter limited to consumed attributes",
          "type": "regex",
          "pattern": "trigger filter"
        },
        {
          "text": "Confirms the supported action version before upgrading",
          "type": "regex",
          "pattern": "verif|confirm"
        },
        {
          "text": "Requires post-migration verification",
          "type": "regex",
          "pattern": "after (the )?(upgrade|migration)|re-?check|post-?migration"
        }
      ]
    },
    {
      "id": 10,
      "skill_path": "core/teams/workflows/skills/isc-workflows-developer",
      "prompt": "Diagnose excessive ISC workflow executions in this recursive remediation process. A processor searches identities with limit 250. Its external-trigger payload contains a string named pagination. Every self-call appends `A` to that string, and the next search uses `pagination.length()` as offset. The observed offsets are 0, 1, 2, and 3. After looping over a page, the processor starts one child workflow per identity and calls itself again while pagination.length() <= 30. When invoked without pagination, it first calls itself with an empty string before doing any search. Successful remediation is supposed to change the condition used by the search, but the timing is unknown. Explain the root cause, quantify the overlap for the first two pages, and propose a safer control flow.",
      "expected_output": "An evidence-backed diagnosis of overlapping pagination and execution amplification, including the 249-record overlap between offsets 0 and 1, numeric page offsets, a partial-page stop condition, removal of the bootstrap self-call, and checks that remediation removes records from the search population.",
      "assertions": [
        "The response identifies string length as the pagination root cause rather than blaming the child workflow alone.",
        "The response correctly states that limit 250 with offsets 0 and 1 overlaps by 249 records.",
        "The corrected design either uses numeric page-size offsets for a stable snapshot or an offset-zero drain strategy for a mutating result set, with expression and progress behavior verified.",
        "The recursion stop condition is based on page results, such as stopping on a partial page, and also retains a safety bound where appropriate.",
        "The response removes the initial no-work bootstrap self-call by defaulting offset to zero.",
        "The response verifies that successful remediation removes identities from the search population and considers reducing unnecessary child calls."
      ],
      "checks": [
        {
          "text": "Identifies string length as the pagination root cause",
          "type": "regex",
          "pattern": "length\\(\\)|string length|pagination string"
        },
        {
          "text": "Quantifies the 249-record overlap",
          "type": "regex",
          "pattern": "249"
        },
        {
          "text": "Proposes numeric offsets or an offset-zero drain",
          "type": "regex",
          "pattern": "numeric offset|page size|offset (0|zero)|drain"
        },
        {
          "text": "Bases the stop condition on page results",
          "type": "regex",
          "pattern": "partial page|fewer than|empty page|page results"
        },
        {
          "text": "Removes the bootstrap self-call",
          "type": "regex",
          "pattern": "bootstrap|initial self-?call|default(ing)? (the )?offset"
        },
        {
          "text": "Verifies remediation removes identities from the search population",
          "type": "regex",
          "pattern": "remov\\w*.{0,50}(search|population)|no longer (match|appear)"
        }
      ]
    },
    {
      "id": "approval-timeout-vs-end-date",
      "skill_path": "core/teams/workflows/skills/isc-workflows-developer",
      "prompt": "A customer wants approvals for the `Shared Mailbox Admin` entitlement to expire when nobody acts within 30 days. An admin already set `requireEndDate` and `maxPermittedAccessDuration` on that entitlement's request configuration, and the approvals that are already pending did not change. Tell me the correct configuration surface, the exact request sequence, and what happens to approvals that are already pending.",
      "expected_output": "Separates approval timeout from requested-access duration, configures timeoutConfig through the generic approvals config for the entitlement, preserves unrelated fields, and states that the change is not retroactive.",
      "assertions": [
        "The response configures the approval expiration through the generic approvals timeoutConfig rather than the access-item request configuration.",
        "The response targets the entitlement-scoped generic approvals configuration.",
        "The response preserves the rest of the returned configuration and verifies persistence.",
        "The response states that pending approvals do not change retroactively."
      ],
      "checks": [
        {
          "text": "Uses timeoutConfig",
          "type": "contains",
          "value": "timeoutConfig"
        },
        {
          "text": "Targets the generic approvals configuration",
          "type": "regex",
          "pattern": "generic-approvals|generic approvals"
        },
        {
          "text": "Scopes the configuration to the entitlement",
          "type": "regex",
          "pattern": "\\{?entitlementId\\}?[:/]ENTITLEMENT|ENTITLEMENT"
        },
        {
          "text": "Preserves unrelated configuration fields",
          "type": "regex",
          "pattern": "preserve|unrelated field|full (existing |returned )?config"
        },
        {
          "text": "States the change is not retroactive",
          "type": "regex",
          "pattern": "not retroactive|newly submitted|created afterward|only.{0,40}new request|already pending.{0,80}(unchanged|will not|do not)"
        }
      ]
    },
    {
      "id": "adaptive-approval-auto-approve",
      "skill_path": "core/teams/workflows/skills/isc-workflows-developer",
      "prompt": "Our Approval Policy workflow action sends no autoApprove value in recent executions, but an execution from July 2026 shows `autoApprove: true`. We want every Adaptive Approval policy to auto-approve. Which configuration do I change, how do I change it, and how should I read that older execution input?",
      "expected_output": "Configures the custom access request approval type, leaves autoApprove unset so sp-approvals resolves the hierarchy, uses PUT to change configuration, and explains the pre-deployment boolean mapping.",
      "assertions": [
        "The response configures the Adaptive Approval policy approval type rather than the standard access-request approval type.",
        "The response explains that the workflow action leaves autoApprove unset and the approval service resolves the configuration hierarchy.",
        "The response distinguishes reading configuration from changing it.",
        "The response explains the older execution input as the prior boolean mapping."
      ],
      "checks": [
        {
          "text": "Uses the custom access request approval type",
          "type": "contains",
          "value": "CUSTOM_ACCESS_REQUEST_APPROVAL"
        },
        {
          "text": "Explains autoApprove is left unset and inherited",
          "type": "regex",
          "pattern": "unset|not set|omit|inherit|configuration hierarchy"
        },
        {
          "text": "Changes configuration with PUT",
          "type": "regex",
          "pattern": "PUT"
        },
        {
          "text": "Explains the legacy boolean mapping",
          "type": "regex",
          "pattern": "DIRECT|boolean mapping|prior (WPS|mapping)|older execution"
        },
        {
          "text": "Does not invent a per-workflow override",
          "type": "regex",
          "pattern": "no (per-workflow|supported hidden|hidden JSON)|not (configurable|available) (in|per)|no supported override"
        }
      ]
    },
    {
      "id": "form-action-url-not-templatable",
      "skill_path": "core/teams/workflows/skills/isc-workflows-developer",
      "prompt": "In the Form action's Notification Body I want the form task link in the middle of a sentence instead of at the bottom. Which JSONPath or Velocity variable holds the form task URL? If there is none, can I send it from a separate Send Email step instead?",
      "expected_output": "States the generated form task URL is not exposed to workflow data flow, is appended after the configured body, and cannot be repositioned today.",
      "assertions": [
        "The response states that no JSONPath or Velocity variable exposes the generated form task URL.",
        "The response explains that ISC appends the link after the configured notification and reminder body.",
        "The response does not propose a separate Send Email step that references the generated URL.",
        "The response treats repositioning as a product enhancement request."
      ],
      "checks": [
        {
          "text": "States the URL is not exposed",
          "type": "regex",
          "pattern": "is\\s*\\**n[o']*t\\** (exposed|surfaced|available)|not exposed|no (documented |such |supported )*(JSONPath|velocity|variable|path)|cannot be referenced"
        },
        {
          "text": "Explains the link is appended after the body",
          "type": "regex",
          "pattern": "append|after the (configured )?(notification )?body|end of the (notification )?body|at the bottom"
        },
        {
          "text": "Treats repositioning as an enhancement request",
          "type": "regex",
          "pattern": "enhancement|feature request|product limitation|is\\s*\\**n[o']*t\\** customiz|cannot (currently )?be customiz"
        },
        {
          "text": "Rejects a separate Send Email step for the generated URL",
          "type": "regex",
          "pattern": "Send Email.{0,120}(n[o']?t|unavailable|cannot)|separate.{0,60}step.{0,80}(n[o']?t viable|will not work|cannot)"
        }
      ]
    },
    {
      "id": "form-array-input-objects",
      "skill_path": "core/teams/workflows/skills/isc-workflows-developer",
      "prompt": "My Form action array input renders one unusable option. I built the input from a Define Variable holding `[\"alpha\",\"beta\"]` and appended `.JSON()` to it. Array Value is `$.value` and Array Label is `$.label`. Fix it.",
      "expected_output": "Explains that array inputs need objects, that Array Value and Array Label are evaluated per item, and that .JSON() serializes rather than reshapes.",
      "assertions": [
        "The response requires an array of objects for the form array input.",
        "The response explains that .JSON() serializes data and does not map primitives into objects.",
        "The response explains that Array Value and Array Label are relative to a single item.",
        "The response recommends preserving, re-fetching, or reshaping an upstream object list."
      ],
      "checks": [
        {
          "text": "Requires an array of objects",
          "type": "regex",
          "pattern": "array of objects|objects\\b|maps\\b"
        },
        {
          "text": "Explains .JSON() only serializes",
          "type": "regex",
          "pattern": "serializ|\\.JSON\\(\\).{0,80}(does not|only|cannot)"
        },
        {
          "text": "Explains per-item path evaluation",
          "type": "regex",
          "pattern": "relative to (each|one|a single) item|per item|each item"
        },
        {
          "text": "Recommends reshaping upstream instead of in Define Variable",
          "type": "regex",
          "pattern": "re-?fetch|preserve.{0,40}object|reshape|upstream (object )?list|HTTP"
        }
      ]
    },
    {
      "id": "joiner-versus-rehire-trigger",
      "skill_path": "core/teams/workflows/skills/isc-workflows-developer",
      "prompt": "I want one workflow for joiners and rehires. My plan is Identity Attributes Changed with a trigger filter matching `cloudLifecycleState` changing from null to active. A teammate says he saw a processed event with previousState null and newState active, so one trigger should be enough. Confirm or correct the design.",
      "expected_output": "Uses Identity Created for joiners and Identity Lifecycle State Changed for rehires, and treats the observed processed-trigger behavior as unvalidated.",
      "assertions": [
        "The response states that Identity Attributes Changed does not detect a null-to-active cloudLifecycleState transition.",
        "The response uses Identity Created filtered to active for joiners.",
        "The response uses Identity Lifecycle State Changed for rehires.",
        "The response treats the teammate's observation as tenant-observed behavior that needs live validation."
      ],
      "checks": [
        {
          "text": "Uses Identity Created for joiners",
          "type": "contains",
          "value": "Identity Created"
        },
        {
          "text": "Uses the lifecycle state trigger for rehires",
          "type": "contains",
          "value": "Identity Lifecycle State Changed"
        },
        {
          "text": "Rejects attribute-change detection of null-to-active",
          "type": "regex",
          "pattern": "n[o']?t (reliably )?detect|cannot detect|is not detected|n[o']?t guarantee detect|does\\s*\\**n[o']*t\\** fire|miss(es)? joiners|will (very likely )?miss"
        },
        {
          "text": "Labels the observation as needing validation",
          "type": "regex",
          "pattern": "observed (tenant )?behavior|not (a )?documented (contract|behavior)|validate (it )?live|needs validation"
        }
      ]
    },
    {
      "id": "loop-success-hides-child-failures",
      "skill_path": "core/teams/workflows/skills/isc-workflows-developer",
      "prompt": "A loop step reports Success but several PATCH updates inside it never applied, and the workflow surfaced no error. Where do I look, and how do I make this condition fail the workflow?",
      "expected_output": "Points at loop failureItems and successfulItems and adds an explicit post-loop failure branch.",
      "assertions": [
        "The response inspects the loop output failure items.",
        "The response inspects the loop output successful items.",
        "The response adds an explicit check after the loop rather than trusting parent status."
      ],
      "checks": [
        {
          "text": "Names failureItems",
          "type": "contains",
          "value": "failureItems"
        },
        {
          "text": "Names successfulItems",
          "type": "contains",
          "value": "successfulItems"
        },
        {
          "text": "Adds a post-loop failure check",
          "type": "regex",
          "pattern": "after the loop|post-?loop|following the loop|once the loop"
        },
        {
          "text": "States parent success does not prove item success",
          "type": "regex",
          "pattern": "(parent|loop|success).{0,80}(does\\s*\\**n[o']*t\\**|not prove|no guarantee|only on whether)|Success.{0,120}n[o']?t branch"
        }
      ]
    },
    {
      "id": "serial-loop-child-and-limits",
      "skill_path": "core/teams/workflows/skills/isc-workflows-developer",
      "prompt": "A Serial For Loop over 1,500 items looks hung. The parent execution history ends at the Serial Loop `ActivityTaskStarted` event and never names an inner step. In Test Workflow the same loop stopped after 50 items. I added a Break Loop step to cancel the run. Diagnose this and tell me what is wrong with my assumptions.",
      "expected_output": "Explains the generated child execution, that live loop input limits and Test Workflow iteration caps differ and must be read from current loop-operator docs, and that Break Loop cannot interrupt a waiting inner action.",
      "assertions": [
        "The response directs investigation to the generated child execution rather than an iterator hang.",
        "The response names the child workflow and run identifiers to capture.",
        "The response looks up current Serial Loop input and Test Workflow iteration limits in public documentation instead of quoting remembered numbers.",
        "The response explains that a Test Workflow stop is not the live input cap and is not proof of a hang.",
        "The response states that Break Loop only applies when execution reaches it."
      ],
      "checks": [
        {
          "text": "Directs to the generated child execution",
          "type": "regex",
          "pattern": "child (workflow|execution)|generated child"
        },
        {
          "text": "Names the run identifier to collect",
          "type": "regex",
          "pattern": "runId|run ID"
        },
        {
          "text": "Looks up current loop limits in public docs",
          "type": "regex",
          "pattern": "loop-operators|loop operators|current (loop |input )?limit|documentation"
        },
        {
          "text": "Distinguishes Test Workflow from live execution limits",
          "type": "regex",
          "pattern": "Test Workflow|test (run|cap|limit|iteration)|differs|not (proof|the live)"
        },
        {
          "text": "Corrects the Break Loop assumption",
          "type": "regex",
          "pattern": "Break Loop.{0,140}(only|does not|cannot)|does not cancel|cannot interrupt"
        }
      ]
    },
    {
      "id": "get-accounts-output-retention",
      "skill_path": "core/teams/workflows/skills/isc-workflows-developer",
      "prompt": "Get Accounts returns only account IDs in my workflow, but the same action returns full attributes for a colleague in another tenant. He added a Wait step before the action and says that fixed it. Explain what is happening and what I should check.",
      "expected_output": "Explains selective output retention through Additional Output Data and downstream references, and rejects the wait as a fix.",
      "assertions": [
        "The response explains that the action retains required fields plus explicitly selected extras.",
        "The response states that adding a delay does not change output retention.",
        "The response inspects downstream field references.",
        "The response compares persisted workflow versions or action inputs between the two executions."
      ],
      "checks": [
        {
          "text": "Names the output selection surface",
          "type": "regex",
          "pattern": "Additional Output Data|resultSelector"
        },
        {
          "text": "Rejects the wait as a fix",
          "type": "regex",
          "pattern": "(wait|delay).{0,100}(does\\s*\\**n[o']*t\\**|will not|no effect|is\\s*n[o']*t|coincidence|never the actual fix)"
        },
        {
          "text": "Inspects downstream references",
          "type": "regex",
          "pattern": "downstream|referenced by|later step"
        },
        {
          "text": "Compares persisted definitions between executions",
          "type": "regex",
          "pattern": "workflow version|persisted|exported? definition|configuration drift"
        }
      ]
    },
    {
      "id": "interactive-trigger-persistence-evidence",
      "skill_path": "core/teams/workflows/skills/isc-workflows-developer",
      "prompt": "Test Workflow returns a `Not Found` error and Manager shows Trigger as `--`. I am sure we hit the known Interactive Trigger persistence bug, and I can send you a screenshot of the Builder showing the trigger. Confirm the diagnosis.",
      "expected_output": "Requires persisted-definition evidence before diagnosing the defect and states that a generic Not Found error is insufficient.",
      "assertions": [
        "The response retrieves the saved workflow through export or the workflows API.",
        "The response verifies whether the persisted definition actually lacks the trigger.",
        "The response states that a generic Test Workflow Not Found error alone is insufficient evidence.",
        "The response declines to diagnose from a screenshot."
      ],
      "checks": [
        {
          "text": "Requires export or API retrieval",
          "type": "regex",
          "pattern": "export|workflow GET|GET .{0,40}workflows|retrieve the saved"
        },
        {
          "text": "Verifies the persisted trigger",
          "type": "regex",
          "pattern": "persisted"
        },
        {
          "text": "Rejects Not Found alone as evidence",
          "type": "regex",
          "pattern": "(not enough|insufficient|not sufficient|alone is not|by itself)"
        },
        {
          "text": "Declines screenshot-only diagnosis",
          "type": "regex",
          "pattern": "screenshot"
        }
      ]
    },
    {
      "id": "form-regex-validation-limits",
      "skill_path": "core/teams/workflows/skills/isc-workflows-developer",
      "prompt": "Give me one form REGEX validation for a text field that requires an uppercase letter, a digit, and a symbol. I already tested `^(?=.*[A-Z])(?=.*\\d)(?=.*[\\W_]).{12,}$` in an online tester and it works there.",
      "expected_output": "States that ISC form REGEX rejects lookarounds and backreferences and moves complexity enforcement elsewhere.",
      "assertions": [
        "The response states that lookahead and similar constructs are rejected by form REGEX validation.",
        "The response explains the expression will not save even though external testers accept it.",
        "The response moves complexity enforcement after submission or to the password policy capability."
      ],
      "checks": [
        {
          "text": "Names the unsupported constructs",
          "type": "regex",
          "pattern": "lookahead|lookaround|look-ahead|backreference"
        },
        {
          "text": "States the expression is rejected",
          "type": "regex",
          "pattern": "(are|is|aren|isn)\\s*\\**n?[o']*t\\** supported|not supported|reject|unsupported|wo\\s*n[o']*t (work|save)|cannot (be )?save|can\\s*n[o']*t enforce"
        },
        {
          "text": "Moves enforcement elsewhere",
          "type": "regex",
          "pattern": "after submission|password[- ]policy|post-submission|in the workflow"
        }
      ]
    },
    {
      "id": "identity-history-from-upper-bound",
      "skill_path": "core/teams/workflows/skills/isc-workflows-developer",
      "prompt": "Get Identity History with `from` set to last Monday keeps returning events older than that date. Is the filter broken? I want only the events after that date.",
      "expected_output": "Explains that from is an upper bound and filters item timestamps client-side for a lower cutoff.",
      "assertions": [
        "The response explains that from selects events on or before the instant.",
        "The response states the filter is behaving as documented.",
        "The response omits from and filters each item's timestamp for a lower cutoff."
      ],
      "checks": [
        {
          "text": "Explains the upper-bound semantics",
          "type": "regex",
          "pattern": "upper bound|on or before|at or before"
        },
        {
          "text": "Recommends omitting from for a lower cutoff",
          "type": "regex",
          "pattern": "omit"
        },
        {
          "text": "Filters item timestamps outside the API",
          "type": "regex",
          "pattern": "client-?side|filter each item|filter the (returned )?item|paginat"
        },
        {
          "text": "States the filter is behaving as documented",
          "type": "regex",
          "pattern": "as documented|documented behavior|n[o']?t (a )?(broken|bug)|working as (designed|intended|documented)|expected behavior"
        }
      ]
    },
    {
      "id": "manage-access-account-selection",
      "skill_path": "core/teams/workflows/skills/isc-workflows-developer",
      "prompt": "Manage Access must grant an access profile to one specific account out of a user's three accounts on the same source. I configured the Access Profile Multiple Account Options and passed accountSelection into the Manage Access action, but it is ignored. What tenant configuration am I missing?",
      "expected_output": "States that Manage Access does not expose accountSelection, points to the Create Access Request API, and explains that Multiple Account Options do not apply to access requests.",
      "assertions": [
        "The response states that the Manage Access action does not expose accountSelection.",
        "The response recommends the Create Access Request API with explicit accountSelection.",
        "The response states that Multiple Account Options do not apply to access requests.",
        "The response does not treat this as missing tenant configuration."
      ],
      "checks": [
        {
          "text": "States accountSelection is unsupported by the action",
          "type": "regex",
          "pattern": "does\\s*\\**n[o']*t\\** (expose|support)|not exposed|is unsupported|is (simply )?(dropped|ignored)|no .{0,20}accountSelection"
        },
        {
          "text": "Recommends the Create Access Request API",
          "type": "contains",
          "value": "Create Access Request"
        },
        {
          "text": "Explains Multiple Account Options do not apply",
          "type": "regex",
          "pattern": "Multiple Account Options.{0,120}(do(es)?\\s*\\**n[o']*t\\**|not apply)|do(es)?\\s*n[o']*t apply to access request"
        }
      ]
    },
    {
      "id": "json-serialization-unquoted-interpolation",
      "skill_path": "core/teams/workflows/skills/isc-workflows-developer",
      "prompt": "My HTTP action sends my array as a string. The body contains `\"members\": \"{{$.getMembers.body.JSON()}}\"` and the receiving API rejects it as a string. Fix the body.",
      "expected_output": "Removes the quotes around the interpolation so the array is emitted as raw JSON, and reserves quoted interpolation for scalars.",
      "assertions": [
        "The response removes the surrounding quotes from the interpolation.",
        "The response keeps the .JSON() call for the array.",
        "The response reserves quoted interpolation for scalar strings."
      ],
      "checks": [
        {
          "text": "Removes the surrounding quotes",
          "type": "regex",
          "pattern": "unquoted|without (the )?quotes|remove the quotes|drop the quotes"
        },
        {
          "text": "Keeps the JSON() serialization",
          "type": "contains",
          "value": ".JSON()"
        },
        {
          "text": "Reserves quoted interpolation for scalars",
          "type": "regex",
          "pattern": "scalar|only for string|string values"
        }
      ]
    },
    {
      "id": "activity-error-is-not-denial",
      "skill_path": "core/teams/workflows/skills/isc-workflows-developer",
      "prompt": "My Generic Approval Policy step returned `activity error`. I read that as the approval being denied by policy. Where do I see the approval, and was it denied?",
      "expected_output": "Explains activity error as an action-execution wrapper, directs diagnosis to the nested error, and names the approvals surface for generic approvals.",
      "assertions": [
        "The response explains that activity error is an action execution failure, not an approval decision.",
        "The response inspects the nested error cause.",
        "The response states that successful generic approvals appear under the other approvals surface."
      ],
      "checks": [
        {
          "text": "Rejects the denial interpretation",
          "type": "regex",
          "pattern": "is\\s*\\**n[o']*t\\** (an? )?(approval |policy )*(denial|decision|deny|sp-approvals)|rather than an? (approval|policy)|action[- ]execution (wrapper|failure)|does\\s*n[o']*t (mean|indicate).{0,40}deni"
        },
        {
          "text": "Inspects the nested error",
          "type": "regex",
          "pattern": "nested|underlying|wrapped|inner error"
        },
        {
          "text": "Names the approvals surface",
          "type": "regex",
          "pattern": "Approvals ?(→|->|>|,|\\s)+ ?Other|under Other"
        }
      ]
    },
    {
      "id": "windows-server-pag-execution-path",
      "skill_path": "core/teams/workflows/skills/isc-workflows-developer",
      "prompt": "The Workflow Windows Server action fails for us. My understanding is that it uploads a temporary .ps1 to the target like IQService does, and we point it at a mapped drive path `Z:\\\\scripts\\\\provision.ps1`. Explain how execution actually works and where I should look for the failure.",
      "expected_output": "Rejects the IQService upload model, requires an existing absolute local script path, states mapped drives and UNC paths are unsupported, and diagnoses cloud-to-PAG delivery separately from target remoting using current Windows Server action docs.",
      "assertions": [
        "The response rejects the IQService temporary-script assumption.",
        "The response requires an existing absolute local script path on the target.",
        "The response states that mapped drives and UNC paths are unsupported.",
        "The response distinguishes command delivery from target remoting and points to current Windows Server action documentation."
      ],
      "checks": [
        {
          "text": "Rejects the IQService upload assumption",
          "type": "regex",
          "pattern": "not IQService|does not (create|upload)|no temporary|unlike IQService"
        },
        {
          "text": "Requires an existing absolute local path",
          "type": "regex",
          "pattern": "absolute.{0,40}local|already (exist|present)|must exist"
        },
        {
          "text": "Rejects the mapped drive path",
          "type": "regex",
          "pattern": "mapped drive|UNC"
        },
        {
          "text": "Separates delivery from target remoting",
          "type": "regex",
          "pattern": "PAG|remoting|WinRM|WSMan|PowerShell Remoting|delivery"
        },
        {
          "text": "Points to current Windows Server action docs",
          "type": "regex",
          "pattern": "documentation|docs|Windows Server action"
        }
      ]
    },
    {
      "id": "chained-workflow-status-visibility",
      "skill_path": "core/teams/workflows/skills/isc-workflows-developer",
      "prompt": "I want the native Interactive Process to stay In Progress until three child workflows started through External Trigger finish, and I plan to start the first stage with a Form Submitted trigger. Tell me whether this gives my users one consolidated status.",
      "expected_output": "Explains that External Trigger children run asynchronously with independent execution IDs, that status does not roll up, and that the parent must stay open with bounded waits.",
      "assertions": [
        "The response states that External Trigger child executions are asynchronous with independent execution identifiers.",
        "The response states that child status does not automatically roll into the parent.",
        "The response explains that the Interactive Process stays open only while the parent workflow runs.",
        "The response requires bounded waits or status checks instead of unbounded polling.",
        "The response recommends external correlation or status storage for long-running orchestration."
      ],
      "checks": [
        {
          "text": "Explains asynchronous child executions",
          "type": "regex",
          "pattern": "asynchronous|independent execution|separate execution"
        },
        {
          "text": "Rejects automatic status roll-up",
          "type": "regex",
          "pattern": "does\\s*\\**n[o']*t\\** (automatically )?roll|n[o']?t roll up|not rolled|no automatic|does\\s*n[o']*t propagate"
        },
        {
          "text": "Ties the interactive process to the parent lifetime",
          "type": "regex",
          "pattern": "parent.{0,80}(open|running)|while its? (owning )?parent"
        },
        {
          "text": "Requires bounded waits",
          "type": "regex",
          "pattern": "bounded|timeout|unbounded polling"
        },
        {
          "text": "Recommends external correlation for long orchestration",
          "type": "regex",
          "pattern": "correlation|external status"
        }
      ]
    },
    {
      "id": "mfa-route-404-escalation",
      "skill_path": "core/teams/workflows/skills/isc-workflows-developer",
      "prompt": "`POST /v3/mfa/token/send` returns 404 from my workflow HTTP action in two different tenants. In the browser network tab I found `/gov-multi-auth/mfa-v3/public/token/send`, which works when I am signed in. Should I call that route from the workflow instead?",
      "expected_output": "Declines the internal browser route, verifies the documented route against the current OpenAPI, and escalates a route-level 404 with tenant routing details.",
      "assertions": [
        "The response declines to use the internal browser route from a workflow.",
        "The response explains that the browser route belongs to a stateful session-dependent flow.",
        "The response verifies the documented route and expected authentication error statuses against the current specification.",
        "The response escalates with tenant, region, environment, and execution details instead of substituting an endpoint."
      ],
      "checks": [
        {
          "text": "Declines the internal route",
          "type": "regex",
          "pattern": "do not (use|call)|not (a )?supported|should not (use|call)|avoid"
        },
        {
          "text": "Explains the stateful session dependency",
          "type": "regex",
          "pattern": "stateful|password[- ]reset|session|JPT"
        },
        {
          "text": "Verifies the documented route",
          "type": "regex",
          "pattern": "OpenAPI|current (API )?spec|specification"
        },
        {
          "text": "Escalates with tenant routing details",
          "type": "regex",
          "pattern": "escalat|tracking ID|org.{0,30}region|gateway"
        }
      ]
    }
  ],
  "_notes": "Cases 1-10 are full-workflow reviews from the original suite. Field learnings collected 2026-08-18 through 2026-09-11 from SailPoint Slack threads, developer community posts, and product documentation. Each case encodes a failure mode observed when the skill lacked the rule."
}
