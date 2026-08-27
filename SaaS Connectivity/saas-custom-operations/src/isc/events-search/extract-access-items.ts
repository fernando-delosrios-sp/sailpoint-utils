import { AccessItemRef, AccessItemRefType, EventSearchDocument } from './types'

const EVENT_TYPE_MAP: Record<string, AccessItemRefType> = {
    Role: 'ROLE',
    AccessProfile: 'ACCESS_PROFILE',
    Entitlement: 'ENTITLEMENT',
    ROLE: 'ROLE',
    ACCESS_PROFILE: 'ACCESS_PROFILE',
    ENTITLEMENT: 'ENTITLEMENT',
}

function normalizeAccessItemType(rawType?: string): AccessItemRefType | undefined {
    if (!rawType) {
        return undefined
    }
    return EVENT_TYPE_MAP[rawType] ?? EVENT_TYPE_MAP[rawType.toUpperCase()]
}

function eventToAccessItem(event: EventSearchDocument): AccessItemRef | undefined {
    const id = event.attributes?.accessItemId
    const type = normalizeAccessItemType(event.attributes?.accessItemType)
    if (!id || !type) {
        return undefined
    }

    return {
        id,
        type,
        name: event.attributes?.accessItemName,
    }
}

/** Extracts deduplicated ENTITLEMENT, ROLE, and ACCESS_PROFILE refs from event documents. */
export function extractAccessItemsFromEvents(events: EventSearchDocument[]): AccessItemRef[] {
    const seen = new Set<string>()
    const items: AccessItemRef[] = []

    for (const event of events) {
        const item = eventToAccessItem(event)
        if (!item) {
            continue
        }
        const key = `${item.type}:${item.id}`
        if (seen.has(key)) {
            continue
        }
        seen.add(key)
        items.push(item)
    }

    return items
}
