import { ConnectorError } from '@sailpoint/connector-sdk'

export interface AccessProfileOwnerRef {
    type?: string
    id?: string
    name?: string
}

/** Returns access profile owner identity id when owner.type is IDENTITY or omitted. */
export function resolveAccessProfileOwnerId(
    accessProfileId: string,
    owner: AccessProfileOwnerRef | undefined
): string {
    if (!owner?.id) {
        throw new ConnectorError(`Access profile ${accessProfileId} has no owner.id`)
    }

    if (owner.type && owner.type.toUpperCase() !== 'IDENTITY') {
        throw new ConnectorError(
            `Access profile ${accessProfileId} owner type ${owner.type} is not supported for form recipient (IDENTITY required)`
        )
    }

    return owner.id
}
