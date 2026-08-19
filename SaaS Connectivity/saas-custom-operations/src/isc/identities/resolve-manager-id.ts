function isRecord(value: unknown): value is Record<string, unknown> {
    return typeof value === 'object' && value !== null
}

function readString(value: unknown): string | undefined {
    return typeof value === 'string' && value.trim() !== '' ? value : undefined
}

/**
 * Extracts the manager identity id from common ISC identity document shapes
 * (`manager.id`, `managerRef.id`). Returns undefined when absent.
 */
export function extractManagerId(identityDoc: unknown): string | undefined {
    if (!isRecord(identityDoc)) {
        return undefined
    }

    const manager = identityDoc.manager
    if (isRecord(manager)) {
        const managerId = readString(manager.id)
        if (managerId) {
            const managerType = readString(manager.type)
            if (!managerType || managerType.toUpperCase() === 'IDENTITY') {
                return managerId
            }
        }
    }

    const managerRef = identityDoc.managerRef
    if (isRecord(managerRef)) {
        return readString(managerRef.id)
    }

    return undefined
}
