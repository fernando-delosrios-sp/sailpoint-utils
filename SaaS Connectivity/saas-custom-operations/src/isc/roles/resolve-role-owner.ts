import { ConnectorError } from '@sailpoint/connector-sdk'

export interface RoleOwnerRef {
    type?: string
    id?: string
    name?: string
}

/** Returns role owner identity id when owner.type is IDENTITY or omitted. */
export function resolveRoleOwnerId(roleId: string, owner: RoleOwnerRef | undefined): string {
    if (!owner?.id) {
        throw new ConnectorError(`Role ${roleId} has no owner.id`)
    }

    if (owner.type && owner.type.toUpperCase() !== 'IDENTITY') {
        throw new ConnectorError(
            `Role ${roleId} owner type ${owner.type} is not supported for form recipient (IDENTITY required)`
        )
    }

    return owner.id
}
