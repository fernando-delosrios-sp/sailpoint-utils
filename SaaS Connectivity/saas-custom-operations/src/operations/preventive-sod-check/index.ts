import { customOperation, isOfflineContext, OperationSignature } from '../../framework'
import { preventiveSodCheckOperationSchema } from './index.schema'
import { evaluatePreventiveSod } from './pending-grants'
import { resolvePreventiveSodCheckInput } from './resolve-input'
import { buildPreventiveSituationSummary } from './situation-summary'

export interface PreventiveSodCheckOperation extends OperationSignature {
    command: 'custom:preventive-sod-check'
    input: {
        identityId?: string
        accessRequestId?: string
    }
    output: {
        'preventive-sod-check:has-violation': boolean
        'preventive-sod-check:situation-summary': string
        'preventive-sod-check:violated-policy-names': string[]
    }
}

/** Evaluates executing GRANT_ACCESS requests and persists preventive SoD summary outputs. */
export const preventiveSodCheckOperation = customOperation<PreventiveSodCheckOperation>(
    async (ctx, input) => {
        const offline = isOfflineContext(ctx)
        const clientConfig = offline ? null : { apiUrl: ctx.apiUrl, token: ctx.token }

        const resolved = await resolvePreventiveSodCheckInput(ctx.requestId, ctx.sdk, input, offline)

        const evaluation = await evaluatePreventiveSod(
            ctx.sdk,
            resolved.identityId,
            resolved.accessRequestId,
            offline,
            clientConfig
        )
        const situationSummary = buildPreventiveSituationSummary({
            violatedPolicyNames: evaluation.violatedPolicyNames,
            accessRequestId: resolved.accessRequestId,
        })

        await ctx.persist(ctx.requestId, {
            'preventive-sod-check:has-violation': evaluation.hasViolation,
            'preventive-sod-check:situation-summary': situationSummary,
            'preventive-sod-check:violated-policy-names': evaluation.violatedPolicyNames,
        })

        ctx.res.send({ status: 'success' })
    },
    { operationSchema: preventiveSodCheckOperationSchema }
)
