import { spawnSync } from 'node:child_process';
import { readFileSync, writeFileSync } from 'node:fs';
import { pathToFileURL } from 'node:url';

/**
 * Install from the public npm registry.
 *
 * The lockfile is generated on a developer machine whose npm registry is a
 * private Artifactory. `npm ci` fetches each `resolved` URL as written, so a
 * GitHub-hosted runner — which has no Artifactory credentials — gets a 403
 * before backup or validation can start.
 *
 * This rewrites those tarball URLs for the install only, then puts the
 * lockfile back so a later commit does not publish public-registry URLs.
 */
const ARTIFACTORY_TARBALL = /^https:\/\/[^/]+\/artifactory\/api\/npm\/[^/]+\//;
const PUBLIC_REGISTRY = 'https://registry.npmjs.org/';

export function rewriteResolvedUrls(lock) {
  let count = 0;
  for (const pkg of Object.values(lock.packages ?? {})) {
    if (typeof pkg.resolved === 'string' && ARTIFACTORY_TARBALL.test(pkg.resolved)) {
      pkg.resolved = pkg.resolved.replace(ARTIFACTORY_TARBALL, PUBLIC_REGISTRY);
      count += 1;
    }
  }
  return count;
}

function main() {
  const lockPath = new URL('../package-lock.json', import.meta.url);
  const original = readFileSync(lockPath, 'utf8');
  const lock = JSON.parse(original);
  const rewritten = rewriteResolvedUrls(lock);
  console.log(`public-npm-ci: rewrote ${rewritten} Artifactory tarball URL(s) to ${PUBLIC_REGISTRY}`);
  writeFileSync(lockPath, `${JSON.stringify(lock, null, 2)}\n`);
  let status = 1;
  try {
    const result = spawnSync(
      'npm',
      ['ci', '--registry', PUBLIC_REGISTRY, '--replace-registry-host', 'never'],
      { stdio: 'inherit' },
    );
    status = result.status ?? 1;
  } finally {
    writeFileSync(lockPath, original);
  }
  process.exit(status);
}

if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) {
  main();
}
