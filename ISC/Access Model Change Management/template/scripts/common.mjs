import { createHash } from 'node:crypto';
import { existsSync, mkdirSync, readFileSync, readdirSync, rmdirSync, writeFileSync, rmSync } from 'node:fs';
import { dirname, join, relative, sep } from 'node:path';
import { fileURLToPath } from 'node:url';
import yaml from 'js-yaml';

const __dirname = dirname(fileURLToPath(import.meta.url));
export const ROOT = join(__dirname, '..');

export const ACCESS_ROOT = join(ROOT, 'access');
export const ENTITLEMENTS_DIR = join(ACCESS_ROOT, 'entitlements');
export const ACCESS_PROFILES_DIR = join(ACCESS_ROOT, 'access-profiles');
export const ROLES_DIR = join(ACCESS_ROOT, 'roles');
export const CHANGES_DIR = join(ROOT, 'changes');
export const CONFIG_PATH = join(ROOT, 'config.yaml');

export const ITEM_TYPES = Object.freeze({
  entitlement: 'entitlement',
  accessProfile: 'accessProfile',
  role: 'role',
});

export const APPLY_ORDER = Object.freeze([
  ITEM_TYPES.entitlement,
  ITEM_TYPES.accessProfile,
  ITEM_TYPES.role,
]);

/** Fields that change without a content change and would pollute diffs. */
export const VOLATILE_FIELDS = Object.freeze([
  'created',
  'modified',
  'synced',
  'sourceCreated',
  'sourceModified',
  'attribute',
  'value',
  'sourceSchemaObjectType',
  'identityCount',
  'accountCount',
]);

export function loadConfig(path = CONFIG_PATH) {
  if (!existsSync(path)) {
    throw new Error(`Missing config at ${path}`);
  }
  return yaml.load(readFileSync(path, 'utf8'));
}

export function slugify(name) {
  return String(name ?? '')
    .normalize('NFKD')
    .replace(/[\u0300-\u036f]/g, '')
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-+|-+$/g, '')
    .slice(0, 120) || 'unnamed';
}

export function ensureDir(path) {
  mkdirSync(path, { recursive: true });
}

export function writeJson(path, value) {
  ensureDir(dirname(path));
  writeFileSync(path, `${JSON.stringify(value, null, 2)}\n`, 'utf8');
}

export function readJson(path) {
  return JSON.parse(readFileSync(path, 'utf8'));
}

export function stableStringify(value) {
  if (value === null || typeof value !== 'object') {
    return JSON.stringify(value);
  }
  if (Array.isArray(value)) {
    return `[${value.map(stableStringify).join(',')}]`;
  }
  const keys = Object.keys(value).sort();
  return `{${keys.map((k) => `${JSON.stringify(k)}:${stableStringify(value[k])}`).join(',')}}`;
}

export function contentHash(value) {
  return createHash('sha256').update(stableStringify(value)).digest('hex');
}

/**
 * File path for an item.
 *
 * `discriminator` disambiguates entitlements that share a name inside one
 * source — ISC allows that, a single file name does not. Callers pass it only
 * for the colliding names (see `entitlementDiscriminator`), so the common case
 * keeps the bare `<name-slug>.json`.
 */
export function itemPath(type, name, sourceSlug = null, discriminator = null) {
  const base = slugify(name);
  const file = discriminator ? `${base}__${slugify(discriminator)}.json` : `${base}.json`;
  if (type === ITEM_TYPES.entitlement) {
    if (!sourceSlug) throw new Error('Entitlement paths require a source slug');
    return join(ENTITLEMENTS_DIR, sourceSlug, file);
  }
  if (type === ITEM_TYPES.accessProfile) {
    return join(ACCESS_PROFILES_DIR, file);
  }
  if (type === ITEM_TYPES.role) {
    return join(ROLES_DIR, file);
  }
  throw new Error(`Unknown item type: ${type}`);
}

export function typeFromPath(filePath) {
  const rel = relative(ACCESS_ROOT, filePath).split(sep);
  if (rel[0] === 'entitlements') return ITEM_TYPES.entitlement;
  if (rel[0] === 'access-profiles') return ITEM_TYPES.accessProfile;
  if (rel[0] === 'roles') return ITEM_TYPES.role;
  return null;
}

export function walkJsonFiles(dir) {
  if (!existsSync(dir)) return [];
  const out = [];
  for (const entry of readdirSync(dir, { withFileTypes: true })) {
    const full = join(dir, entry.name);
    if (entry.isDirectory()) {
      out.push(...walkJsonFiles(full));
    } else if (entry.isFile() && entry.name.endsWith('.json')) {
      out.push(full);
    }
  }
  return out.sort();
}

export function loadAllItems(root = ACCESS_ROOT) {
  const items = [];
  for (const file of walkJsonFiles(root)) {
    const type = typeFromPath(file);
    if (!type) continue;
    const data = readJson(file);
    items.push({
      type,
      path: file,
      relPath: relative(ROOT, file),
      data,
      name: data.name,
      id: data.id ?? null,
      sourceSlug: type === ITEM_TYPES.entitlement
        ? relative(ENTITLEMENTS_DIR, dirname(file)).split(sep)[0]
        : null,
    });
  }
  return items;
}

/**
 * Native value of an entitlement — its identifier inside the source. Name is
 * patchable metadata, value is not, so value is what identifies the same
 * entitlement across a backup/apply round trip.
 */
export function entitlementValue(item) {
  const value = item?.data?._readonly?.value ?? null;
  return value === null || value === undefined ? null : String(value);
}

/**
 * Suffix that makes two same-named entitlements in one source distinguishable.
 * Value first (stable in the source), id second (stable in ISC).
 */
export function entitlementDiscriminator(item) {
  return entitlementValue(item) ?? (item?.id ?? item?.data?.id ?? null);
}

/**
 * Uniqueness key for an item.
 *
 * Entitlements are keyed by source + native value: names are only unique within
 * a source (two Google Workspace connectors can both have a "Directory Sync
 * Admin Role"), and even inside one source ISC allows repeats — AWS policy
 * entitlements routinely do. Keying on value also means renaming an
 * entitlement in ISC reads as an update instead of an unsupported
 * create-plus-delete. Entitlements with no value fall back to name.
 *
 * Access profiles and roles are tenant-wide and keyed by name alone.
 */
export function nameKey(item) {
  if (item.type === ITEM_TYPES.entitlement) {
    const value = entitlementValue(item);
    const scope = item.sourceSlug ?? '';
    return value === null
      ? `${item.type}:${scope}:name:${item.name}`
      : `${item.type}:${scope}:value:${value}`;
  }
  return `${item.type}:${item.name}`;
}

/**
 * Entitlement names by themselves (ignoring source) for referential-integrity
 * checks only — a bare name reference cannot disambiguate source, so this
 * just answers "does an entitlement with this name exist anywhere".
 */
export function entitlementNames(items) {
  const names = new Set();
  for (const item of items) {
    if (item.type === ITEM_TYPES.entitlement) names.add(item.name);
  }
  return names;
}

/**
 * Index items by identity. Entitlements are keyed by source and native value,
 * so repeated names inside a source are fine; a throw here means two items
 * genuinely share an identity and the plan could not tell them apart.
 */
export function indexByName(items) {
  const map = new Map();
  for (const item of items) {
    const key = nameKey(item);
    const existing = map.get(key);
    if (existing) {
      const where = item.type === ITEM_TYPES.entitlement
        ? ` in source "${item.sourceSlug}" (value ${entitlementValue(item) ?? 'unset'})`
        : '';
      throw new Error(
        `Duplicate ${item.type} named "${item.name}"${where}: `
        + `${existing.relPath} and ${item.relPath}`,
      );
    }
    map.set(key, item);
  }
  return map;
}

export function indexById(items) {
  const map = new Map();
  for (const item of items) {
    if (!item.id) continue;
    map.set(`${item.type}:${item.id}`, item);
  }
  return map;
}

export function removeEmptyDirs(dir) {
  if (!existsSync(dir)) return;
  for (const entry of readdirSync(dir, { withFileTypes: true })) {
    if (entry.isDirectory()) {
      removeEmptyDirs(join(dir, entry.name));
    }
  }
  if (readdirSync(dir).length === 0 && dir !== ACCESS_ROOT) {
    // rmSync without recursive throws EISDIR on a directory, even an empty one.
    rmdirSync(dir);
  }
}

export function nowIso() {
  return new Date().toISOString();
}

export function utcStamp(date = new Date()) {
  return date.toISOString().replace(/[-:]/g, '').replace(/\.\d{3}Z$/, 'Z');
}
