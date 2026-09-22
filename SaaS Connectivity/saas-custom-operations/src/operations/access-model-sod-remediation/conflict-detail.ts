import { ISC_STRING_ATTRIBUTE_MAX_LENGTH } from '../../framework/attribute-limits'
import { buildIscUiUrl } from '../../lib/sod-form-html'
import { AccessItemViolation } from './detect-violations'
import { ExpandedAccessItemEntitlements } from './expand-access-item-entitlements'

export interface AccessModelSodConflictDetail {
    'access-model-sod-remediation:access-item-id': string
    'access-model-sod-remediation:access-item-type': string
    'access-model-sod-remediation:access-item-name': string
    'access-model-sod-remediation:policy-id': string
    'access-model-sod-remediation:policy-name': string
    'access-model-sod-remediation:access-item-url'?: string
    'access-model-sod-remediation:policy-url'?: string
    'access-model-sod-remediation:recipient-id': string
    'access-model-sod-remediation:conflicting-entitlements-group-a': string
    'access-model-sod-remediation:conflicting-entitlements-group-b': string
}

export interface BuildConflictDetailParams {
    violation: AccessItemViolation
    expanded: ExpandedAccessItemEntitlements
    recipientId: string
    uiOrigin?: string
    maxLength?: number
}

function entitlementNames(ids: string[], expanded: ExpandedAccessItemEntitlements): string[] {
    return ids.map((id) => expanded.entitlements.find((entitlement) => entitlement.id === id)?.name ?? id)
}

/**
 * Plain text for one policy side, read by an interactive panel and by people. Each side is its own
 * attribute so a panel can column them, and each gets the full ISC ceiling rather than half of it.
 */
export function buildSideEntitlements(
    ids: string[],
    expanded: ExpandedAccessItemEntitlements,
    maxLength: number = ISC_STRING_ATTRIBUTE_MAX_LENGTH
): string {
    const names = entitlementNames(ids, expanded)
    if (names.length === 0) {
        return 'none'
    }

    const kept: string[] = []
    for (const name of names) {
        const remaining = names.length - kept.length - 1
        const suffix = remaining > 0 ? ` +${remaining} more` : ''
        if (`${[...kept, name].join(', ')}${suffix}`.length > maxLength) {
            break
        }
        kept.push(name)
    }

    // A single name too long for the ceiling leaves nothing to show but the size of the side.
    if (kept.length === 0) {
        return `${names.length} ${names.length === 1 ? 'entitlement' : 'entitlements'}`
    }

    const dropped = names.length - kept.length
    return `${kept.join(', ')}${dropped > 0 ? ` +${dropped} more` : ''}`
}

/** Descriptive attributes persisted on a conflict's child account, from data the scan already holds. */
export function buildConflictDetail(params: BuildConflictDetailParams): AccessModelSodConflictDetail {
    const { violation, expanded, recipientId, uiOrigin, maxLength } = params
    const accessItemKind = violation.accessItem.type === 'ROLE' ? 'role' : 'accessProfile'

    return {
        'access-model-sod-remediation:access-item-id': violation.accessItem.id,
        'access-model-sod-remediation:access-item-type': violation.accessItem.type,
        'access-model-sod-remediation:access-item-name': violation.accessItem.name ?? violation.accessItem.id,
        'access-model-sod-remediation:policy-id': violation.policy.id,
        'access-model-sod-remediation:policy-name': violation.policy.name ?? violation.policy.id,
        ...(uiOrigin
            ? {
                  'access-model-sod-remediation:access-item-url': buildIscUiUrl(
                      uiOrigin,
                      accessItemKind,
                      violation.accessItem.id
                  ),
                  'access-model-sod-remediation:policy-url': buildIscUiUrl(uiOrigin, 'sodPolicy', violation.policy.id),
              }
            : {}),
        'access-model-sod-remediation:recipient-id': recipientId,
        'access-model-sod-remediation:conflicting-entitlements-group-a': buildSideEntitlements(
            violation.groupAIds,
            expanded,
            maxLength
        ),
        'access-model-sod-remediation:conflicting-entitlements-group-b': buildSideEntitlements(
            violation.groupBIds,
            expanded,
            maxLength
        ),
    }
}
