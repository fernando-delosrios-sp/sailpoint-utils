import { AccessProfilesApi, RolesApi } from 'sailpoint-api-client'
import { patchAccessProfileComposition } from '../../isc/access-profiles/access-profile-patch'
import { patchRoleComposition } from '../../isc/roles/role-patch'
import { CorrectionPlan } from './build-correction-plan'
import { ParsedFormInstance } from './parse-form-instance'
import { buildDescriptionAuditLine } from './description-audit'

export interface ApplyCorrectionClients {
    roles: RolesApi
    accessProfiles: AccessProfilesApi
}

/** Applies a correction plan to the ISC catalog with a single PATCH per access item. */
export async function applyCorrection(
    clients: ApplyCorrectionClients,
    parsed: ParsedFormInstance,
    plan: CorrectionPlan,
    auditLine: string
): Promise<void> {
    if (plan.accessItemType === 'ACCESS_PROFILE') {
        await patchAccessProfileComposition(clients.accessProfiles, plan.accessItemId, {
            removeEntitlementIds: plan.removedEntitlementIds,
            descriptionAppend: auditLine,
        })
        return
    }

    await patchRoleComposition(clients.roles, plan.accessItemId, {
        detachAccessProfileIds: plan.detachedAccessProfileIds,
        removeEntitlementIds: plan.removedEntitlementIds,
        descriptionAppend: auditLine,
    })
}

/** Builds the description audit line from parsed form input and correction plan. */
export function buildAuditLineForPlan(parsed: ParsedFormInstance, plan: CorrectionPlan): string {
    return buildDescriptionAuditLine({
        policyName: parsed.policyName,
        policyId: parsed.policyId,
        remediationSide: parsed.remediationSide,
        formInstanceId: parsed.formInstanceId,
        detachedProfiles: plan.detachedAccessProfileDetails,
        removedEntitlements: plan.removedEntitlementDetails,
        comments: parsed.comments,
        submitterId: parsed.submitterId,
    })
}
