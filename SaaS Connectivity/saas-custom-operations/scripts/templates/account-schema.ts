import { RESERVED_OUTPUT_KEYS } from '../../src/framework/output-schema'
import { inferFromTsType, IscAttributeType } from '../../src/framework/schema-inference'
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

function createAttribute(
    name: string,
    type: IscAttributeType,
    isMulti: boolean,
    description: string | null = null
): IscAttribute {
    return {
        name,
        nativeName: null,
        type,
        schema: null,
        description,
        isMulti,
        isEntitlement: false,
        isGroup: false,
        isManaged: false,
    }
}

const CORE_ATTRIBUTES: IscAttribute[] = [
    createAttribute('id', 'STRING', false, 'The unique ID for the account'),
    createAttribute('status', 'STRING', false),
    createAttribute('date', 'STRING', false),
]

/** Builds an ISC account schema from registered operation output fields. */
export function buildAccountSchema(operations: OperationMeta[]): IscAccountSchema {
    const attributeMeta = new Map<string, { type: IscAttributeType; isMulti: boolean }>([
        ['id', { type: 'STRING', isMulti: false }],
        ['status', { type: 'STRING', isMulti: false }],
        ['date', { type: 'STRING', isMulti: false }],
    ])

    for (const op of operations) {
        for (const field of op.output) {
            if (RESERVED_OUTPUT_KEYS.has(field.name)) {
                continue
            }

            const inferred = inferFromTsType(field.type)
            const existing = attributeMeta.get(field.name)
            attributeMeta.set(field.name, {
                type: existing?.type ?? inferred.type,
                isMulti: existing?.isMulti === true || inferred.isMulti,
            })
        }
    }

    const dynamicAttributes = [...attributeMeta.entries()]
        .filter(([name]) => !['id', 'status', 'date'].includes(name))
        .sort(([a], [b]) => a.localeCompare(b))
        .map(([name, meta]) => createAttribute(name, meta.type, meta.isMulti))

    return {
        name: 'account',
        nativeObjectType: 'User',
        identityAttribute: 'id',
        displayAttribute: 'id',
        hierarchyAttribute: null,
        includePermissions: false,
        features: [],
        configuration: {},
        attributes: [...CORE_ATTRIBUTES, ...dynamicAttributes],
    }
}
