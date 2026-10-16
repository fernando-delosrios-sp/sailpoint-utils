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
  entitlementDiscriminator,
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
 * Entitlements of one source, with same-named ones given a disambiguating file
 * name. ISC permits repeats of a name inside a source (AWS policy entitlements
 * do it routinely); without this they would all collapse onto one path and all
 * but the last would silently vanish from the backup.
 */
function entitlementEntries(raws, sourceSlug) {
  const normalized = raws.map((raw) => ({
    data: normalizeEntitlement(raw, { sourceSlug }),
    id: raw.id ?? null,
  }));

  const countBySlug = new Map();
  for (const item of normalized) {
    const slug = slugify(item.data.name);
    countBySlug.set(slug, (countBySlug.get(slug) ?? 0) + 1);
  }

  return normalized.map((item) => {
    const collides = countBySlug.get(slugify(item.data.name)) > 1;
    return entry({
      type: ITEM_TYPES.entitlement,
      data: item.data,
      sourceSlug,
      // Only the colliding names carry a suffix, so the ordinary case keeps a
      // clean <name-slug>.json and existing repositories do not churn.
      discriminator: collides
        ? entitlementDiscriminator({ data: item.data, id: item.id })
        : null,
    });
  });
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

  return {
    entries: [...entitlements, ...accessProfiles, ...roles],
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
