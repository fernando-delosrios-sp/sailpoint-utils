import { readFileSync } from 'node:fs';
import { join } from 'node:path';
import {
  ITEM_TYPES,
  ROOT,
  entitlementNames,
  indexByName,
  loadAllItems,
  loadConfig,
  nameKey,
} from './common.mjs';

const SCHEMAS = {
  [ITEM_TYPES.entitlement]: join(ROOT, 'schemas', 'entitlement.json'),
  [ITEM_TYPES.accessProfile]: join(ROOT, 'schemas', 'access-profile.json'),
  [ITEM_TYPES.role]: join(ROOT, 'schemas', 'role.json'),
};

function loadSchema(type) {
  return JSON.parse(readFileSync(SCHEMAS[type], 'utf8'));
}

function typeOf(value) {
  if (value === null) return 'null';
  if (Array.isArray(value)) return 'array';
  return typeof value;
}

/**
 * Minimal JSON-schema subset validator (type, required, properties, additionalProperties).
 * Keeps the template free of a heavyweight Ajv dependency.
 */
export function validateAgainstSchema(data, schema, path = '$') {
  const errors = [];
  const expectedType = schema.type;
  if (expectedType) {
    const actual = typeOf(data);
    const allowed = Array.isArray(expectedType) ? expectedType : [expectedType];
    if (!allowed.includes(actual)) {
      errors.push(`${path}: expected ${allowed.join('|')}, got ${actual}`);
      return errors;
    }
  }
  if (schema.required && typeOf(data) === 'object') {
    for (const key of schema.required) {
      if (!(key in data) || data[key] === undefined) {
        errors.push(`${path}: missing required property "${key}"`);
      }
    }
  }
  if (schema.properties && typeOf(data) === 'object') {
    for (const [key, propSchema] of Object.entries(schema.properties)) {
      if (data[key] === undefined) continue;
      errors.push(...validateAgainstSchema(data[key], propSchema, `${path}.${key}`));
    }
    if (schema.additionalProperties === false) {
      const allowed = new Set(Object.keys(schema.properties));
      for (const key of Object.keys(data)) {
        if (!allowed.has(key)) {
          errors.push(`${path}: unexpected property "${key}"`);
        }
      }
    }
  }
  if (schema.items && typeOf(data) === 'array') {
    data.forEach((item, i) => {
      errors.push(...validateAgainstSchema(item, schema.items, `${path}[${i}]`));
    });
  }
  if (schema.enum && !schema.enum.includes(data)) {
    errors.push(`${path}: value must be one of ${schema.enum.join(', ')}`);
  }
  return errors;
}

/**
 * Validate all access items: schema + name uniqueness + name-reference resolution.
 */
export function validateRepo({ config = loadConfig(), items = loadAllItems() } = {}) {
  const errors = [];
  const warnings = [];
  const byName = new Map();

  for (const item of items) {
    const schema = loadSchema(item.type);
    for (const err of validateAgainstSchema(item.data, schema)) {
      errors.push(`${item.relPath}: ${err}`);
    }

    const key = nameKey(item);
    if (byName.has(key)) {
      errors.push(`Duplicate ${item.type} name "${item.data.name}" (${item.relPath} and ${byName.get(key)})`);
    } else {
      byName.set(key, item.relPath);
    }

    if (item.type === ITEM_TYPES.entitlement) {
      const allowed = (config.entitlementSources ?? []).map((s) => s.name);
      const sourceName = item.data.source?.name;
      if (sourceName && allowed.length && !allowed.includes(sourceName)) {
        errors.push(`${item.relPath}: source "${sourceName}" is not in entitlementSources allowlist`);
      }
      if (!item.data.id) {
        warnings.push(`${item.relPath}: entitlement has no id (entitlements cannot be created via this repo)`);
      }
    }
  }

  const nameIndex = indexByName(items);
  const entNames = entitlementNames(items);

  for (const item of items) {
    if (item.type === ITEM_TYPES.accessProfile) {
      for (const ent of item.data.entitlements ?? []) {
        if (!ent.name) {
          errors.push(`${item.relPath}: entitlement reference missing name`);
          continue;
        }
        if (!entNames.has(ent.name) && !ent.id) {
          errors.push(`${item.relPath}: unresolved entitlement "${ent.name}"`);
        }
      }
    }
    if (item.type === ITEM_TYPES.role) {
      for (const ap of item.data.accessProfiles ?? []) {
        if (!ap.name) {
          errors.push(`${item.relPath}: access profile reference missing name`);
          continue;
        }
        if (!nameIndex.has(`${ITEM_TYPES.accessProfile}:${ap.name}`) && !ap.id) {
          errors.push(`${item.relPath}: unresolved access profile "${ap.name}"`);
        }
      }
      for (const ent of item.data.entitlements ?? []) {
        if (!ent.name) continue;
        if (!entNames.has(ent.name) && !ent.id) {
          errors.push(`${item.relPath}: unresolved entitlement "${ent.name}"`);
        }
      }
    }
  }

  return {
    ok: errors.length === 0,
    errors,
    warnings,
    itemCount: items.length,
  };
}
