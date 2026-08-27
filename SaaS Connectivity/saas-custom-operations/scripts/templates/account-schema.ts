import { RESERVED_OUTPUT_KEYS } from '../../src/framework/output-schema'
import { buildBaseAccountSchema } from '../../src/framework/base-account-schema'
import { IscAttributeType } from '../../src/framework/schema-inference'
import { OperationMeta } from './types'

export interface IscAttribute {
    name: string
    nativeName: null
    type: IscAttributeType
    schema: null
    description: string | null
    isMulti: boolean
    isEntitlement: false
    isGroup: false
    isManaged: false
}

export interface IscAccountSchema {
    name: string
    nativeObjectType: string
    identityAttribute: string
    displayAttribute: string
    hierarchyAttribute: null
    includePermissions: false
    features: []
    configuration: Record<string, never>
    attributes: IscAttribute[]
}

/** Builds an ISC account schema from registered operation output fields. */
export function buildAccountSchema(operations: OperationMeta[]): IscAccountSchema {
    const outputFields = operations.flatMap((op) =>
        op.output.map((field) => ({
            name: field.name,
            type: field.type,
            optional: field.optional,
        }))
    )

    const payload = buildBaseAccountSchema(outputFields)

    return {
        name: payload.name ?? 'account',
        nativeObjectType: payload.nativeObjectType ?? 'User',
        identityAttribute: payload.identityAttribute ?? 'id',
        displayAttribute: payload.displayAttribute ?? 'id',
        hierarchyAttribute: null,
        includePermissions: false,
        features: [],
        configuration: {},
        attributes: (payload.attributes ?? []).map((attr) => ({
            name: attr.name ?? '',
            nativeName: null,
            type: (attr.type ?? 'STRING') as IscAttributeType,
            schema: null,
            description: attr.description ?? null,
            isMulti: attr.isMulti ?? false,
            isEntitlement: false,
            isGroup: false,
            isManaged: false,
        })),
    }
}
