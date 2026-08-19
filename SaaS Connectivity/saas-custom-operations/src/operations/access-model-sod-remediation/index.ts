import { ConnectorError } from '@sailpoint/connector-sdk'
import { customOperation, isOfflineContext, OperationSignature, RequestContext } from '../../framework'
import { listEnabledAccessProfiles, listEnabledAccessProfilesOffline } from '../../isc/access-profiles'
import {
    listEnabledRoles,
    listEnabledRolesOffline,
    CatalogAccessItem,
    resolveCatalogAccessItemOwnerId,
    resolveCatalogAccessItemOwnerIdOffline,
} from '../../isc/roles'
import { listSodPolicies, listSodPoliciesOffline, SodPolicySummary } from '../../isc/sod-policies'
import { findAccountOnSource } from '../../isc/accounts'
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
import { ExpandedAccessItemEntitlements, expandAccessItemEntitlements } from './expand-access-item-entitlements'
import {
    createAccessModelSodRemediationInstance,
    ensureAccessModelSodFormDefinition,
    resolveRemediationSectionLabel,
} from './form-service'
import { buildFormEmailBody, buildFormEmailHeader } from './form-email'
import { buildGroupContentsHtml } from './group-html'
import { buildSituationSummaryHtml } from './situation-summary'
import { expandAccessItemEntitlementsOffline } from './offline-data'
import { accessModelSodRemediationOperationSchema } from './index.schema'
import { renderTypeTag, resolveUiOrigin } from '../../lib/sod-form-html'
import {
    AccessModelSodSkippedFormInstance,
    buildSkippedFormInstance,
} from './skipped-form-instance'

export interface AccessModelSodRemediationOperation extends OperationSignature {
    command: 'custom:access-model-sod-remediation'
    input: {
        formName: string
        scope?: string
        searchIndices?: SearchIndex[]
        policyScope?: string
        disableLinks?: boolean
    }
    output: {
        'access-model-sod-remediation:form-url'?: string
        'access-model-sod-remediation:form-email-header'?: string
        'access-model-sod-remediation:form-email-body'?: string
        'access-model-sod-remediation:form-email-recipients'?: string[]
    }
    response: {
        'access-model-sod-remediation:access-items-scanned': number
        'access-model-sod-remediation:violations-found': number
        'access-model-sod-remediation:forms-skipped'?: number
        'access-model-sod-remediation:forms-skipped-instances'?: AccessModelSodSkippedFormInstance[]
        'access-model-sod-remediation:forms-launch-failed'?: number
        'access-model-sod-remediation:forms-persist-failed'?: number
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

    ctx.log.info('discoverAccessItems', {
        offline,
        scope,
        searchIndices,
    })

    if (offline) {
        ctx.log.info('discoverAccessItems using offline fixtures')
        if (searchIndices.includes('roles')) {
            items.push(...listEnabledRolesOffline())
        }
        if (searchIndices.includes('accessprofiles')) {
            items.push(...listEnabledAccessProfilesOffline())
        }
        ctx.log.info('discoverAccessItems offline count', { count: items.length })
        return items
    }

    if (searchIndices.includes('roles')) {
        ctx.log.info('discoverAccessItems listing roles')
        items.push(...(await listEnabledRoles(ctx.sdk.roles, scope, ctx.sdk.search)))
    }
    if (searchIndices.includes('accessprofiles')) {
        ctx.log.info('discoverAccessItems listing access profiles')
        items.push(...(await listEnabledAccessProfiles(ctx.sdk.accessProfiles, scope, ctx.sdk.search)))
    }

    ctx.log.info('discoverAccessItems live count', { count: items.length })
    return items
}

async function loadPolicies(
    offline: boolean,
    policyScope: string,
    ctx: RequestContext<AccessModelSodRemediationOperation['output']>
): Promise<SodPolicySummary[]> {
    ctx.log.info('loadPolicies', { offline, policyScope })

    if (offline) {
        return listSodPoliciesOffline()
    }

    const policies = await listSodPolicies(ctx.sdk.sodPolicies, policyScope)
    ctx.log.info('loadPolicies count', { count: policies.length })
    return policies
}

/** Scans catalog access items for intrinsic SoD violations and launches access-item-owner remediation forms. */
export const accessModelSodRemediationOperation = customOperation<AccessModelSodRemediationOperation>(
    async (ctx, input) => {
        const offline = isOfflineContext(ctx)
        const scope = input.scope ?? DEFAULT_SCOPE
        const searchIndices = validateSearchIndices(input.searchIndices)
        const policyScope = input.policyScope ?? DEFAULT_POLICY_SCOPE

        ctx.log.info('access-model-sod-remediation start', {
            offline,
            apiUrl: ctx.apiUrl || '<empty>',
            scope,
            searchIndices,
        })

        const accessItems = await discoverAccessItems(offline, searchIndices, scope, ctx)
        const policies = await loadPolicies(offline, policyScope, ctx)

        const tokenOwnerId = offline ? 'offline-token-owner' : await resolveTokenIdentity(ctx.token)
        const formDefinitionId = await ensureAccessModelSodFormDefinition(ctx.sdk.forms, input.formName, tokenOwnerId)

        let violationsFound = 0
        let formsSkipped = 0
        const skippedFormInstances: AccessModelSodSkippedFormInstance[] = []
        let formsLaunchFailed = 0
        let formsPersistFailed = 0
        let formsCreated = 0

        const expandedByAccessItemId = new Map<string, ExpandedAccessItemEntitlements>()
        const ownerIdByAccessItemId = new Map<string, string>()
        const ownerEmailById = new Map<string, string>()

        for (const accessItem of accessItems) {
            let expanded = expandedByAccessItemId.get(accessItem.id)
            if (!expanded) {
                expanded = offline
                    ? expandAccessItemEntitlementsOffline(accessItem)
                    : await expandAccessItemEntitlements(
                          { roles: ctx.sdk.roles, accessProfiles: ctx.sdk.accessProfiles },
                          accessItem
                      )
                expandedByAccessItemId.set(accessItem.id, expanded)
            }

            const violations = detectAccessItemViolations(accessItem, expanded, policies)

            for (const violation of violations) {
                violationsFound += 1

                if (formsCreated >= MAX_FORMS_PER_RUN) {
                    ctx.log.warn('access-model-sod-remediation form cap reached; skipping remaining forms', {
                        cap: MAX_FORMS_PER_RUN,
                    })
                    break
                }

                const childId = childPersistIdentity(ctx.requestId, violation.accessItem.id, violation.policy.id)
                const existingChildAccount = offline
                    ? undefined
                    : await findAccountOnSource(ctx.sdk.accounts, ctx.sourceId, childId)

                if (existingChildAccount) {
                    ctx.log.info('access-model-sod-remediation skipping violation: child persist account already exists', {
                        accessItemId: violation.accessItem.id,
                        policyId: violation.policy.id,
                        identityId: childId,
                    })
                    formsSkipped += 1
                    skippedFormInstances.push(buildSkippedFormInstance(childId, violation))
                    continue
                }

                const uiOrigin =
                    offline || input.disableLinks === true ? undefined : resolveUiOrigin(ctx.apiUrl)
                const html = buildGroupContentsHtml(violation.groupAIds, violation.groupBIds, expanded, uiOrigin)
                const situationSummaryHtml = buildSituationSummaryHtml({
                    uiOrigin,
                    accessItemId: violation.accessItem.id,
                    accessItemType: violation.accessItem.type,
                    accessItemName: violation.accessItem.name,
                    policyId: violation.policy.id,
                    policyName: violation.policy.name,
                })
                const emailInput = {
                    accessItem: violation.accessItem,
                    policy: violation.policy,
                    groupAIds: violation.groupAIds,
                    groupBIds: violation.groupBIds,
                }

                let ownerId = ownerIdByAccessItemId.get(violation.accessItem.id)
                let ownerEmail: string | undefined
                let formUrl: string
                try {
                    if (ownerId === undefined) {
                        ownerId = offline
                            ? resolveCatalogAccessItemOwnerIdOffline(violation.accessItem)
                            : await resolveCatalogAccessItemOwnerId(
                                  { roles: ctx.sdk.roles, accessProfiles: ctx.sdk.accessProfiles },
                                  violation.accessItem
                              )
                        ownerIdByAccessItemId.set(violation.accessItem.id, ownerId)
                    }

                    ownerEmail = ownerEmailById.get(ownerId)
                    if (ownerEmail === undefined) {
                        ownerEmail = offline
                            ? resolveIdentityEmailOffline(ownerId)
                            : await resolveIdentityEmail({ apiUrl: ctx.apiUrl, token: ctx.token }, ownerId)
                        ownerEmailById.set(ownerId, ownerEmail)
                    }

                    formUrl = await createAccessModelSodRemediationInstance({
                        forms: ctx.sdk.forms,
                        formDefinitionId,
                        recipientId: ownerId,
                        createdBySourceId: ctx.sourceId,
                        formInput: {
                            parentRequestId: ctx.requestId,
                            accessItemId: violation.accessItem.id,
                            accessItemType: violation.accessItem.type,
                            accessItemTypeTagHtml: renderTypeTag(violation.accessItem.type),
                            remediationSectionLabel: resolveRemediationSectionLabel(violation.accessItem.type),
                            accessItemName: violation.accessItem.name,
                            policyId: violation.policy.id,
                            policyName: violation.policy.name,
                            situationSummaryHtml,
                            groupAIds: violation.groupAIds,
                            groupBIds: violation.groupBIds,
                            ...html,
                        },
                    })
                } catch (error) {
                    formsLaunchFailed += 1
                    const detail = error instanceof Error ? error.message : String(error)
                    ctx.log.warn('access-model-sod-remediation form launch failed', {
                        accessItemId: violation.accessItem.id,
                        policyId: violation.policy.id,
                        detail,
                    })
                    continue
                }

                if (ownerEmail === undefined) {
                    continue
                }

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
                    ctx.log.warn('access-model-sod-remediation child persist failed', {
                        identityId: childId,
                        detail,
                    })
                }

                formsCreated += 1
            }

            if (formsCreated >= MAX_FORMS_PER_RUN) {
                break
            }
        }

        ctx.respond({
            'access-model-sod-remediation:access-items-scanned': accessItems.length,
            'access-model-sod-remediation:violations-found': violationsFound,
            ...(formsSkipped > 0 ? { 'access-model-sod-remediation:forms-skipped': formsSkipped } : {}),
            ...(skippedFormInstances.length > 0
                ? { 'access-model-sod-remediation:forms-skipped-instances': skippedFormInstances }
                : {}),
            ...(formsLaunchFailed > 0
                ? { 'access-model-sod-remediation:forms-launch-failed': formsLaunchFailed }
                : {}),
            ...(formsPersistFailed > 0
                ? { 'access-model-sod-remediation:forms-persist-failed': formsPersistFailed }
                : {}),
        })
    },
    { operationSchema: accessModelSodRemediationOperationSchema }
)
