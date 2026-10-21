/**
 * Thin ISC REST client for access-item backup and apply.
 * Auth: ISC_ACCESS_TOKEN, or ISC_CLIENT_ID + ISC_CLIENT_SECRET against ISC_TENANT_URL.
 */

import { Semaphore } from './concurrency.mjs';

/** Requests allowed in flight at once. The gateway allows 100 per 10s. */
const DEFAULT_MAX_IN_FLIGHT = 8;
const DEFAULT_MAX_ATTEMPTS = 5;
const RETRYABLE_STATUS = new Set([429, 500, 502, 503, 504]);

const sleep = (ms) => new Promise((resolve) => setTimeout(resolve, ms));

export class IscClient {
  constructor({
    baseUrl,
    accessToken,
    clientId,
    clientSecret,
    fetchImpl = globalThis.fetch,
    maxInFlight = DEFAULT_MAX_IN_FLIGHT,
    maxAttempts = DEFAULT_MAX_ATTEMPTS,
    sleepImpl = sleep,
  }) {
    if (!baseUrl) throw new Error('ISC base URL is required');
    this.baseUrl = baseUrl.replace(/\/$/, '');
    this.accessToken = accessToken ?? null;
    this.clientId = clientId ?? null;
    this.clientSecret = clientSecret ?? null;
    this.fetchImpl = fetchImpl;
    this.maxAttempts = maxAttempts;
    this.sleepImpl = sleepImpl;
    this.gate = new Semaphore(maxInFlight);
  }

  static fromEnv(env = process.env) {
    return new IscClient({
      baseUrl: env.ISC_TENANT_URL,
      accessToken: env.ISC_ACCESS_TOKEN,
      clientId: env.ISC_CLIENT_ID,
      clientSecret: env.ISC_CLIENT_SECRET,
    });
  }

  async ensureToken() {
    if (this.accessToken) return this.accessToken;
    if (!this.clientId || !this.clientSecret) {
      throw new Error('Provide ISC_ACCESS_TOKEN or ISC_CLIENT_ID + ISC_CLIENT_SECRET');
    }
    const tokenUrl = `${this.baseUrl}/oauth/token`;
    const body = new URLSearchParams({
      grant_type: 'client_credentials',
      client_id: this.clientId,
      client_secret: this.clientSecret,
    });
    const res = await this.fetchImpl(tokenUrl, {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body,
    });
    if (!res.ok) {
      throw new Error(`OAuth token failed: ${res.status} ${await res.text()}`);
    }
    const json = await res.json();
    this.accessToken = json.access_token;
    return this.accessToken;
  }

  /**
   * Seconds to wait before retrying, from Retry-After when the gateway sets it
   * (429 carries it) and exponential backoff otherwise.
   */
  retryDelayMs(res, attempt) {
    const header = res?.headers?.get?.('retry-after');
    const seconds = header === null || header === undefined ? NaN : Number(header);
    if (Number.isFinite(seconds) && seconds >= 0) return seconds * 1000;
    return Math.min(8000, 250 * 2 ** (attempt - 1));
  }

  /**
   * Each service carries its own version in the path (`/entitlements/v1`,
   * `/roles/v1`), which is the current contract. The yearly generations
   * (`/v2024`, `/v2025`) are legacy and are not used here.
   */
  async request(method, path, { query, body, headers } = {}) {
    await this.ensureToken();
    const url = new URL(path.startsWith('http') ? path : `${this.baseUrl}${path}`);
    if (query) {
      for (const [k, v] of Object.entries(query)) {
        if (v === undefined || v === null) continue;
        url.searchParams.set(k, String(v));
      }
    }

    for (let attempt = 1; ; attempt++) {
      let res;
      try {
        res = await this.gate.run(() => this.fetchImpl(url, {
          method,
          headers: {
            Authorization: `Bearer ${this.accessToken}`,
            Accept: 'application/json',
            ...(body !== undefined ? { 'Content-Type': 'application/json' } : {}),
            ...headers,
          },
          body: body === undefined ? undefined : JSON.stringify(body),
        }));
      } catch (err) {
        // fetch() itself rejects on a network-level failure (DNS, reset,
        // timeout) — there is no res.status to check, so the retry below
        // never saw these. Seen live: a bare `TypeError: fetch failed` out
        // of listAll aborted a restore's post-apply reconcile step outright,
        // even though the restore it was reconciling had just succeeded.
        if (attempt < this.maxAttempts) {
          await this.sleepImpl(this.retryDelayMs(null, attempt));
          continue;
        }
        throw err;
      }

      // Rate limits and transient gateway errors are expected once requests
      // overlap, so they wait and retry rather than failing a whole backup.
      if (RETRYABLE_STATUS.has(res.status) && attempt < this.maxAttempts) {
        await this.sleepImpl(this.retryDelayMs(res, attempt));
        continue;
      }

      const text = await res.text();
      let json = null;
      if (text) {
        try {
          json = JSON.parse(text);
        } catch {
          json = text;
        }
      }
      if (!res.ok) {
        const err = new Error(`${method} ${url.pathname} failed: ${res.status}`);
        err.status = res.status;
        err.body = json;
        throw err;
      }
      return { status: res.status, headers: res.headers, body: json };
    }
  }

  get(path, opts) {
    return this.request('GET', path, opts);
  }
  post(path, body, opts) {
    return this.request('POST', path, { ...opts, body });
  }
  put(path, body, opts) {
    return this.request('PUT', path, { ...opts, body });
  }
  patch(path, body, opts) {
    return this.request('PATCH', path, {
      ...opts,
      body,
      headers: { 'Content-Type': 'application/json-patch+json', ...opts?.headers },
    });
  }
  delete(path, opts) {
    return this.request('DELETE', path, opts);
  }

  /**
   * Page a collection endpoint.
   *
   * Pages are fetched in windows of `window` so a large source does not cost
   * one serial round trip per 250 rows; a window stops as soon as a short page
   * shows the end, so over-fetch is at most `window - 1` requests per call.
   * `count` is never requested — nothing here reads X-Total-Count, and asking
   * for it makes the gateway total the collection on every page.
   */
  async listAll(path, { query = {}, limit = 250, window = 4 } = {}) {
    const items = [];
    let offset = 0;
    for (;;) {
      const offsets = Array.from({ length: window }, (_, i) => offset + i * limit);
      const pages = await Promise.all(offsets.map(async (pageOffset) => {
        const { body } = await this.get(path, { query: { ...query, limit, offset: pageOffset } });
        return Array.isArray(body) ? body : body?.items ?? [];
      }));

      let done = false;
      for (const page of pages) {
        items.push(...page);
        if (page.length < limit) {
          done = true;
          break;
        }
      }
      if (done) return items;
      offset += window * limit;
    }
  }

  // --- Entitlements (metadata update only) ---

  listEntitlements(filters) {
    return this.listAll('/entitlements/v1', { query: filters ? { filters } : {} });
  }

  getEntitlement(id) {
    return this.get(`/entitlements/v1/${id}`).then((r) => r.body);
  }

  patchEntitlement(id, operations) {
    return this.patch(`/entitlements/v1/${id}`, operations).then((r) => r.body);
  }

  // --- Access profiles ---

  listAccessProfiles(filters) {
    return this.listAll('/access-profiles/v1', { query: filters ? { filters } : {} });
  }

  getAccessProfile(id) {
    return this.get(`/access-profiles/v1/${id}`).then((r) => r.body);
  }

  createAccessProfile(body) {
    return this.post('/access-profiles/v1', body).then((r) => r.body);
  }

  patchAccessProfile(id, operations) {
    return this.patch(`/access-profiles/v1/${id}`, operations).then((r) => r.body);
  }

  deleteAccessProfile(id) {
    return this.delete(`/access-profiles/v1/${id}`);
  }

  // --- Roles ---

  listRoles(filters) {
    return this.listAll('/roles/v1', { query: filters ? { filters } : {} });
  }

  getRole(id) {
    return this.get(`/roles/v1/${id}`).then((r) => r.body);
  }

  createRole(body) {
    return this.post('/roles/v1', body).then((r) => r.body);
  }

  patchRole(id, operations) {
    return this.patch(`/roles/v1/${id}`, operations).then((r) => r.body);
  }

  deleteRole(id) {
    return this.delete(`/roles/v1/${id}`);
  }

  // --- Sources / governance / audit helpers ---

  listSources() {
    return this.listAll('/sources/v1');
  }

  listGovernanceGroups() {
    return this.listAll('/workgroups/v1');
  }

  search(body) {
    return this.post('/search/v1', body).then((r) => r.body);
  }

  /**
   * Page a Search API query. Offset paging stops at 10,000; `max` stops earlier
   * so a wide audit window cannot pull the whole events index.
   */
  async searchAll(body, { limit = 500, max = 5000 } = {}) {
    const items = [];
    let offset = 0;
    let truncated = false;
    for (;;) {
      const { body: pageBody } = await this.request('POST', '/search/v1', {
        query: { limit, offset },
        body,
      });
      const page = Array.isArray(pageBody) ? pageBody : pageBody?.items ?? [];
      items.push(...page);
      if (page.length < limit) break;
      offset += limit;
      if (offset >= max || offset >= 10000) {
        truncated = true;
        break;
      }
    }
    return { items, truncated };
  }

  async getWorkflowExecution(id) {
    return this.get(`/workflow-executions/v1/${id}`).then((r) => r.body);
  }

  async getIdentity(id) {
    return this.get(`/beta/identities/${id}`).then((r) => r.body);
  }
}
