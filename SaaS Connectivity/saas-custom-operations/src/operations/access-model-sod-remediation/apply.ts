import { ConnectorError } from '@sailpoint/connector-sdk'
import { isOfflineContext, RequestContext } from '../../framework'
import { findFormDefinitionIdByName, getFormInstanceByDefinitionAndId } from '../../isc/forms'
import { CatalogAccessItem } from '../../isc/roles'
import { expandAccessItemEntitlements } from './expand-access-item-entitlements'
import { applyCorrection, buildAuditLineForPlan } from './apply-correction'
import { buildCorrectionPlan, isCorrectionPlanEmpty } from './build-correction-plan'
import {
    applyCorrectionOffline,
    expandAccessItemEntitlementsFromOfflineState,
    getFormInstanceByIdOffline,
} from './apply-offline-data'
import { applyPersistIdentity } from './constants'
import { AccessModelSodApplyOutput } from './apply-outputs'
import { parseFormInstance } from './parse-form-instance'
import { readPriorTerminalApplyOutputs } from './prior-apply-status'

function buildOutputs(
    status: 'applied' | 'skipped-already-clean' | 'skipped-already-applied',
    parsed: ReturnType<typeof parseFormInstance>,
    plan: ReturnType<typeof buildCorrectionPlan>,
    auditLine?: string
): AccessModelSodApplyOutput {
    return {
        'access-model-sod-remediation-apply:status': status,
        'access-model-sod-remediation-apply:access-item-id': parsed.accessItemId,
        'access-model-sod-remediation-apply:access-item-type': parsed.accessItemType,
        ...(plan.removedEntitlementIds.length > 0
            ? { 'access-model-sod-remediation-apply:removed-entitlement-ids': plan.removedEntitlementIds }
            : {}),
        ...(plan.detachedAccessProfileIds.length > 0
            ? {
                  'access-model-sod-remediation-apply:detached-access-profile-ids': plan.detachedAccessProfileIds,
              }
            : {}),
        ...(auditLine ? { 'access-model-sod-remediation-apply:description-appended': auditLine } : {}),
    }
}

/**
 * Applies a completed access-model SoD remediation form decision to the ISC catalog.
 * Invoked when `formInstanceId` is set on `custom:access-model-sod-remediation`.
 */
export async function runAccessModelSodApply(
    ctx: RequestContext<AccessModelSodApplyOutput>,
    input: { formInstanceId: string; formName: string }
): Promise<void> {
    const formInstanceId = input.formInstanceId?.trim()
    if (!formInstanceId) {
        throw new ConnectorError('Missing required input field: formInstanceId')
    }

    const formName = input.formName?.trim()
    if (!formName) {
        throw new ConnectorError('Missing required input field: formName')
    }

    const offline = isOfflineContext(ctx)

    if (!offline) {
        const priorOutputs = await readPriorTerminalApplyOutputs(ctx, ctx.requestId, formInstanceId)
        if (priorOutputs) {
            await ctx.persist(applyPersistIdentity(ctx.requestId, formInstanceId), priorOutputs)
            ctx.res.send({ status: 'success', ...priorOutputs })
            return
        }
    }

    let instance
    if (offline) {
        instance = getFormInstanceByIdOffline(formInstanceId)
    } else {
        const formDefinitionId = await findFormDefinitionIdByName(ctx.sdk.forms, formName)
        instance = await getFormInstanceByDefinitionAndId(ctx.sdk.forms, formDefinitionId, formInstanceId)
    }

    const parsed = parseFormInstance(instance)

    const catalogItem: CatalogAccessItem = {
        id: parsed.accessItemId,
        name: parsed.accessItemId,
        type: parsed.accessItemType,
    }

    const expanded = offline
        ? expandAccessItemEntitlementsFromOfflineState(catalogItem)
        : await expandAccessItemEntitlements(
              { roles: ctx.sdk.roles, accessProfiles: ctx.sdk.accessProfiles },
              catalogItem
          )

    const plan = buildCorrectionPlan(parsed, expanded)
    const alreadyClean = isCorrectionPlanEmpty(plan)

    let auditLine: string | undefined
    if (!alreadyClean) {
        auditLine = buildAuditLineForPlan(parsed, plan)
        if (offline) {
            applyCorrectionOffline(plan, auditLine)
        } else {
            await applyCorrection(
                { roles: ctx.sdk.roles, accessProfiles: ctx.sdk.accessProfiles },
                parsed,
                plan,
                auditLine
            )
        }
    }

    const status = alreadyClean ? 'skipped-already-clean' : 'applied'
    const outputs = buildOutputs(status, parsed, plan, auditLine)

    await ctx.persist(applyPersistIdentity(ctx.requestId, formInstanceId), outputs)
    ctx.res.send({ status: 'success', ...outputs })
}
