import { describe, it } from 'node:test';
import assert from 'node:assert/strict';
import { validateAgainstSchema } from '../validate.mjs';
import { readFileSync } from 'node:fs';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = join(dirname(fileURLToPath(import.meta.url)), '../..');

describe('validateAgainstSchema', () => {
  it('accepts a valid role', () => {
    const schema = JSON.parse(readFileSync(join(root, 'schemas/role.json'), 'utf8'));
    const errors = validateAgainstSchema({
      id: null,
      name: 'Role A',
      description: '',
      enabled: true,
      requestable: false,
      owner: { type: 'IDENTITY', id: '1', name: 'Owner' },
      accessProfiles: [{ name: 'AP' }],
      entitlements: [],
      membership: null,
      accessRequestConfig: null,
      revocationRequestConfig: null,
      segments: [],
      dimensional: false,
      dimensionRefs: [],
    }, schema);
    assert.deepEqual(errors, []);
  });

  it('rejects missing name', () => {
    const schema = JSON.parse(readFileSync(join(root, 'schemas/role.json'), 'utf8'));
    const errors = validateAgainstSchema({
      owner: { type: 'IDENTITY' },
    }, schema);
    assert.ok(errors.some((e) => e.includes('name')));
  });
});
