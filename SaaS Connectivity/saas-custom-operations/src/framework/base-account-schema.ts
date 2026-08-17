import { SchemaAttribute, SchemaPayload } from '../isc/sources'
import { RESERVED_OUTPUT_KEYS } from './output-schema'
import {
    IscAttributeType,
    inferSchemaAttribute,
    InferredSchemaAttribute,
    OperationField,
} from './schema-inference'

const CORE_ATTRIBUTE_NAMES = ['id', 'status', 'date', 'details'] as const

const CORE_ATTRIBUTES: SchemaAttribute[] = [
    { name: 'id', type: 'STRING', isMulti: false },
    { name: 'status', type: 'STRING', isMulti: false },
    { name: 'date', type: 'STRING', isMulti: false },
    { name: 'details', type: 'STRING', isMulti: false },
]

function toAttributeDefinition(attr: InferredSchemaAttribute): SchemaAttribute {
    return {
        name: attr.name,
        nativeName: null,
        type: attr.type,
        schema: null,
        description: attr.name === 'id' ? 'The unique ID for the account' : undefined,
        isMulti: attr.isMulti,
        isEntitlement: false,
        isGroup: false,
    }
}

/** Collects union attribute definitions for a base account schema from operation output fields. */
export function collectBaseSchemaAttributes(outputFields: OperationField[]): Map<string, InferredSchemaAttribute> {
    const required = new Map<string, InferredSchemaAttribute>()

    for (const core of CORE_ATTRIBUTES) {
        required.set(core.name!, {
            name: core.name!,
            type: core.type! as IscAttributeType,
            isMulti: core.isMulti ?? false,
        })
    }

    for (const field of outputFields) {
        if (RESERVED_OUTPUT_KEYS.has(field.name) || field.name === 'details') {
            continue
        }

        const inferred = inferSchemaAttribute(field)
        const existing = required.get(field.name)
        if (existing) {
            required.set(field.name, {
                name: field.name,
                type: existing.type,
                isMulti: existing.isMulti || inferred.isMulti,
            })
            continue
        }

        required.set(field.name, inferred)
    }

    return required
}

/** Builds the base ISC account schema payload from operation output fields. */
export function buildBaseAccountSchema(outputFields: OperationField[]): SchemaPayload {
    const attributesByName = collectBaseSchemaAttributes(outputFields)
    const dynamicNames = [...attributesByName.keys()]
        .filter((name) => !CORE_ATTRIBUTE_NAMES.includes(name as (typeof CORE_ATTRIBUTE_NAMES)[number]))
        .sort((a, b) => a.localeCompare(b))

    const orderedNames = [...CORE_ATTRIBUTE_NAMES, ...dynamicNames]

    return {
        name: 'account',
        nativeObjectType: 'User',
        identityAttribute: 'id',
        displayAttribute: 'id',
        hierarchyAttribute: null,
        includePermissions: false,
        features: [],
        configuration: {},
        attributes: orderedNames.map((name) => toAttributeDefinition(attributesByName.get(name)!)),
    }
}

export { CORE_ATTRIBUTES as BASE_CORE_ATTRIBUTES, toAttributeDefinition as baseSchemaAttributeDefinition }
