import { ConnectorError } from '@sailpoint/connector-sdk'
import { customOperation, isOfflineContext, OperationSignature } from '../../framework'
import { getFormInstanceById } from '../../isc/forms'
import { CatalogAccessItem } from '../../isc/roles'
import { expandAccessItemEntitlements } from '../access-model-sod-remediation/expand-access-item-entitlements'
import { applyCorrection, buildAuditLineForPlan } from './apply-correction'
import { buildCorrectionPlan, isCorrectionPlanEmpty } from './build-correction-plan'
import { accessModelSodRemediationApplyOperationSchema } from './index.schema'
import {
    applyCorrectionOffline,
    expandAccessItemEntitlementsFromOfflineState,
    getFormInstanceByIdOffline,
} from './offline-data'
import { parseFormInstance } from './parse-form-instance'
import { readPriorTerminalApplyOutputs } from './prior-apply-status'

export interface AccessModelSodRemediationApplyOperation extends OperationSignature {
    command: 'custom:access-model-sod-remediation-apply'
    input: {
        formInstanceId: string
    }
    output: {
        'access-model-sod-remediation-apply:status': string
        'access-model-sod-remediation-apply:access-item-id': string
        'access-model-sod-remediation-apply:access-item-type': string
        'access-model-sod-remediation-apply:removed-entitlement-ids'?: string[]
        'access-model-sod-remediation-apply:detached-access-profile-ids'?: string[]
        'access-model-sod-remediation-apply:description-appended'?: string
    }
}

// Persist keys are assembled in buildOutputs / prior-apply helpers (not inline object literals).
// persist-dynamic: access-model-sod-remediation-apply:status
// persist-dynamic: access-model-sod-remediation-apply:access-item-id
// persist-dynamic: access-model-sod-remediation-apply:access-item-type
// persist-dynamic: access-model-sod-remediation-apply:removed-entitlement-ids
// persist-dynamic: access-model-sod-remediation-apply:detached-access-profile-ids
// persist-dynamic: access-model-sod-remediation-apply:description-appended

function buildOutputs(
    status: 'applied' | 'skipped-already-clean' | 'skipped-already-applied',
    parsed: ReturnType<typeof parseFormInstance>,
    plan: ReturnType<typeof buildCorrectionPlan>,
    auditLine?: string
): AccessModelSodRemediationApplyOperation['output'] {
    return {
        'access-model-sod-remediation-apply:status': status,
        'access-model-sod-remediation-apply:access-item-id': parsed.accessItemId,
        'access-model-sod-remediation-apply:access-item-type': parsed.accessItemType,
        ...(plan.removedEntitlementIds.length > 0
            ? { 'access-model-sod-remediation-apply:removed-entitlement-ids': plan.removedEntitlementIds }
            : {}),
        ...(plan.detachedAccessProfileIds.length > 0
            ? {
                  'access-model-sod-remediation-apply:detached-access-profile-ids':
                      plan.detachedAccessProfileIds,
              }
            : {}),
        ...(auditLine ? { 'access-model-sod-remediation-apply:description-appended': auditLine } : {}),
    }
}

/** Applies a completed access-model SoD remediation form decision to the ISC catalog. */
export const accessModelSodRemediationApplyOperation = customOperation<AccessModelSodRemediationApplyOperation>(
    async (ctx, input) => {
        const formInstanceId = input.formInstanceId?.trim()
        if (!formInstanceId) {
            throw new ConnectorError('Missing required input field: formInstanceId')
        }

        const offline = isOfflineContext(ctx)

        if (!offline) {
            const priorOutputs = await readPriorTerminalApplyOutputs(ctx, formInstanceId)
            if (priorOutputs) {
                await ctx.persist(formInstanceId, priorOutputs)
                ctx.res.send({ status: 'success', ...priorOutputs })
                return
            }
        }

        const instance = offline
            ? getFormInstanceByIdOffline(formInstanceId)
            : await getFormInstanceById(ctx.sdk.forms, formInstanceId)

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

        await ctx.persist(formInstanceId, outputs)
        ctx.res.send({ status: 'success', ...outputs })
    },
    { operationSchema: accessModelSodRemediationApplyOperationSchema }
)
