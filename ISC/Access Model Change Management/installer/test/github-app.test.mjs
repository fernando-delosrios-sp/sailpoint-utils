import { describe, it } from 'node:test';
import assert from 'node:assert/strict';
import { generateKeyPairSync, verify as cryptoVerify } from 'node:crypto';
import { signAppJwt, mintInstallationToken } from '../github-app.mjs';

function base64urlDecode(str) {
  return JSON.parse(Buffer.from(str, 'base64url').toString('utf8'));
}

const { privateKey, publicKey } = generateKeyPairSync('rsa', {
  modulusLength: 2048,
  publicKeyEncoding: { type: 'spki', format: 'pem' },
  privateKeyEncoding: { type: 'pkcs8', format: 'pem' },
});

describe('signAppJwt', () => {
  it('produces a three-part JWT with the App id as issuer and a verifiable RS256 signature', () => {
    const now = 1_700_000_000;
    const jwt = signAppJwt({ appId: '123456', privateKeyPem: privateKey, now });
    const [headerPart, payloadPart, signaturePart] = jwt.split('.');
    assert.equal([headerPart, payloadPart, signaturePart].length, 3);

    assert.deepEqual(base64urlDecode(headerPart), { alg: 'RS256', typ: 'JWT' });
    const payload = base64urlDecode(payloadPart);
    assert.equal(payload.iss, '123456');
    assert.equal(payload.iat, now - 60);
    assert.equal(payload.exp, now + 600);

    const signingInput = `${headerPart}.${payloadPart}`;
    const signature = Buffer.from(signaturePart, 'base64url');
    assert.ok(cryptoVerify('RSA-SHA256', Buffer.from(signingInput), publicKey, signature));
  });

  it('trims the App id so a pasted value with surrounding whitespace still verifies', () => {
    const jwt = signAppJwt({ appId: ' 42 \n', privateKeyPem: privateKey });
    const [, payloadPart] = jwt.split('.');
    assert.equal(base64urlDecode(payloadPart).iss, '42');
  });
});

describe('mintInstallationToken', () => {
  it('exchanges the App key for an installation token scoped to the target repo', async () => {
    const calls = [];
    const fetchImpl = async (url, init) => {
      calls.push({ url, init });
      if (url.endsWith('/repos/acme/amcm/installation')) {
        return {
          ok: true,
          text: async () => JSON.stringify({ id: 999 }),
        };
      }
      if (url.endsWith('/app/installations/999/access_tokens')) {
        return {
          ok: true,
          text: async () => JSON.stringify({ token: 'ghs_abc', expires_at: '2026-01-01T00:00:00Z' }),
        };
      }
      throw new Error(`unexpected URL ${url}`);
    };

    const result = await mintInstallationToken({
      appId: '123',
      privateKeyPem: privateKey,
      owner: 'acme',
      repo: 'amcm',
      fetchImpl,
    });

    assert.deepEqual(result, { token: 'ghs_abc', expiresAt: '2026-01-01T00:00:00Z', installationId: 999 });
    assert.equal(calls.length, 2);
    assert.equal(calls[0].init.method, 'GET');
    assert.equal(calls[1].init.method, 'POST');
    for (const call of calls) {
      assert.match(call.init.headers.Authorization, /^Bearer /);
    }
  });

  it('surfaces the GitHub error body when the installation lookup fails', async () => {
    const fetchImpl = async () => ({
      ok: false,
      status: 404,
      text: async () => JSON.stringify({ message: 'Not Found' }),
    });
    await assert.rejects(
      () => mintInstallationToken({ appId: '123', privateKeyPem: privateKey, owner: 'acme', repo: 'amcm', fetchImpl }),
      /404.*Not Found/,
    );
  });
});
