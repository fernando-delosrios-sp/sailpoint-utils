import {
  APPLY_ORDER,
  ITEM_TYPES,
  contentHash,
  indexByName,
  loadAllItems,
  nameKey,
  stableStringify,
} from './common.mjs';
import { ENTITLEMENT_PATCHABLE } from './normalize.mjs';

/**
 * Semantic compare of two normalized item bodies, ignoring id and _readonly.
 */
export function semanticBody(data, type) {
  const clone = structuredClone(data);
  delete clone.id;
  delete clone._readonly;
  delete clone.sourceSlug;
  if (type === ITEM_TYPES.entitlement) {
    const kept = {};
    for (const key of ENTITLEMENT_PATCHABLE) {
      if (key in clone) kept[key] = clone[key];
    }
    // source is identity context, not patchable content for equality of metadata
    kept.source = clone.source;
    return kept;
  }
  // Strip nested ids from name-keyed refs so renames of ids do not look like content change
  if (clone.entitlements) {
    clone.entitlements = clone.entitlements.map(({ name, type: t }) => ({ name, type: t }));
  }
  if (clone.accessProfiles) {
    clone.accessProfiles = clone.accessProfiles.map(({ name }) => ({ name }));
  }
  return clone;
}

function bodiesEqual(a, b, type) {
  return stableStringify(semanticBody(a, type)) === stableStringify(semanticBody(b, type));
}

/**
 * Build a JSON Patch document for entitlement metadata.
 */
export function entitlementPatch(before, after) {
  const ops = [];
  for (const field of ENTITLEMENT_PATCHABLE) {
    const left = before?.[field] ?? null;
    const right = after?.[field] ?? null;
    if (stableStringify(left) !== stableStringify(right)) {
      ops.push({ op: left === null || left === undefined ? 'add' : 'replace', path: `/${field}`, value: right });
    }
  }
  return ops;
}

/**
 * Build a JSON Patch that replaces top-level mutable fields on access profiles / roles.
 */
export function objectPatch(before, after, type) {
  const left = semanticBody(before, type);
  const right = semanticBody(after, type);
  const ops = [];
  const keys = new Set([...Object.keys(left), ...Object.keys(right)]);
  for (const key of keys) {
    if (stableStringify(left[key]) === stableStringify(right[key])) continue;
    if (right[key] === undefined) {
      ops.push({ op: 'remove', path: `/${key}` });
    } else if (left[key] === undefined) {
      ops.push({ op: 'add', path: `/${key}`, value: right[key] });
    } else {
      ops.push({ op: 'replace', path: `/${key}`, value: right[key] });
    }
  }
  return ops;
}

/**
 * Diff base items vs head items into ordered create / update / delete operations.
 * Base is typically `main` (or live ISC for restore); head is the desired state.
 */
export function buildPlan({ baseItems, headItems }) {
  const baseByKey = indexByName(baseItems);
  const headByKey = indexByName(headItems);
  const operations = [];

  for (const type of APPLY_ORDER) {
    const headOfType = headItems.filter((i) => i.type === type);
    const baseOfType = baseItems.filter((i) => i.type === type);

    for (const head of headOfType) {
      const key = nameKey(head);
      const base = baseByKey.get(key);
      if (!base) {
        if (type === ITEM_TYPES.entitlement) {
          operations.push({
            op: 'skip',
            type,
            name: head.name,
            reason: 'Entitlements cannot be created via this repo',
            path: head.relPath,
          });
          continue;
        }
        operations.push({
          op: 'create',
          type,
          name: head.name,
          path: head.relPath,
          desired: head.data,
          owner: head.data.owner ?? null,
        });
        continue;
      }
      if (!bodiesEqual(base.data, head.data, type)) {
        const patch = type === ITEM_TYPES.entitlement
          ? entitlementPatch(base.data, head.data)
          : objectPatch(base.data, head.data, type);
        operations.push({
          op: 'update',
          type,
          name: head.name,
          id: head.data.id ?? base.data.id,
          path: head.relPath,
          patch,
          desired: head.data,
          before: base.data,
          owner: head.data.owner ?? base.data.owner ?? null,
        });
      }
    }

    for (const base of baseOfType) {
      const key = nameKey(base);
      if (!headByKey.has(key)) {
        if (type === ITEM_TYPES.entitlement) {
          operations.push({
            op: 'skip',
            type,
            name: base.name,
            reason: 'Entitlements cannot be deleted via this repo',
            path: base.relPath,
          });
          continue;
        }
        operations.push({
          op: 'delete',
          type,
          name: base.name,
          id: base.data.id,
          path: base.relPath,
          before: base.data,
          owner: base.data.owner ?? null,
        });
      }
    }
  }

  // Creates/updates stay in dependency order; deletes run reverse (roles, then APs).
  const createsAndUpdates = operations.filter((o) => o.op !== 'delete');
  const deletes = operations
    .filter((o) => o.op === 'delete')
    .sort((a, b) => APPLY_ORDER.indexOf(b.type) - APPLY_ORDER.indexOf(a.type));

  const finalOps = [];
  for (const type of APPLY_ORDER) {
    finalOps.push(...createsAndUpdates.filter((o) => o.type === type));
  }
  finalOps.push(...deletes);

  const actionable = finalOps.filter((o) => o.op !== 'skip');
  return {
    operations: finalOps,
    summary: {
      create: actionable.filter((o) => o.op === 'create').length,
      update: actionable.filter((o) => o.op === 'update').length,
      delete: actionable.filter((o) => o.op === 'delete').length,
      skip: finalOps.filter((o) => o.op === 'skip').length,
    },
    planHash: contentHash(actionable.map(({ op, type, name, patch, desired }) => ({
      op, type, name, patch, desired: desired ? semanticBody(desired, type) : null,
    }))),
  };
}

/**
 * Plan from two loaded item arrays (e.g. git show base vs working tree).
 */
export function planFromTrees({ baseItems = [], headItems = loadAllItems() } = {}) {
  return buildPlan({ baseItems, headItems });
}
