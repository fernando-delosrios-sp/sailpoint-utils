import { ConnectorError } from '@sailpoint/connector-sdk'
import { customOperation, isOfflineContext, OperationSignature } from '../../framework'
import { createEntitlementExpansionCache } from '../../isc/sod-prediction'
import { createAccessRiskCatalog } from '../../lib/access-request-risk/catalog'
import { evaluateAccessRisk } from '../../lib/access-request-risk/evaluate'
import { resolveRequestedItems } from '../../lib/access-request-risk/resolve-items'
import { parseConsiderPrivilege } from '../../lib/access-request-risk/tiers'
import { evaluatePreventiveSod } from '../preventive-sod-check/pending-grants'
import { parseInflightOnly, parseRequestedItems, parseWaitForPersist } from '../preventive-sod-check/resolve-input'
import { buildPreventiveSituationSummary } from '../preventive-sod-check/situation-summary'
import { evaluateAccessRequestOperationSchema } from './index.schema'

export interface EvaluateAccessRequestOperation extends OperationSignature {
    command: 'custom:evaluate-access-request'
    input: {
        accessRequestId?: string
        identityId?: string
        /** ISC collapses a single-element `$.trigger.requestedItems` to a bare object on invoke. */
        requestedItems?:
            | Array<{ id?: string; type?: string; name?: string }>
            | { id?: string; type?: string; name?: string }
            | string
        considerPrivilege?: boolean | string
        inflightOnly?: boolean | string
        /**
         * Defaults to true. Set false to skip risk scoring; risk attributes are then omitted
         * from the audit account and the invoke summary.
         */
        evaluateRisk?: boolean | string
        /**
         * Defaults to false. Set true to run preventive SoD; SoD attributes are then included
         * on the audit account and the invoke summary. Requires identityId.
         */
        evaluateSod?: boolean | string
        /**
         * Defaults to true. Set false to submit the audit account write without polling its
         * provisioning task or indexed account.
         */
        waitForPersist?: boolean | string
    }
    output: {
        'evaluate-access-request-risk:tier': string
        'evaluate-access-request-risk:situation-summary': string
        'evaluate-access-request-risk:contributing-ids': string
        'preventive-sod-check:has-violation': boolean
        'preventive-sod-check:situation-summary': string
        'preventive-sod-check:violated-policy-names': string[]
    }
    response: {
        tier?: string
        situationSummary?: string
        contributingIds?: string
        hasViolation?: boolean
        sodSituationSummary?: string
        violatedPolicyNames?: string[]
    }
}

/**
 * Scores access-request risk and/or preventive SoD in one invoke.
 * Risk is on by default; SoD is off unless evaluateSod is true. Enabled checks run concurrently
 * and share an entitlement expansion cache. waitForPersist defaults to true.
 */
export const evaluateAccessRequestOperation = customOperation<EvaluateAccessRequestOperation>(
    async (ctx, input) => {
        const offline = isOfflineContext(ctx)
        const clientConfig = offline ? null : { apiUrl: ctx.apiUrl, token: ctx.token }
        const considerPrivilege = parseConsiderPrivilege(input.considerPrivilege)
        const inflightOnly = parseInflightOnly(input.inflightOnly)
        const evaluateRisk = parseConsiderPrivilege(input.evaluateRisk)
        const evaluateSod = parseInflightOnly(input.evaluateSod)
        const waitForPersist = parseWaitForPersist(input.waitForPersist)
        const accessRequestId = input.accessRequestId?.trim() || undefined
        const identityId = input.identityId?.trim()
        const requestedItems = parseRequestedItems(input.requestedItems)

        if (!evaluateRisk && !evaluateSod) {
            throw new ConnectorError('At least one of evaluateRisk or evaluateSod must be true')
        }
        if (evaluateSod && !identityId) {
            throw new ConnectorError('Missing required input: identityId')
        }

        const expansion = offline ? undefined : createEntitlementExpansionCache(ctx.sdk)
        const catalog = evaluateRisk ? createAccessRiskCatalog(offline, ctx.sdk, expansion) : undefined
        const started = Date.now()

        const riskItems = evaluateRisk
            ? await resolveRequestedItems(ctx.sdk.accessRequests, {
                  accessRequestId,
                  requestedItems: input.requestedItems,
              })
            : []

        const [risk, sodEvaluation] = await Promise.all([
            evaluateRisk && catalog
                ? evaluateAccessRisk(riskItems, catalog, { considerPrivilege })
                : Promise.resolve(undefined),
            evaluateSod && identityId
                ? evaluatePreventiveSod(ctx.sdk, identityId, accessRequestId, offline, clientConfig, {
                      inflightOnly,
                      requestedItems,
                      expansion,
                  })
                : Promise.resolve(undefined),
        ])

        const sodSituationSummary = sodEvaluation
            ? buildPreventiveSituationSummary({
                  violatedPolicies: sodEvaluation.violatedPolicies,
                  accessRequestId,
              })
            : undefined

        ctx.log.info(
            `[evaluate-access-request] evaluations complete elapsedMs=${
                Date.now() - started
            } evaluateRisk=${evaluateRisk} evaluateSod=${evaluateSod} tier=${risk?.tier ?? 'skipped'} hasViolation=${
                sodEvaluation ? sodEvaluation.hasViolation : 'skipped'
            }`
        )

        const summary: EvaluateAccessRequestOperation['response'] = {}
        if (risk) {
            summary.tier = risk.tier
            summary.situationSummary = risk.situationSummary
            summary.contributingIds = risk.contributingIds
        }
        if (sodEvaluation && sodSituationSummary !== undefined) {
            summary.hasViolation = sodEvaluation.hasViolation
            summary.sodSituationSummary = sodSituationSummary
            summary.violatedPolicyNames = sodEvaluation.violatedPolicyNames
        }

        await ctx.persist(
            ctx.requestId,
            {
                'evaluate-access-request-risk:tier': risk?.tier,
                'evaluate-access-request-risk:situation-summary': risk?.situationSummary,
                'evaluate-access-request-risk:contributing-ids': risk?.contributingIds,
                'preventive-sod-check:has-violation': sodEvaluation?.hasViolation,
                'preventive-sod-check:situation-summary': sodSituationSummary,
                'preventive-sod-check:violated-policy-names': sodEvaluation?.violatedPolicyNames,
            },
            undefined,
            waitForPersist ? undefined : { verify: false, waitForCompletion: false }
        )

        ctx.respond(summary)
    },
    { operationSchema: evaluateAccessRequestOperationSchema }
)
