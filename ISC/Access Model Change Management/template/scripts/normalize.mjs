import { ITEM_TYPES, VOLATILE_FIELDS } from './common.mjs';

function omit(obj, keys) {
  if (!obj || typeof obj !== 'object') return obj;
  const out = { ...obj };
  for (const k of keys) delete out[k];
  return out;
}

function ownerRef(owner) {
  if (!owner) return null;
  return {
    type: owner.type ?? 'IDENTITY',
    id: owner.id ?? null,
    name: owner.name ?? null,
  };
}

function sourceRef(source) {
  if (!source) return null;
  return {
    id: source.id ?? null,
    name: source.name ?? null,
  };
}

/**
 * Normalize a live ISC entitlement into the repo file shape.
 * Only metadata the Entitlements API can update is kept for apply.
 */
export function normalizeEntitlement(raw, { sourceSlug } = {}) {
  return {
    id: raw.id ?? null,
    name: raw.name,
    description: raw.description ?? '',
    privileged: Boolean(raw.privileged),
    requestable: Boolean(raw.requestable),
    owner: ownerRef(raw.owner),
    source: sourceRef(raw.source),
    sourceSlug: sourceSlug ?? null,
    // Read-only context kept for humans; never patched back.
    _readonly: {
      value: raw.value ?? null,
      attribute: raw.attribute ?? null,
      sourceSchemaObjectType: raw.sourceSchemaObjectType ?? null,
    },
  };
}

/**
 * Access profile shape stored in git. Entitlement membership is by name within source.
 */
export function normalizeAccessProfile(raw, { entitlementNameById = new Map() } = {}) {
  const entitlements = (raw.entitlements ?? []).map((e) => {
    const name = e.name ?? entitlementNameById.get(e.id) ?? null;
    return {
      id: e.id ?? null,
      name,
      type: e.type ?? 'ENTITLEMENT',
    };
  });

  return omit(
    {
      id: raw.id ?? null,
      name: raw.name,
      description: raw.description ?? '',
      enabled: raw.enabled !== false,
      requestable: Boolean(raw.requestable),
      owner: ownerRef(raw.owner),
      source: sourceRef(raw.source),
      entitlements,
      accessRequestConfig: raw.accessRequestConfig ?? null,
      revocationRequestConfig: raw.revocationRequestConfig ?? null,
      segments: raw.segments ?? [],
      provisioningCriteria: raw.provisioningCriteria ?? null,
    },
    VOLATILE_FIELDS,
  );
}

/**
 * Role shape. Access profiles and entitlements referenced by name where possible.
 */
export function normalizeRole(raw, {
  accessProfileNameById = new Map(),
  entitlementNameById = new Map(),
} = {}) {
  const accessProfiles = (raw.accessProfiles ?? []).map((ap) => ({
    id: ap.id ?? null,
    name: ap.name ?? accessProfileNameById.get(ap.id) ?? null,
  }));

  const entitlements = (raw.entitlements ?? []).map((e) => ({
    id: e.id ?? null,
    name: e.name ?? entitlementNameById.get(e.id) ?? null,
    type: e.type ?? 'ENTITLEMENT',
  }));

  return omit(
    {
      id: raw.id ?? null,
      name: raw.name,
      description: raw.description ?? '',
      enabled: raw.enabled !== false,
      requestable: Boolean(raw.requestable),
      owner: ownerRef(raw.owner),
      accessProfiles,
      entitlements,
      membership: raw.membership ?? null,
      accessRequestConfig: raw.accessRequestConfig ?? null,
      revocationRequestConfig: raw.revocationRequestConfig ?? null,
      segments: raw.segments ?? [],
      dimensional: Boolean(raw.dimensional),
      dimensionRefs: raw.dimensionRefs ?? [],
    },
    VOLATILE_FIELDS,
  );
}

export function normalizeByType(type, raw, opts) {
  if (type === ITEM_TYPES.entitlement) return normalizeEntitlement(raw, opts);
  if (type === ITEM_TYPES.accessProfile) return normalizeAccessProfile(raw, opts);
  if (type === ITEM_TYPES.role) return normalizeRole(raw, opts);
  throw new Error(`Unknown type ${type}`);
}

/**
 * Fields that may be patched on an entitlement via the Entitlements API.
 */
export const ENTITLEMENT_PATCHABLE = Object.freeze([
  'name',
  'description',
  'privileged',
  'requestable',
  'owner',
]);

/**
 * Build a create payload for access profiles / roles from a repo file.
 * Name-based refs are resolved to ids by the caller before calling this.
 */
export function toCreatePayload(type, item) {
  if (type === ITEM_TYPES.accessProfile) {
    const { id: _id, sourceSlug: _s, _readonly, ...rest } = item;
    return rest;
  }
  if (type === ITEM_TYPES.role) {
    const { id: _id, _readonly, ...rest } = item;
    return rest;
  }
  throw new Error(`Creates are not supported for ${type}`);
}
