import { describe, it } from 'node:test';
import assert from 'node:assert/strict';
import { mkdtempSync, mkdirSync, writeFileSync, readFileSync, existsSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { tmpdir } from 'node:os';
import { fileURLToPath } from 'node:url';
import { clearAccessAndLedger } from '../reset.mjs';
import { writeInitEntry } from '../ledger.mjs';
import { generateReadme } from '../readme.mjs';

const templateRoot = join(dirname(fileURLToPath(import.meta.url)), '../..');

describe('clearAccessAndLedger', () => {
  it('removes access and ledger json and keeps gitkeep files', () => {
    const root = mkdtempSync(join(tmpdir(), 'amcm-reset-'));
    const access = join(root, 'access');
    const changes = join(root, 'changes');
    mkdirSync(join(access, 'roles'), { recursive: true });
    mkdirSync(join(access, 'entitlements', 'ad'), { recursive: true });
    mkdirSync(join(changes, '2026-10'), { recursive: true });
    writeFileSync(join(access, 'roles', '.gitkeep'), '');
    writeFileSync(join(access, 'entitlements', '.gitkeep'), '');
    writeFileSync(join(access, 'roles', 'a.json'), '{}\n');
    writeFileSync(join(access, 'entitlements', 'ad', 'e.json'), '{}\n');
    writeFileSync(join(changes, '.gitkeep'), '');
    writeFileSync(join(changes, '2026-10', 'pr-1.json'), '{}\n');
    writeFileSync(join(root, 'config.yaml'), 'keep\n');

    const result = clearAccessAndLedger({ accessRoot: access, changesDir: changes });

    assert.equal(result.removed, 3);
    assert.equal(existsSync(join(access, 'roles', '.gitkeep')), true);
    assert.equal(existsSync(join(access, 'roles', 'a.json')), false);
    assert.equal(existsSync(join(access, 'entitlements', '.gitkeep')), true);
    assert.equal(existsSync(join(access, 'entitlements', 'ad')), false);
    assert.equal(existsSync(join(changes, '.gitkeep')), true);
    assert.equal(existsSync(join(changes, '2026-10')), false);
    assert.equal(readFileSync(join(root, 'config.yaml'), 'utf8'), 'keep\n');
  });
});

describe('writeInitEntry', () => {
  it('writes a baseline ledger entry from backup counts', () => {
    const changes = mkdtempSync(join(tmpdir(), 'amcm-ledger-'));
    const { path, entry } = writeInitEntry({
      requester: 'ada',
      counts: { entitlements: 2, accessProfiles: 3, roles: 4 },
      tag: 'known-good/20261016T120000Z',
      timestamp: '2026-10-16T12:00:00.000Z',
      changesDir: changes,
    });
    assert.equal(existsSync(path), true);
    assert.equal(entry.kind, 'init');
    assert.equal(entry.requester, 'ada');
    assert.equal(entry.counts.roles, 4);
    assert.match(path, /2026-10\/init-2026-10-16T12-00-00-000Z\.json$/);
  });
});

describe('readme init row', () => {
  it('lists the baseline backup and the Init action', () => {
    const out = join(mkdtempSync(join(tmpdir(), 'amcm-readme-')), 'README.md');
    generateReadme({
      config: {
        tenant: { name: 'demo', apiUrl: 'https://example.test', uiUrl: '' },
        entitlementSources: [],
        approval: { governanceGroupName: 'Gov' },
        backup: { schedule: '0 2 * * *' },
      },
      entries: [{
        entry: {
          kind: 'init',
          requester: 'ada',
          counts: { entitlements: 1, accessProfiles: 2, roles: 3 },
          tag: 'known-good/20261016T120000Z',
          timestamp: '2026-10-16T12:00:00.000Z',
        },
      }],
      tags: ['known-good/20261016T120000Z'],
      outPath: out,
    });
    const text = readFileSync(out, 'utf8');
    assert.match(text, /\| init \| 1 entitlements, 2 access profiles, 3 roles \|/);
    assert.match(text, /known-good\/20261016T120000Z/);
    assert.match(text, /Actions → Init/);
    assert.match(text, /Type `RESET`/);
  });
});

describe('init workflow contract', () => {
  it('confirms RESET without interpolating the input into the shell script', () => {
    const yml = readFileSync(join(templateRoot, '.github/workflows/init.yml'), 'utf8');
    assert.match(yml, /CONFIRM: \$\{\{ inputs\.confirm \}\}/);
    assert.doesNotMatch(yml, /\[\s*"\$\{\{ inputs\.confirm \}\}"/);
    assert.match(yml, /clear-content/);
    assert.match(yml, /cli\.mjs backup/);
    assert.match(yml, /git push --force origin main/);
    assert.match(yml, /chore\(init\): baseline backup from ISC/);
    assert.match(yml, /Other workflows are still queued or running/);
  });

  it('does not apply or regenerate the readme for the init commit', () => {
    const apply = readFileSync(join(templateRoot, '.github/workflows/apply.yml'), 'utf8');
    const readme = readFileSync(join(templateRoot, '.github/workflows/readme.yml'), 'utf8');
    assert.match(apply, /chore\(init\):/);
    assert.match(apply, /HEAD~1/);
    assert.match(readme, /chore\(init\):/);
    assert.match(readme, /fetch-tags: true/);
  });
});
