/**
 * Thin ISC REST client for access-item backup and apply.
 * Auth: ISC_ACCESS_TOKEN, or ISC_CLIENT_ID + ISC_CLIENT_SECRET against ISC_TENANT_URL.
 */

const DEFAULT_API_VERSION = 'v2025';

export class IscClient {
  constructor({
    baseUrl,
    accessToken,
    clientId,
    clientSecret,
    apiVersion = DEFAULT_API_VERSION,
    fetchImpl = globalThis.fetch,
  }) {
    if (!baseUrl) throw new Error('ISC base URL is required');
    this.baseUrl = baseUrl.replace(/\/$/, '');
    this.accessToken = accessToken ?? null;
    this.clientId = clientId ?? null;
    this.clientSecret = clientSecret ?? null;
    this.apiVersion = apiVersion;
    this.fetchImpl = fetchImpl;
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

  async request(method, path, { query, body, headers } = {}) {
    await this.ensureToken();
    const url = new URL(
      path.startsWith('http') ? path : `${this.baseUrl}/${this.apiVersion}${path}`,
    );
    if (query) {
      for (const [k, v] of Object.entries(query)) {
        if (v === undefined || v === null) continue;
        url.searchParams.set(k, String(v));
      }
    }
    const res = await this.fetchImpl(url, {
      method,
      headers: {
        Authorization: `Bearer ${this.accessToken}`,
        Accept: 'application/json',
        ...(body !== undefined ? { 'Content-Type': 'application/json' } : {}),
        ...headers,
      },
      body: body === undefined ? undefined : JSON.stringify(body),
    });
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

  async listAll(path, { query = {}, limit = 250 } = {}) {
    const items = [];
    let offset = 0;
    for (;;) {
      const { body } = await this.get(path, {
        query: { ...query, limit, offset, count: true },
      });
      const page = Array.isArray(body) ? body : body?.items ?? [];
      items.push(...page);
      if (page.length < limit) break;
      offset += limit;
    }
    return items;
  }

  // --- Entitlements (metadata update only) ---

  listEntitlements(filters) {
    return this.listAll('/entitlements', { query: filters ? { filters } : {} });
  }

  getEntitlement(id) {
    return this.get(`/entitlements/${id}`).then((r) => r.body);
  }

  patchEntitlement(id, operations) {
    return this.patch(`/entitlements/${id}`, operations).then((r) => r.body);
  }

  // --- Access profiles ---

  listAccessProfiles(filters) {
    return this.listAll('/access-profiles', { query: filters ? { filters } : {} });
  }

  getAccessProfile(id) {
    return this.get(`/access-profiles/${id}`).then((r) => r.body);
  }

  createAccessProfile(body) {
    return this.post('/access-profiles', body).then((r) => r.body);
  }

  patchAccessProfile(id, operations) {
    return this.patch(`/access-profiles/${id}`, operations).then((r) => r.body);
  }

  deleteAccessProfile(id) {
    return this.delete(`/access-profiles/${id}`);
  }

  // --- Roles ---

  listRoles(filters) {
    return this.listAll('/roles', { query: filters ? { filters } : {} });
  }

  getRole(id) {
    return this.get(`/roles/${id}`).then((r) => r.body);
  }

  createRole(body) {
    return this.post('/roles', body).then((r) => r.body);
  }

  patchRole(id, operations) {
    return this.patch(`/roles/${id}`, operations).then((r) => r.body);
  }

  deleteRole(id) {
    return this.delete(`/roles/${id}`);
  }

  // --- Sources / governance / audit helpers ---

  listSources() {
    return this.listAll('/sources');
  }

  listGovernanceGroups() {
    return this.listAll('/workgroups');
  }

  search(body) {
    return this.post('/search', body).then((r) => r.body);
  }

  async getWorkflowExecution(id) {
    return this.get(`/workflow-executions/${id}`).then((r) => r.body);
  }
}
