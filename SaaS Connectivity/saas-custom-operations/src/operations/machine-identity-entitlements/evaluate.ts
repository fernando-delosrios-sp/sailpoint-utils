import { EntitlementRef } from '../../isc/entitlements'
import { UserEntitlementRef } from '../../isc/machine-identities'

/** Returns the connector attribute selected by the source's native user-entitlements configuration. */
export function userEntitlementsAttributeName(
    source: { connectorAttributes?: Record<string, unknown> } | undefined
): string | undefined {
    if (!source) {
        return undefined
    }
    const raw = source.connectorAttributes?.userEntitlements
    if (typeof raw !== 'string' || !raw.trim()) {
        return undefined
    }
    return raw.trim()
}

/** Normalizes a single- or multi-valued account attribute into trimmed non-blank strings. */
export function extractInboundValues(attributeValue: unknown): string[] {
    if (attributeValue == null) {
        return []
    }
    const values = Array.isArray(attributeValue) ? attributeValue : [attributeValue]
    return values.map((value) => String(value).trim()).filter((value) => value.length > 0)
}

function assignedKey(sourceId: string, entitlementId: string): string {
    return `${sourceId}:${entitlementId}`
}

/** Dedupes matched catalog entitlements and drops refs already on userEntitlements. */
export function entitlementsToAdd(matched: EntitlementRef[], assigned: UserEntitlementRef[]): EntitlementRef[] {
    const alreadyAssigned = new Set(assigned.map((ref) => assignedKey(ref.sourceId, ref.entitlementId)))
    const seenIds = new Set<string>()
    const toAdd: EntitlementRef[] = []

    for (const entitlement of matched) {
        if (seenIds.has(entitlement.id)) {
            continue
        }
        seenIds.add(entitlement.id)
        if (alreadyAssigned.has(assignedKey(entitlement.sourceId, entitlement.id))) {
            continue
        }
        toAdd.push(entitlement)
    }

    return toAdd
}
