/**
 * One read of the live access model, shaped exactly like the repo files.
 *
 * Backup, drift detection and restore all need the same thing, and each full
 * read is ~70 paged requests against ISC, so they share this module and a
 * drift decision can reuse a single snapshot instead of enumerating twice.
 */
import { join, relative } from 'node:path';
import {
  ITEM_TYPES,
  ROOT,
  entitlementId,
  entitlementObjectType,
  entitlementValue,
  itemPath,
  slugify,
} from './common.mjs';
import { mapLimit } from './concurrency.mjs';
import {
  normalizeAccessProfile,
  normalizeEntitlement,
  normalizeRole,
} from './normalize.mjs';

/** Entitlement sources read at once. IscClient caps total in-flight requests. */
const SOURCE_CONCURRENCY = 6;

function entry({ type, data, sourceSlug = null, discriminator = null }) {
  const path = itemPath(type, data.name, sourceSlug, discriminator);
  return {
    type,
    path,
    relPath: relative(ROOT, path),
    data,
    name: data.name,
    id: data.id ?? null,
    sourceSlug,
  };
}

/**
 * Suffixes to try for entitlements that share a name inside one source, from
 * most readable to most certain. The last one is the ISC id, which is unique
 * by definition, so a group can always be separated.
 *
 * Name alone is not enough (AWS exposes many same-named policy entitlements),
 * and neither is the native value: an Entra group surfaces as `group`,
 * `azureADActiveGroup` and `azureADEligibleGroup` entitlements carrying the
 * same name and the same object GUID, and a PIM role surfaces as both an
 * active and an eligible entitlement.
 */
function discriminatorTiers(item) {
  const value = entitlementValue(item);
  const objectType = entitlementObjectType(item);
  const id = entitlementId(item);
  return [
    value,
    objectType,
    objectType && value ? `${objectType}-${value}` : null,
    id,
  ].filter((tier) => tier !== null);
}

/**
 * Entitlements of one source, with same-named ones given a disambiguating file
 * name. Without this they collapse onto one path and all but the last silently
 * vanish from the backup, which is how 18% of a tenant went missing.
 */
function entitlementEntries(raws, sourceSlug) {
  const normalized = raws.map((raw) => ({
    data: normalizeEntitlement(raw, { sourceSlug }),
    id: raw.id ?? null,
  }));

  const byNameSlug = new Map();
  for (const item of normalized) {
    const slug = slugify(item.data.name);
    if (!byNameSlug.has(slug)) byNameSlug.set(slug, []);
    byNameSlug.get(slug).push(item);
  }

  const entries = [];
  for (const group of byNameSlug.values()) {
    // A name used once keeps a clean <name-slug>.json, so the ordinary case
    // reads well and existing repositories do not churn.
    if (group.length === 1) {
      entries.push(entry({ type: ITEM_TYPES.entitlement, data: group[0].data, sourceSlug }));
      continue;
    }
    const tiers = group.map(discriminatorTiers);
    const depth = Math.max(...tiers.map((t) => t.length));
    let chosen = null;
    for (let tier = 0; tier < depth; tier++) {
      const candidates = tiers.map((t) => t[Math.min(tier, t.length - 1)]);
      if (new Set(candidates).size === candidates.length) {
        chosen = candidates;
        break;
      }
    }
    if (!chosen) {
      throw new Error(
        `Cannot tell apart ${group.length} entitlements named "${group[0].data.name}" `
        + `in source "${sourceSlug}" — they share an id`,
      );
    }
    group.forEach((item, i) => entries.push(entry({
      type: ITEM_TYPES.entitlement,
      data: item.data,
      sourceSlug,
      discriminator: chosen[i],
    })));
  }
  return entries;
}

/**
 * Two entries on one path means a backup writes one over the other and the
 * loser disappears without a trace, which is the failure this module exists to
 * prevent. Fail loudly instead.
 */
function assertDistinctPaths(entries) {
  const seen = new Map();
  for (const item of entries) {
    const first = seen.get(item.relPath);
    if (first) {
      throw new Error(
        `Two items share the path ${item.relPath}: `
        + `${first.type} id ${first.id ?? 'none'} and ${item.type} id ${item.id ?? 'none'}`,
      );
    }
    seen.set(item.relPath, item);
  }
}

/**
 * Read allowlisted entitlements, all access profiles and all roles.
 * Returns repo-shaped entries plus the name maps needed to render references.
 */
export async function snapshotLive({ client, config }) {
  const allowlist = config.entitlementSources ?? [];
  const entitlementNameById = new Map();
  const accessProfileNameById = new Map();

  const perSource = await mapLimit(allowlist, SOURCE_CONCURRENCY, async (source) => {
    const raws = await client.listEntitlements(`source.id eq "${source.id}"`);
    return { raws, sourceSlug: slugify(source.name) };
  });

  const entitlements = [];
  for (const { raws, sourceSlug } of perSource) {
    for (const raw of raws) entitlementNameById.set(raw.id, raw.name);
    entitlements.push(...entitlementEntries(raws, sourceSlug));
  }

  // Access profiles and roles render entitlement names, so they come after.
  const [rawAccessProfiles, rawRoles] = await Promise.all([
    client.listAccessProfiles(),
    client.listRoles(),
  ]);

  const accessProfiles = rawAccessProfiles.map((raw) => {
    accessProfileNameById.set(raw.id, raw.name);
    return entry({
      type: ITEM_TYPES.accessProfile,
      data: normalizeAccessProfile(raw, { entitlementNameById }),
    });
  });

  const roles = rawRoles.map((raw) => entry({
    type: ITEM_TYPES.role,
    data: normalizeRole(raw, { accessProfileNameById, entitlementNameById }),
  }));

  const entries = [...entitlements, ...accessProfiles, ...roles];
  assertDistinctPaths(entries);

  return {
    entries,
    counts: {
      entitlements: entitlements.length,
      accessProfiles: accessProfiles.length,
      roles: roles.length,
    },
  };
}

/** Serializable form, so one process can read ISC and another can write it. */
export function toSnapshotFile(snapshot) {
  return {
    version: 1,
    counts: snapshot.counts,
    entries: snapshot.entries.map(({ type, relPath, data, sourceSlug }) => ({
      type,
      relPath,
      data,
      sourceSlug,
    })),
  };
}

export function fromSnapshotFile(file) {
  if (!file || file.version !== 1 || !Array.isArray(file.entries)) {
    throw new Error('Unrecognized snapshot file');
  }
  return {
    counts: file.counts,
    entries: file.entries.map(({ type, relPath, data, sourceSlug }) => ({
      type,
      path: join(ROOT, relPath),
      relPath,
      data,
      name: data.name,
      id: data.id ?? null,
      sourceSlug: sourceSlug ?? null,
    })),
  };
}
