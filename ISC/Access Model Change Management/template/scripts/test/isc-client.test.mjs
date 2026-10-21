import { describe, it } from 'node:test';
import assert from 'node:assert/strict';
import { IscClient } from '../isc-client.mjs';

function response(status, body, headers = {}) {
  return {
    status,
    ok: status >= 200 && status < 300,
    headers: { get: (k) => headers[k.toLowerCase()] ?? null },
    text: async () => (body === undefined ? '' : JSON.stringify(body)),
  };
}

function clientWith(handler, opts = {}) {
  const calls = [];
  const sleeps = [];
  const client = new IscClient({
    baseUrl: 'https://tenant.api.identitynow.com',
    accessToken: 'token',
    fetchImpl: async (url, init) => {
      calls.push({ url: new URL(url), init });
      return handler(calls.length, new URL(url));
    },
    sleepImpl: async (ms) => { sleeps.push(ms); },
    ...opts,
  });
  return { client, calls, sleeps };
}

describe('IscClient retry', () => {
  it('waits the Retry-After the gateway asks for and then succeeds', async () => {
    const { client, calls, sleeps } = clientWith((n) => (n === 1
      ? response(429, { message: 'slow down' }, { 'retry-after': '2' })
      : response(200, { ok: true })));
    const { body } = await client.get('/roles/v1');
    assert.deepEqual(body, { ok: true });
    assert.equal(calls.length, 2);
    assert.deepEqual(sleeps, [2000]);
  });

  it('backs off exponentially when no Retry-After is given', async () => {
    const { client, sleeps } = clientWith((n) => (n < 4 ? response(503) : response(200, [])));
    await client.get('/roles/v1');
    assert.deepEqual(sleeps, [250, 500, 1000]);
  });

  it('gives up after maxAttempts and reports the status', async () => {
    const { client, calls } = clientWith(() => response(429, { message: 'nope' }), {
      maxAttempts: 3,
    });
    await assert.rejects(
      () => client.get('/roles/v1'),
      (err) => err.status === 429 && /GET \/roles\/v1 failed: 429/.test(err.message),
    );
    assert.equal(calls.length, 3);
  });

  it('does not retry a client error it cannot recover from', async () => {
    const { client, calls } = clientWith(() => response(403, { message: 'forbidden' }));
    await assert.rejects(() => client.get('/search/v1'), (err) => err.status === 403);
    assert.equal(calls.length, 1);
  });

  it('retries a network-level fetch rejection, not just an HTTP error status', async () => {
    // fetch() rejects outright on DNS/connection failures — there is no
    // res.status for the status-based retry above to see. Seen live: a bare
    // `TypeError: fetch failed` propagated straight out of listAll and
    // aborted a restore's post-apply reconcile step with no retry at all,
    // even though the restore it was reconciling had already succeeded.
    let calls = 0;
    const sleeps = [];
    const client = new IscClient({
      baseUrl: 'https://tenant.api.identitynow.com',
      accessToken: 'token',
      fetchImpl: async () => {
        calls += 1;
        if (calls < 3) throw new TypeError('fetch failed');
        return response(200, { ok: true });
      },
      sleepImpl: async (ms) => { sleeps.push(ms); },
    });
    const { body } = await client.get('/roles/v1');
    assert.deepEqual(body, { ok: true });
    assert.equal(calls, 3);
    assert.equal(sleeps.length, 2);
  });

  it('gives up after maxAttempts of network-level failures and rethrows', async () => {
    const client = new IscClient({
      baseUrl: 'https://tenant.api.identitynow.com',
      accessToken: 'token',
      fetchImpl: async () => { throw new TypeError('fetch failed'); },
      sleepImpl: async () => {},
      maxAttempts: 3,
    });
    await assert.rejects(() => client.get('/roles/v1'), /fetch failed/);
  });
});

describe('IscClient paging', () => {
  it('stops at the first short page and never asks for a count', async () => {
    const pages = {
      0: Array.from({ length: 250 }, (_, i) => ({ id: `a${i}` })),
      250: Array.from({ length: 250 }, (_, i) => ({ id: `b${i}` })),
      500: [{ id: 'c0' }],
      750: [],
    };
    const { client, calls } = clientWith((_n, url) => response(
      200,
      pages[Number(url.searchParams.get('offset'))] ?? [],
    ));
    const items = await client.listAll('/entitlements/v1');
    assert.equal(items.length, 501);
    for (const call of calls) {
      assert.equal(call.url.searchParams.get('count'), null);
    }
  });

  it('fetches a window of pages at once rather than one round trip per page', async () => {
    const full = Array.from({ length: 250 }, (_, i) => ({ id: i }));
    let peak = 0;
    let inFlight = 0;
    const { client } = clientWith(async (_n, url) => {
      inFlight += 1;
      peak = Math.max(peak, inFlight);
      await new Promise((r) => setTimeout(r, 1));
      inFlight -= 1;
      return response(200, Number(url.searchParams.get('offset')) < 500 ? full : []);
    });
    const items = await client.listAll('/entitlements/v1');
    assert.equal(items.length, 500);
    assert.ok(peak > 1, 'pages were fetched serially');
  });

  it('caps requests in flight so the gateway rate limit is respected', async () => {
    let peak = 0;
    let inFlight = 0;
    const { client } = clientWith(async () => {
      inFlight += 1;
      peak = Math.max(peak, inFlight);
      await new Promise((r) => setTimeout(r, 2));
      inFlight -= 1;
      return response(200, []);
    }, { maxInFlight: 3 });
    await Promise.all([...Array(12)].map(() => client.get('/roles/v1')));
    assert.ok(peak <= 3, `peak in flight was ${peak}`);
  });
});

describe('IscClient search paging', () => {
  it('reports truncation when the window exceeds max', async () => {
    const page = Array.from({ length: 500 }, (_, i) => ({ id: i }));
    const { client } = clientWith(() => response(200, page));
    const { items, truncated } = await client.searchAll({ indices: ['events'] }, { max: 1000 });
    assert.equal(items.length, 1000);
    assert.equal(truncated, true);
  });

  it('is not truncated when the results end first', async () => {
    const { client } = clientWith((n) => response(200, n === 1
      ? Array.from({ length: 500 }, (_, i) => ({ id: i }))
      : [{ id: 'last' }]));
    const { items, truncated } = await client.searchAll({ indices: ['events'] });
    assert.equal(items.length, 501);
    assert.equal(truncated, false);
  });
});

describe('IscClient identity lookup', () => {
  it('fetches an identity by id via /beta/identities/:id', async () => {
    const expected = { id: 'ident-123', alias: 'alice', attributes: { uid: 'alice' } };
    const { client, calls } = clientWith(() => response(200, expected));
    const ident = await client.getIdentity('ident-123');
    assert.deepEqual(ident, expected);
    assert.equal(calls.length, 1);
    assert.equal(calls[0].url.pathname, '/beta/identities/ident-123');
  });
});
