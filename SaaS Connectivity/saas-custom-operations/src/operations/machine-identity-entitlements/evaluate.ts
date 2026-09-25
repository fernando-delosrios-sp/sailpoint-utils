import { SchemaPayload } from '../../isc/sources'
import { EntitlementRef } from '../../isc/entitlements'
import { UserEntitlementRef } from '../../isc/machine-identities'

/** Returns the inbound entitlements attribute name when the schema opts in and the attribute exists. */
export function inboundAttributeName(schema: SchemaPayload | undefined): string | undefined {
    if (!schema) {
        return undefined
    }
    const raw = schema.configuration?.inboundEntitlements
    if (typeof raw !== 'string' || !raw.trim()) {
        return undefined
    }
    const name = raw.trim()
    const present = schema.attributes?.some((attribute) => attribute.name === name)
    return present ? name : undefined
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
