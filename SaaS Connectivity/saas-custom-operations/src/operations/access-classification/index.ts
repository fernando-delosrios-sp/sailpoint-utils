import { customOperation, isOfflineContext, OperationSignature, RequestContext } from '../../framework'
import { listSodPolicies, type SodPolicySummary } from '../../isc/sod-policies'
import {
    bulkAddTags,
    bulkRemoveTags,
    ensureTag,
    listObjectsByTag,
    type TaggedObjectRef,
    type TaggedObjectType,
} from '../../isc/tagged-objects'
import {
    listViolatingIdentityIdsByPolicyQuery,
    listViolatingIdentityIdsForPolicy,
} from '../../isc/violations'
import { listAccessProfileCatalog, listEntitlementCatalog, listRoleCatalog } from './catalog'
import { ACCESS_ITEM_TYPES, PRIVILEGED_TAG, RISK_TAG, SOD_RECONCILE_TYPES } from './constants'
import { addViolatingIdentities, buildDesiredClassification, type DesiredTagMap } from './desired-tags'
import { accessClassificationOperationSchema } from './index.schema'
import {
    OFFLINE_ACCESS_PROFILES,
    OFFLINE_CURRENT_BY_TAG,
    OFFLINE_ENTITLEMENTS,
    OFFLINE_ROLES,
    OFFLINE_SOD_POLICIES,
    OFFLINE_VIOLATING_IDENTITIES,
} from './offline-data'
import { buildTagDiffs, type TagDiff } from './reconcile'

export interface AccessClassificationOperation extends OperationSignature {
    command: 'custom:access-classification'
    input: Record<string, never>
    output: {
        'access-classification:entitlements-scanned': number
        'access-classification:access-profiles-scanned': number
        'access-classification:roles-scanned': number
        'access-classification:identities-scanned': number
        'access-classification:tags-added': number
        'access-classification:tags-removed': number
        'access-classification:objects-failed': number
        'access-classification:failure-details': string[]
    }
    response: {
        entitlementsScanned?: number
        accessProfilesScanned?: number
        rolesScanned?: number
        identitiesScanned?: number
        tagsAdded?: number
        tagsRemoved?: number
        objectsFailed?: number
    }
}

interface OperationSummary {
    entitlementsScanned: number
    accessProfilesScanned: number
    rolesScanned: number
    identitiesScanned: number
    tagsAdded: number
    tagsRemoved: number
    objectsFailed: number
}

function allowedTypesForTag(tag: string): ReadonlySet<TaggedObjectType> {
    const normalized = tag.trim().toLowerCase()
    if (normalized === PRIVILEGED_TAG || normalized === RISK_TAG) {
        return ACCESS_ITEM_TYPES
    }
    return SOD_RECONCILE_TYPES
}

function remapDesiredTags(desired: DesiredTagMap, aliases: ReadonlyMap<string, string>): DesiredTagMap {
    const remapped: DesiredTagMap = new Map()
    for (const [tag, holders] of desired) {
        const canonical = aliases.get(tag) ?? tag
        const existing = remapped.get(canonical) ?? new Set<string>()
        for (const holder of holders) {
            existing.add(holder)
        }
        remapped.set(canonical, existing)
    }
    return remapped
}

function findAliasSource(aliases: ReadonlyMap<string, string>, canonical: string): string | undefined {
    for (const [source, target] of aliases) {
        if (target === canonical) {
            return source
        }
    }
    return undefined
}

/**
 * Identities currently in violation for tagging:
 * - Open / Mitigated / Reopened violation records (Closed and Remediated are skipped)
 * - plus identities that currently match the policy query (live conflicting access)
 */
async function collectViolatingIdentityIds(
    ctx: RequestContext<
        AccessClassificationOperation['output'],
        AccessClassificationOperation['response']
    >,
    policy: SodPolicySummary
): Promise<string[]> {
    let fromViolations: string[] = []
    try {
        fromViolations = await listViolatingIdentityIdsForPolicy(
            { apiUrl: ctx.apiUrl, token: ctx.token },
            policy.id
        )
    } catch (error) {
        const detail = error instanceof Error ? error.message : String(error)
        ctx.log.warn('Violation list unavailable; falling back to search only', {
            policyId: policy.id,
            error: detail,
        })
    }

    let fromSearch: string[] = []
    try {
        fromSearch = await listViolatingIdentityIdsByPolicyQuery(ctx.sdk.search, policy)
    } catch (error) {
        const detail = error instanceof Error ? error.message : String(error)
        ctx.log.warn('Policy-query search unavailable; using violation list only', {
            policyId: policy.id,
            error: detail,
        })
    }

    const seen = new Set<string>()
    const ids: string[] = []
    for (const id of [...fromViolations, ...fromSearch]) {
        if (seen.has(id)) {
            continue
        }
        seen.add(id)
        ids.push(id)
    }
    return ids
}

/** Classifies access items and identities, then reconciles privileged, risk, and SOD tags. */
export const accessClassificationOperation = customOperation<AccessClassificationOperation>(
    async (ctx, _input) => {
        const offline = isOfflineContext(ctx)

        const catalog = offline
            ? {
                  entitlements: OFFLINE_ENTITLEMENTS,
                  accessProfiles: OFFLINE_ACCESS_PROFILES,
                  roles: OFFLINE_ROLES,
              }
            : {
                  entitlements: await listEntitlementCatalog(ctx.sdk.entitlements),
                  accessProfiles: await listAccessProfileCatalog(ctx.sdk.accessProfiles),
                  roles: await listRoleCatalog(ctx.sdk.roles),
              }

        const policies = offline
            ? OFFLINE_SOD_POLICIES
            : await listSodPolicies(ctx.sdk.sodPolicies, 'state eq "ENFORCED"')

        const classification = buildDesiredClassification(catalog, policies)
        const { desired, managedTags, policiesWithTags } = classification

        const identityIds = new Set<string>()
        for (const policy of policiesWithTags) {
            const tags = (policy.tags ?? []).map((tag) => tag.trim()).filter(Boolean)
            const violators = offline
                ? OFFLINE_VIOLATING_IDENTITIES[policy.id] ?? []
                : await collectViolatingIdentityIds(ctx, policy)
            for (const id of violators) {
                identityIds.add(id)
            }
            addViolatingIdentities(desired, tags, violators)
        }

        // ISC stores tag names case-insensitively (privileged → PRIVILEGED). Remap desired keys
        // to the canonical names returned by ensureTag so reconcile and writes stay consistent.
        const tagAliases = new Map<string, string>()
        if (!offline) {
            for (const tag of managedTags) {
                const canonical = await ensureTag(ctx.sdk.tags, tag)
                tagAliases.set(tag, canonical)
            }
        } else {
            for (const tag of managedTags) {
                tagAliases.set(tag, tag)
            }
        }
        const canonicalDesired = remapDesiredTags(desired, tagAliases)
        const canonicalManaged = new Set(tagAliases.values())

        const currentByTag = new Map<string, TaggedObjectRef[]>()
        for (const tag of canonicalManaged) {
            const current = offline
                ? OFFLINE_CURRENT_BY_TAG[tag] ?? OFFLINE_CURRENT_BY_TAG[findAliasSource(tagAliases, tag) ?? tag] ?? []
                : await listObjectsByTag(ctx.sdk.taggedObjects, tag, allowedTypesForTag(findAliasSource(tagAliases, tag) ?? tag))
            currentByTag.set(tag, current)
        }

        const diffs = buildTagDiffs(canonicalDesired, canonicalManaged, currentByTag, (tag) =>
            allowedTypesForTag(findAliasSource(tagAliases, tag) ?? tag)
        )
        const applyResult = await applyDiffs(ctx, offline, diffs)

        const summary: OperationSummary = {
            entitlementsScanned: classification.entitlementsScanned,
            accessProfilesScanned: classification.accessProfilesScanned,
            rolesScanned: classification.rolesScanned,
            identitiesScanned: identityIds.size,
            tagsAdded: applyResult.tagsAdded,
            tagsRemoved: applyResult.tagsRemoved,
            objectsFailed: applyResult.failures.length,
        }
        const summaryStatus =
            summary.objectsFailed === 0
                ? 'success'
                : summary.tagsAdded > 0 || summary.tagsRemoved > 0
                ? 'partial'
                : 'failed'

        await persistSummary(ctx, summary, applyResult.failures, summaryStatus)
        ctx.respond(summary, summaryStatus === 'failed' ? 'failed' : 'success')
    },
    { operationSchema: accessClassificationOperationSchema }
)

async function applyDiffs(
    ctx: RequestContext<
        AccessClassificationOperation['output'],
        AccessClassificationOperation['response']
    >,
    offline: boolean,
    diffs: readonly TagDiff[]
): Promise<{ tagsAdded: number; tagsRemoved: number; failures: string[] }> {
    let tagsAdded = 0
    let tagsRemoved = 0
    const failures: string[] = []

    for (const diff of diffs) {
        if (diff.toAdd.length > 0) {
            try {
                if (!offline) {
                    await bulkAddTags(ctx.sdk.taggedObjects, diff.toAdd, [diff.tag])
                }
                tagsAdded += diff.toAdd.length
            } catch (error) {
                const detail = error instanceof Error ? error.message : String(error)
                ctx.log.warn('Failed to add tag batch', { tag: diff.tag, error: detail })
                failures.push(`add ${diff.tag}: ${detail}`)
            }
        }
        if (diff.toRemove.length > 0) {
            try {
                if (!offline) {
                    await bulkRemoveTags(ctx.sdk.taggedObjects, diff.toRemove, [diff.tag])
                }
                tagsRemoved += diff.toRemove.length
            } catch (error) {
                const detail = error instanceof Error ? error.message : String(error)
                ctx.log.warn('Failed to remove tag batch', { tag: diff.tag, error: detail })
                failures.push(`remove ${diff.tag}: ${detail}`)
            }
        }
    }

    return { tagsAdded, tagsRemoved, failures }
}

async function persistSummary(
    ctx: RequestContext<
        AccessClassificationOperation['output'],
        AccessClassificationOperation['response']
    >,
    summary: OperationSummary,
    failures: readonly string[],
    status: 'success' | 'partial' | 'failed'
): Promise<void> {
    await ctx.persist(
        ctx.requestId,
        {
            'access-classification:entitlements-scanned': summary.entitlementsScanned,
            'access-classification:access-profiles-scanned': summary.accessProfilesScanned,
            'access-classification:roles-scanned': summary.rolesScanned,
            'access-classification:identities-scanned': summary.identitiesScanned,
            'access-classification:tags-added': summary.tagsAdded,
            'access-classification:tags-removed': summary.tagsRemoved,
            'access-classification:objects-failed': summary.objectsFailed,
            'access-classification:failure-details': [...failures],
        },
        status
    )
}
