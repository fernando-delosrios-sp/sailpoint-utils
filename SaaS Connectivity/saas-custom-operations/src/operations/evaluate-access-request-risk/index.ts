import { customOperation, isOfflineContext, OperationSignature } from '../../framework'
import { createAccessRiskCatalog } from './catalog'
import { riskPersistIdentity } from './constants'
import { evaluateAccessRisk } from './evaluate'
import { evaluateAccessRequestRiskOperationSchema } from './index.schema'
import { resolveRequestedItems } from './resolve-items'
import { parseConsiderPrivilege } from './tiers'

export interface EvaluateAccessRequestRiskOperation extends OperationSignature {
    command: 'custom:evaluate-access-request-risk'
    input: {
        accessRequestId?: string
        /** ISC collapses a single-element `$.trigger.requestedItems` to a bare object on invoke. */
        requestedItems?:
            | Array<{ id?: string; type?: string; name?: string }>
            | { id?: string; type?: string; name?: string }
            | string
        /** When false, entitlement scoring ignores privilegeLevel.effective. Defaults to true. */
        considerPrivilege?: boolean | string
    }
    output: {
        'evaluate-access-request-risk:tier': string
        'evaluate-access-request-risk:situation-summary': string
        'evaluate-access-request-risk:contributing-ids': string
    }
    response: {
        tier: string
    }
}

/** Scores requested access and persists the highest risk tier. Does not choose approvers. */
export const evaluateAccessRequestRiskOperation = customOperation<EvaluateAccessRequestRiskOperation>(
    async (ctx, input) => {
        const offline = isOfflineContext(ctx)
        const considerPrivilege = parseConsiderPrivilege(input.considerPrivilege)
        const items = await resolveRequestedItems(ctx.sdk.accessRequests, input)
        const catalog = createAccessRiskCatalog(offline, ctx.sdk)
        const result = await evaluateAccessRisk(items, catalog, { considerPrivilege })

        await ctx.persist(ctx.resultIdentity, {
            'evaluate-access-request-risk:tier': result.tier,
            'evaluate-access-request-risk:situation-summary': result.situationSummary,
            'evaluate-access-request-risk:contributing-ids': result.contributingIds,
        })
        ctx.respond({ tier: result.tier })
    },
    { operationSchema: evaluateAccessRequestRiskOperationSchema, resultIdentity: riskPersistIdentity }
)
