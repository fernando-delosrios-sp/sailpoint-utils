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
import { AccessItemViolation, detectAccessItemViolations } from './detect-violations'
import { buildConflictDetail } from './conflict-detail'
import { buildRefreshedChildAttributes, storedRecipientId } from './refresh-child-detail'
import { ExpandedAccessItemEntitlements, expandAccessItemEntitlements } from './expand-access-item-entitlements'
import {
    ensureAccessModelSodFormDefinition,
    launchAccessModelSodRemediationForm,
    resolveRemediationSectionLabel,
} from './form-service'
import { buildFormEmailBody, buildFormEmailHeader } from './form-email'
import { buildGroupContentsHtml } from './group-html'
import { buildSituationSummaryHtml } from './situation-summary'
import { expandAccessItemEntitlementsOffline } from './offline-data'
import { accessModelSodRemediationOperationSchema } from './index.schema'
import { FormNotification, toPersistAttributes } from '../../lib/form-notification'
import { renderTypeTag, resolveUiOrigin } from '../../lib/sod-form-html'
import { AccessModelSodSkippedFormInstance, buildSkippedFormInstance } from './skipped-form-instance'

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
        'access-model-sod-remediation:access-item-id'?: string
        'access-model-sod-remediation:access-item-type'?: string
        'access-model-sod-remediation:access-item-name'?: string
        'access-model-sod-remediation:policy-id'?: string
        'access-model-sod-remediation:policy-name'?: string
        'access-model-sod-remediation:access-item-url'?: string
        'access-model-sod-remediation:policy-url'?: string
        'access-model-sod-remediation:recipient-id'?: string
        'access-model-sod-remediation:conflicting-entitlements-group-a'?: string
        'access-model-sod-remediation:conflicting-entitlements-group-b'?: string
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

// Persist keys are assembled in toPersistAttributes / buildConflictDetail / the skip refresh, not inline.
// persist-dynamic: access-model-sod-remediation:form-url
// persist-dynamic: access-model-sod-remediation:form-email-header
// persist-dynamic: access-model-sod-remediation:form-email-body
// persist-dynamic: access-model-sod-remediation:form-email-recipients
// persist-dynamic: access-model-sod-remediation:access-item-id
// persist-dynamic: access-model-sod-remediation:access-item-type
// persist-dynamic: access-model-sod-remediation:access-item-name
// persist-dynamic: access-model-sod-remediation:policy-id
// persist-dynamic: access-model-sod-remediation:policy-name
// persist-dynamic: access-model-sod-remediation:access-item-url
// persist-dynamic: access-model-sod-remediation:policy-url
// persist-dynamic: access-model-sod-remediation:recipient-id
// persist-dynamic: access-model-sod-remediation:conflicting-entitlements-group-a
// persist-dynamic: access-model-sod-remediation:conflicting-entitlements-group-b

type AccessModelSodRemediationContext = RequestContext<
    AccessModelSodRemediationOperation['output'],
    AccessModelSodRemediationOperation['response']
>

function validateSearchIndices(indices: string[] | undefined): SearchIndex[] {
    const resolved = indices ?? [...DEFAULT_SEARCH_INDICES]
    for (const index of resolved) {
        if (!VALID_SEARCH_INDICES.has(index)) {
            throw new ConnectorError(`Invalid searchIndices value "${index}". Allowed values: accessprofiles, roles`)
        }
    }
    return resolved as SearchIndex[]
}

async function discoverAccessItems(
    offline: boolean,
    searchIndices: SearchIndex[],
    scope: string,
    ctx: AccessModelSodRemediationContext
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
    ctx: AccessModelSodRemediationContext
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
        const uiOrigin = offline ? undefined : resolveUiOrigin(ctx.apiUrl)

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

        const resolveOwnerId = async (accessItem: CatalogAccessItem): Promise<string> => {
            const cached = ownerIdByAccessItemId.get(accessItem.id)
            if (cached !== undefined) {
                return cached
            }

            const resolved = offline
                ? resolveCatalogAccessItemOwnerIdOffline(accessItem)
                : await resolveCatalogAccessItemOwnerId(
                      { roles: ctx.sdk.roles, accessProfiles: ctx.sdk.accessProfiles },
                      accessItem
                  )
            ownerIdByAccessItemId.set(accessItem.id, resolved)
            return resolved
        }

        /**
         * A skipped conflict keeps its form and its owner email, but its description is rewritten from
         * this scan so a record written before the detail existed, or before a rename, stops being wrong.
         */
        const refreshExistingChild = async (
            childId: string,
            existing: { attributes: Record<string, unknown> },
            violation: AccessItemViolation,
            expanded: ExpandedAccessItemEntitlements
        ): Promise<void> => {
            let recipientId = storedRecipientId(existing.attributes) ?? ''
            try {
                recipientId = await resolveOwnerId(violation.accessItem)
            } catch (error) {
                ctx.log.warn('access-model-sod-remediation owner lookup failed on refresh', {
                    accessItemId: violation.accessItem.id,
                    detail: error instanceof Error ? error.message : String(error),
                })
            }

            const detail = buildConflictDetail({ violation, expanded, recipientId, uiOrigin })
            await ctx.persist(childId, buildRefreshedChildAttributes(existing.attributes, detail), undefined, {
                verify: false,
            })
        }

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
                    ctx.log.info(
                        'access-model-sod-remediation skipping violation: child persist account already exists',
                        {
                            accessItemId: violation.accessItem.id,
                            policyId: violation.policy.id,
                            identityId: childId,
                        }
                    )
                    formsSkipped += 1
                    skippedFormInstances.push(buildSkippedFormInstance(childId, violation))

                    try {
                        await refreshExistingChild(childId, existingChildAccount, violation, expanded)
                    } catch (error) {
                        ctx.log.warn('access-model-sod-remediation child refresh failed', {
                            identityId: childId,
                            detail: error instanceof Error ? error.message : String(error),
                        })
                    }
                    continue
                }

                const formUiOrigin = input.disableLinks === true ? undefined : uiOrigin
                const html = buildGroupContentsHtml(violation.groupAIds, violation.groupBIds, expanded, formUiOrigin)
                const situationSummaryHtml = buildSituationSummaryHtml({
                    uiOrigin: formUiOrigin,
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

                let ownerId: string | undefined
                let ownerEmail: string | undefined
                let formNotification: FormNotification
                try {
                    ownerId = await resolveOwnerId(violation.accessItem)

                    ownerEmail = ownerEmailById.get(ownerId)
                    if (ownerEmail === undefined) {
                        ownerEmail = offline
                            ? resolveIdentityEmailOffline(ownerId)
                            : await resolveIdentityEmail({ apiUrl: ctx.apiUrl, token: ctx.token }, ownerId)
                        ownerEmailById.set(ownerId, ownerEmail)
                    }

                    formNotification = await launchAccessModelSodRemediationForm({
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
                        notification: {
                            emailHeader: buildFormEmailHeader(emailInput),
                            emailBody: ({ formUrl }) => buildFormEmailBody(emailInput, formUrl),
                            emailRecipients: [ownerEmail],
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

                if (ownerEmail === undefined || ownerId === undefined) {
                    continue
                }

                try {
                    await ctx.persist(
                        childId,
                        {
                            ...toPersistAttributes('access-model-sod-remediation', formNotification),
                            ...buildConflictDetail({ violation, expanded, recipientId: ownerId, uiOrigin }),
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
            ...(formsLaunchFailed > 0 ? { 'access-model-sod-remediation:forms-launch-failed': formsLaunchFailed } : {}),
            ...(formsPersistFailed > 0
                ? { 'access-model-sod-remediation:forms-persist-failed': formsPersistFailed }
                : {}),
        })
    },
    { operationSchema: accessModelSodRemediationOperationSchema }
)
