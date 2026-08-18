import { findAccountOnSource } from '../../isc/accounts'
import { RequestContext } from '../../framework/types'
import type { AccessModelSodRemediationApplyOperation } from './index'

const STATUS_FIELD = 'access-model-sod-remediation-apply:status'
const ACCESS_ITEM_ID_FIELD = 'access-model-sod-remediation-apply:access-item-id'
const ACCESS_ITEM_TYPE_FIELD = 'access-model-sod-remediation-apply:access-item-type'
const REMOVED_ENTITLEMENTS_FIELD = 'access-model-sod-remediation-apply:removed-entitlement-ids'
const DETACHED_APS_FIELD = 'access-model-sod-remediation-apply:detached-access-profile-ids'
const DESCRIPTION_FIELD = 'access-model-sod-remediation-apply:description-appended'

const PRIOR_TERMINAL_APPLY_STATUSES = new Set(['applied', 'skipped-already-applied'])

function readStringArray(value: unknown): string[] | undefined {
    if (value == null) {
        return undefined
    }
    if (Array.isArray(value)) {
        return value.map(String)
    }
    if (typeof value === 'string') {
        try {
            const parsed = JSON.parse(value)
            return Array.isArray(parsed) ? parsed.map(String) : undefined
        } catch {
            return undefined
        }
    }
    return undefined
}

/** Returns skip outputs when a prior terminal apply persist exists for the form instance. */
export async function readPriorTerminalApplyOutputs(
    ctx: RequestContext<AccessModelSodRemediationApplyOperation['output']>,
    formInstanceId: string
): Promise<AccessModelSodRemediationApplyOperation['output'] | undefined> {
    const account = await findAccountOnSource(ctx.sdk.accounts, ctx.sourceId, formInstanceId)
    const attrs = account?.attributes as Record<string, unknown> | undefined
    if (!attrs) {
        return undefined
    }

    const priorStatus = attrs[STATUS_FIELD]
    if (typeof priorStatus !== 'string' || !PRIOR_TERMINAL_APPLY_STATUSES.has(priorStatus)) {
        return undefined
    }

    const accessItemId = attrs[ACCESS_ITEM_ID_FIELD]
    const accessItemType = attrs[ACCESS_ITEM_TYPE_FIELD]
    if (typeof accessItemId !== 'string' || typeof accessItemType !== 'string') {
        return undefined
    }

    const outputs: AccessModelSodRemediationApplyOperation['output'] = {
        'access-model-sod-remediation-apply:status': 'skipped-already-applied',
        'access-model-sod-remediation-apply:access-item-id': accessItemId,
        'access-model-sod-remediation-apply:access-item-type': accessItemType,
    }

    const removedEntitlementIds = readStringArray(attrs[REMOVED_ENTITLEMENTS_FIELD])
    if (removedEntitlementIds?.length) {
        outputs['access-model-sod-remediation-apply:removed-entitlement-ids'] = removedEntitlementIds
    }

    const detachedAccessProfileIds = readStringArray(attrs[DETACHED_APS_FIELD])
    if (detachedAccessProfileIds?.length) {
        outputs['access-model-sod-remediation-apply:detached-access-profile-ids'] = detachedAccessProfileIds
    }

    const descriptionAppended = attrs[DESCRIPTION_FIELD]
    if (typeof descriptionAppended === 'string' && descriptionAppended.length > 0) {
        outputs['access-model-sod-remediation-apply:description-appended'] = descriptionAppended
    }

    return outputs
}
