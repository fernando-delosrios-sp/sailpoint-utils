import { ConnectorError } from '@sailpoint/connector-sdk'
import { customOperation, OperationSignature, RequestContext } from '../../framework'
import { listEnabledAccessProfiles, listEnabledAccessProfilesOffline } from '../../isc/access-profiles'
import { listEnabledRoles, listEnabledRolesOffline, CatalogAccessItem } from '../../isc/roles'
import {
    listSodPolicies,
    listSodPoliciesOffline,
    resolvePolicyOwnerId,
    SodPolicySummary,
} from '../../isc/sod-policies'
import { resolveIdentityEmail } from '../../isc/public-identities'
import { resolveIdentityEmailOffline } from '../../isc/public-identities/offline-data'
import { resolveTokenIdentity } from '../../isc/token-identity'
import {
    childPersistIdentity,
    DEFAULT_POLICY_SCOPE,
    DEFAULT_SCOPE,
    DEFAULT_SEARCH_INDICES,
    MAX_FORMS_PER_RUN,
    SearchIndex,
    VALID_SEARCH_INDICES,
} from './constants'
import { detectAccessItemViolations } from './detect-violations'
import { expandAccessItemEntitlements } from './expand-access-item-entitlements'
import {
    createAccessModelSodRemediationInstance,
    ensureAccessModelSodFormDefinition,
    hasAssignedRemediationInstance,
} from './form-service'
import { buildFormEmailBody, buildFormEmailHeader } from './form-email'
import { buildGroupContentsHtml } from './group-html'
import { expandAccessItemEntitlementsOffline } from './offline-data'
import { accessModelSodRemediationOperationSchema } from './index.schema'
import { renderTypeTag } from '../../lib/sod-form-html'

export interface AccessModelSodRemediationOperation extends OperationSignature {
    command: 'custom:access-model-sod-remediation'
    input: {
        formName: string
        scope?: string
        searchIndices?: SearchIndex[]
        policyScope?: string
    }
    output: {
        'access-model-sod-remediation:access-items-scanned': number
        'access-model-sod-remediation:violations-found': number
        'access-model-sod-remediation:forms-skipped'?: number
        'access-model-sod-remediation:forms-persist-failed'?: number
        'access-model-sod-remediation:form-url'?: string
        'access-model-sod-remediation:form-email-header'?: string
        'access-model-sod-remediation:form-email-body'?: string
        'access-model-sod-remediation:form-email-recipients'?: string[]
    }
}

function validateSearchIndices(indices: string[] | undefined): SearchIndex[] {
    const resolved = indices ?? [...DEFAULT_SEARCH_INDICES]
    for (const index of resolved) {
        if (!VALID_SEARCH_INDICES.has(index)) {
            throw new ConnectorError(
                `Invalid searchIndices value "${index}". Allowed values: accessprofiles, roles`
            )
        }
    }
    return resolved as SearchIndex[]
}

async function discoverAccessItems(
    offline: boolean,
    searchIndices: SearchIndex[],
    scope: string,
    ctx: RequestContext<AccessModelSodRemediationOperation['output']>
): Promise<CatalogAccessItem[]> {
    const items: CatalogAccessItem[] = []

    console.log(
        `[access-model-sod-remediation] discoverAccessItems offline=${offline} scope=${JSON.stringify(scope)} indices=${JSON.stringify(searchIndices)}`
    )

    if (offline) {
        console.log('[access-model-sod-remediation] discoverAccessItems using offline fixtures')
        if (searchIndices.includes('roles')) {
            items.push(...listEnabledRolesOffline())
        }
        if (searchIndices.includes('accessprofiles')) {
            items.push(...listEnabledAccessProfilesOffline())
        }
        console.log(`[access-model-sod-remediation] discoverAccessItems offline count=${items.length}`)
        return items
    }

    if (searchIndices.includes('roles')) {
        console.log('[access-model-sod-remediation] discoverAccessItems listing roles')
        items.push(...(await listEnabledRoles(ctx.sdk.roles, scope, ctx.sdk.search)))
    }
    if (searchIndices.includes('accessprofiles')) {
        console.log('[access-model-sod-remediation] discoverAccessItems listing access profiles')
        items.push(...(await listEnabledAccessProfiles(ctx.sdk.accessProfiles, scope, ctx.sdk.search)))
    }

    console.log(`[access-model-sod-remediation] discoverAccessItems live count=${items.length}`)
    return items
}

async function loadPolicies(
    offline: boolean,
    policyScope: string,
    ctx: RequestContext<AccessModelSodRemediationOperation['output']>
): Promise<SodPolicySummary[]> {
    console.log(`[access-model-sod-remediation] loadPolicies offline=${offline} policyScope=${JSON.stringify(policyScope)}`)

    if (offline) {
        return listSodPoliciesOffline()
    }

    const policies = await listSodPolicies(ctx.sdk.sodPolicies, policyScope)
    console.log(`[access-model-sod-remediation] loadPolicies count=${policies.length}`)
    return policies
}

/** Scans catalog access items for intrinsic SoD violations and launches policy-owner remediation forms. */
export const accessModelSodRemediationOperation = customOperation<AccessModelSodRemediationOperation>(
    async (ctx, input) => {
        const offline = !ctx.apiUrl || !ctx.token
        const scope = input.scope ?? DEFAULT_SCOPE
        const searchIndices = validateSearchIndices(input.searchIndices)
        const policyScope = input.policyScope ?? DEFAULT_POLICY_SCOPE

        console.log(
            `[access-model-sod-remediation] start requestId=${ctx.requestId} offline=${offline} apiUrl=${ctx.apiUrl || '<empty>'} scope=${JSON.stringify(scope)} searchIndices=${JSON.stringify(searchIndices)}`
        )

        const accessItems = await discoverAccessItems(offline, searchIndices, scope, ctx)
        const policies = await loadPolicies(offline, policyScope, ctx)

        const tokenOwnerId = offline ? 'offline-token-owner' : await resolveTokenIdentity(ctx.token)
        const formDefinitionId = await ensureAccessModelSodFormDefinition(ctx.sdk.forms, input.formName, tokenOwnerId)

        let violationsFound = 0
        let formsSkipped = 0
        let formsPersistFailed = 0
        let formsCreated = 0

        for (const accessItem of accessItems) {
            const expanded = offline
                ? expandAccessItemEntitlementsOffline(accessItem)
                : await expandAccessItemEntitlements(
                      { roles: ctx.sdk.roles, accessProfiles: ctx.sdk.accessProfiles },
                      accessItem
                  )

            const violations = detectAccessItemViolations(accessItem, expanded, policies)

            for (const violation of violations) {
                violationsFound += 1

                if (formsCreated >= MAX_FORMS_PER_RUN) {
                    console.warn(
                        `[${ctx.requestId}] access-model-sod-remediation form cap ${MAX_FORMS_PER_RUN} reached; skipping remaining forms`
                    )
                    break
                }

                const alreadyAssigned = offline
                    ? false
                    : await hasAssignedRemediationInstance(
                          ctx.sdk.forms,
                          formDefinitionId,
                          violation.accessItem.id,
                          violation.policy.id
                      )

                if (alreadyAssigned) {
                    formsSkipped += 1
                    continue
                }

                const ownerId = resolvePolicyOwnerId(violation.policy)
                const ownerEmail = offline
                    ? resolveIdentityEmailOffline(ownerId)
                    : await resolveIdentityEmail({ apiUrl: ctx.apiUrl, token: ctx.token }, ownerId)
                const html = buildGroupContentsHtml(violation.groupAIds, violation.groupBIds, expanded)
                const emailInput = {
                    accessItem: violation.accessItem,
                    policy: violation.policy,
                    groupAIds: violation.groupAIds,
                    groupBIds: violation.groupBIds,
                }

                const formUrl = await createAccessModelSodRemediationInstance({
                    forms: ctx.sdk.forms,
                    formDefinitionId,
                    recipientId: ownerId,
                    createdBySourceId: ctx.sourceId,
                    formInput: {
                        accessItemId: violation.accessItem.id,
                        accessItemType: violation.accessItem.type,
                        accessItemTypeTagHtml: renderTypeTag(violation.accessItem.type),
                        accessItemName: violation.accessItem.name,
                        policyId: violation.policy.id,
                        policyName: violation.policy.name,
                        groupAIds: violation.groupAIds,
                        groupBIds: violation.groupBIds,
                        ...html,
                    },
                })

                const childId = childPersistIdentity(ctx.requestId, violation.accessItem.id, violation.policy.id)
                try {
                    await ctx.persist(
                        childId,
                        {
                            'access-model-sod-remediation:form-url': formUrl,
                            'access-model-sod-remediation:form-email-header': buildFormEmailHeader(emailInput),
                            'access-model-sod-remediation:form-email-body': buildFormEmailBody(emailInput, formUrl),
                            'access-model-sod-remediation:form-email-recipients': [ownerEmail],
                        },
                        undefined,
                        { verify: false }
                    )
                } catch (error) {
                    formsPersistFailed += 1
                    const detail = error instanceof Error ? error.message : String(error)
                    console.warn(
                        `[${ctx.requestId}] access-model-sod-remediation child persist failed identity=${childId}: ${detail}`
                    )
                }

                formsCreated += 1
            }

            if (formsCreated >= MAX_FORMS_PER_RUN) {
                break
            }
        }

        await ctx.persist(ctx.requestId, {
            'access-model-sod-remediation:access-items-scanned': accessItems.length,
            'access-model-sod-remediation:violations-found': violationsFound,
            ...(formsSkipped > 0 ? { 'access-model-sod-remediation:forms-skipped': formsSkipped } : {}),
            ...(formsPersistFailed > 0
                ? { 'access-model-sod-remediation:forms-persist-failed': formsPersistFailed }
                : {}),
        })

        ctx.res.send({ status: 'success' })
    },
    { operationSchema: accessModelSodRemediationOperationSchema }
)
