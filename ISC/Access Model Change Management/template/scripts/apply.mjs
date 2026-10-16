import { relative } from 'node:path';
import {
  ITEM_TYPES,
  ROOT,
  indexByName,
  loadAllItems,
  writeJson,
} from './common.mjs';
import { IscClient } from './isc-client.mjs';
import { toCreatePayload } from './normalize.mjs';

/**
 * Resolve name-based references to ISC ids using the current item index.
 */
export function resolveReferences(desired, type, nameIndex) {
  const body = structuredClone(desired);

  if (body.entitlements) {
    body.entitlements = body.entitlements.map((e) => {
      if (e.id) return { id: e.id, type: e.type ?? 'ENTITLEMENT' };
      const found = nameIndex.get(`${ITEM_TYPES.entitlement}:${e.name}`);
      if (!found?.id) {
        throw new Error(`Cannot resolve entitlement "${e.name}" to an id`);
      }
      return { id: found.id, type: e.type ?? 'ENTITLEMENT' };
    });
  }

  if (body.accessProfiles) {
    body.accessProfiles = body.accessProfiles.map((ap) => {
      if (ap.id) return { id: ap.id };
      const found = nameIndex.get(`${ITEM_TYPES.accessProfile}:${ap.name}`);
      if (!found?.id) {
        throw new Error(`Cannot resolve access profile "${ap.name}" to an id`);
      }
      return { id: found.id };
    });
  }

  if (body.source && !body.source.id) {
    // Source id is required on create; leave as-is if missing — caller should have it.
  }

  return body;
}

/**
 * Apply a plan to ISC. Stops on first failure.
 * Writes new ids back into repo files after successful creates.
 */
export async function applyPlan({
  plan,
  client = IscClient.fromEnv(),
  items = loadAllItems(),
  dryRun = false,
} = {}) {
  const nameIndex = indexByName(items);
  const results = [];

  for (const op of plan.operations) {
    if (op.op === 'skip') {
      results.push({ ...op, status: 'skipped' });
      continue;
    }

    try {
      if (dryRun) {
        results.push({ ...op, status: 'dry-run' });
        continue;
      }

      if (op.op === 'create') {
        const payload = resolveReferences(toCreatePayload(op.type, op.desired), op.type, nameIndex);
        let created;
        if (op.type === ITEM_TYPES.accessProfile) {
          created = await client.createAccessProfile(payload);
        } else if (op.type === ITEM_TYPES.role) {
          created = await client.createRole(payload);
        } else {
          throw new Error(`Create not supported for ${op.type}`);
        }

        // Write id back into the repo file and refresh index for later refs.
        const fileItem = items.find((i) => i.type === op.type && i.name === op.name);
        if (fileItem) {
          fileItem.data.id = created.id;
          fileItem.id = created.id;
          writeJson(fileItem.path, fileItem.data);
          nameIndex.set(`${op.type}:${op.name}`, fileItem);
        }

        results.push({
          op: op.op,
          type: op.type,
          name: op.name,
          id: created.id,
          path: op.path,
          status: 'applied',
        });
        continue;
      }

      if (op.op === 'update') {
        let patch = op.patch;
        // Re-resolve name refs inside patch values where needed
        if (op.type !== ITEM_TYPES.entitlement && op.desired) {
          const resolved = resolveReferences(op.desired, op.type, nameIndex);
          // Rebuild patch against resolved desired for membership fields
          patch = op.patch.map((p) => {
            if (p.path === '/entitlements') return { ...p, value: resolved.entitlements };
            if (p.path === '/accessProfiles') return { ...p, value: resolved.accessProfiles };
            return p;
          });
        }

        if (op.type === ITEM_TYPES.entitlement) {
          await client.patchEntitlement(op.id, patch);
        } else if (op.type === ITEM_TYPES.accessProfile) {
          await client.patchAccessProfile(op.id, patch);
        } else if (op.type === ITEM_TYPES.role) {
          await client.patchRole(op.id, patch);
        }

        results.push({
          op: op.op,
          type: op.type,
          name: op.name,
          id: op.id,
          path: op.path,
          status: 'applied',
        });
        continue;
      }

      if (op.op === 'delete') {
        if (!op.id) throw new Error(`Delete of ${op.type} "${op.name}" has no id`);
        if (op.type === ITEM_TYPES.accessProfile) {
          await client.deleteAccessProfile(op.id);
        } else if (op.type === ITEM_TYPES.role) {
          await client.deleteRole(op.id);
        } else {
          throw new Error(`Delete not supported for ${op.type}`);
        }
        results.push({
          op: op.op,
          type: op.type,
          name: op.name,
          id: op.id,
          path: op.path,
          status: 'applied',
        });
        continue;
      }

      throw new Error(`Unknown operation ${op.op}`);
    } catch (err) {
      results.push({
        op: op.op,
        type: op.type,
        name: op.name,
        id: op.id ?? null,
        path: op.path,
        status: 'failed',
        error: err.message,
        body: err.body ?? null,
      });
      return {
        ok: false,
        stoppedAt: results.length - 1,
        results,
        applied: results.filter((r) => r.status === 'applied'),
        failed: results[results.length - 1],
      };
    }
  }

  return {
    ok: true,
    results,
    applied: results.filter((r) => r.status === 'applied'),
    failed: null,
  };
}

export function summarizeApply(result) {
  return {
    ok: result.ok,
    applied: result.applied.length,
    failed: result.failed
      ? `${result.failed.type}:${result.failed.name} — ${result.failed.error}`
      : null,
    paths: result.applied.map((r) => r.path ?? relative(ROOT, r.path ?? '')),
  };
}
