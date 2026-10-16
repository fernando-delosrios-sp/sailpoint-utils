import { describe, it } from 'node:test';
import assert from 'node:assert/strict';
import { mkdtempSync, readFileSync, mkdirSync, writeFileSync, existsSync } from 'node:fs';
import { join } from 'node:path';
import { tmpdir } from 'node:os';
import { buildConfig, materializeTemplate } from '../render.mjs';
import yaml from 'js-yaml';

describe('buildConfig / materializeTemplate', () => {
  it('writes config.yaml with selected sources', () => {
    const src = mkdtempSync(join(tmpdir(), 'amcm-src-'));
    const dest = mkdtempSync(join(tmpdir(), 'amcm-dst-'));
    mkdirSync(join(src, 'access'), { recursive: true });
    writeFileSync(join(src, 'config.yaml'), 'tenant: {}\n');
    writeFileSync(join(src, 'README.md'), 'Hello {{TENANT_NAME}}\n');

    const config = buildConfig({
      tenantName: 'demo',
      tenantApiUrl: 'https://demo.api.identitynow.com',
      tenantUiUrl: 'https://demo.identitynow.com',
      entitlementSources: [{ id: '1', name: 'AD' }],
      governanceGroupId: 'g1',
      governanceGroupName: 'Gov',
      githubOwner: 'acme',
      githubRepo: 'access',
    });

    materializeTemplate({
      templateDir: src,
      destDir: dest,
      config,
      replacements: { '{{TENANT_NAME}}': 'demo' },
    });

    const written = yaml.load(readFileSync(join(dest, 'config.yaml'), 'utf8'));
    assert.equal(written.tenant.name, 'demo');
    assert.equal(written.entitlementSources[0].name, 'AD');
    assert.equal(readFileSync(join(dest, 'README.md'), 'utf8').trim(), 'Hello demo');
    assert.ok(existsSync(join(dest, 'access')));
  });
});
