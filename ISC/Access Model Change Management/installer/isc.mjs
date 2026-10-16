import { readFileSync } from 'node:fs';

/**
 * Minimal ISC client for installer (workflows, external triggers, sources, workgroups).
 */
export class InstallerIsc {
  constructor({ baseUrl, clientId, clientSecret, accessToken, fetchImpl = globalThis.fetch }) {
    this.baseUrl = baseUrl.replace(/\/$/, '');
    this.clientId = clientId;
    this.clientSecret = clientSecret;
    this.accessToken = accessToken ?? null;
    this.fetchImpl = fetchImpl;
    this.apiVersion = 'v2025';
  }

  static fromAnswers(answers) {
    return new InstallerIsc({
      baseUrl: answers.tenantApiUrl,
      clientId: answers.clientId,
      clientSecret: answers.clientSecret,
      accessToken: answers.accessToken,
    });
  }

  async ensureToken() {
    if (this.accessToken) return this.accessToken;
    const res = await this.fetchImpl(`${this.baseUrl}/oauth/token`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body: new URLSearchParams({
        grant_type: 'client_credentials',
        client_id: this.clientId,
        client_secret: this.clientSecret,
      }),
    });
    if (!res.ok) throw new Error(`ISC OAuth failed: ${res.status} ${await res.text()}`);
    this.accessToken = (await res.json()).access_token;
    return this.accessToken;
  }

  async request(method, path, body, { contentType = 'application/json' } = {}) {
    await this.ensureToken();
    const url = path.startsWith('http') ? path : `${this.baseUrl}/${this.apiVersion}${path}`;
    const res = await this.fetchImpl(url, {
      method,
      headers: {
        Authorization: `Bearer ${this.accessToken}`,
        Accept: 'application/json',
        ...(body !== undefined ? { 'Content-Type': contentType } : {}),
      },
      body: body === undefined ? undefined : JSON.stringify(body),
    });
    const text = await res.text();
    let json = null;
    try {
      json = text ? JSON.parse(text) : null;
    } catch {
      json = text;
    }
    if (!res.ok) {
      const err = new Error(`${method} ${path} → ${res.status}`);
      err.status = res.status;
      err.body = json;
      throw err;
    }
    return json;
  }

  get(path) {
    return this.request('GET', path);
  }
  post(path, body) {
    return this.request('POST', path, body);
  }
  put(path, body) {
    return this.request('PUT', path, body);
  }
  patch(path, body) {
    return this.request('PATCH', path, body);
  }
  delete(path) {
    return this.request('DELETE', path);
  }

  async listAll(path) {
    const items = [];
    let offset = 0;
    const limit = 250;
    for (;;) {
      const page = await this.get(`${path}${path.includes('?') ? '&' : '?'}limit=${limit}&offset=${offset}`);
      const arr = Array.isArray(page) ? page : page?.items ?? page?.results ?? [];
      items.push(...arr);
      if (arr.length < limit) break;
      offset += limit;
    }
    return items;
  }

  listSources() {
    return this.listAll('/sources');
  }

  listGovernanceGroups() {
    return this.listAll('/workgroups');
  }

  /**
   * Decode the access-token JWT payload (no signature check — token came from ISC).
   */
  decodeAccessToken() {
    if (!this.accessToken) return null;
    const parts = this.accessToken.split('.');
    if (parts.length < 2) return null;
    try {
      const json = Buffer.from(parts[1], 'base64url').toString('utf8');
      return JSON.parse(json);
    } catch {
      try {
        const json = Buffer.from(parts[1].replace(/-/g, '+').replace(/_/g, '/'), 'base64').toString('utf8');
        return JSON.parse(json);
      } catch {
        return null;
      }
    }
  }

  /**
   * Identity that owns the PAT / client credentials — used as the workflow owner.
   */
  async resolvePatOwner() {
    await this.ensureToken();
    const claims = this.decodeAccessToken() ?? {};
    const id = claims.identity_id
      || claims.identityId
      || claims.idn_uid
      || claims.uid
      || claims.sub;
    if (!id) {
      throw new Error(
        'Could not read identity_id from the access token. Use a personal access token (PAT) client for a service identity.',
      );
    }

    let name = claims.user_name || claims.username || claims.strong_id || claims.preferred_username || null;
    try {
      const identity = await this.get(`/identities/${id}`);
      name = identity?.name ?? identity?.alias ?? name ?? id;
      // Workflow owner.name is validated against the identity's alias — not its
      // display name and not attributes.uid, which can differ from the alias.
      const alias = identity?.alias ?? identity?.attributes?.uid ?? name;
      return { id: identity?.id ?? id, name, alias };
    } catch {
      return { id, name: name ?? id, alias: name ?? id };
    }
  }

  async validateCredentials() {
    await this.ensureToken();
    // lightweight call
    await this.get('/public-identities-config');
    return true;
  }

  async findWorkflowByName(name) {
    try {
      const all = await this.listAll('/workflows');
      return all.find((w) => w.name === name) ?? null;
    } catch {
      return null;
    }
  }

  /**
   * Upsert a workflow JSON, substituting placeholders.
   */
  async upsertWorkflow(workflowPath, replacements) {
    let text = readFileSync(workflowPath, 'utf8');
    for (const [key, value] of Object.entries(replacements)) {
      text = text.split(key).join(String(value));
    }
    const body = JSON.parse(text);
    const existing = await this.findWorkflowByName(body.name);
    if (existing) {
      const updated = await this.put(
        `/workflows/${existing.id}`,
        toWorkflowWriteBody(body, { id: existing.id }),
      );
      return { name: body.name, id: existing.id, action: 'updated', body: updated ?? body };
    }
    const created = await this.post('/workflows', toWorkflowWriteBody(body));
    return { name: body.name, id: created.id, action: 'created', body: created };
  }

  /**
   * Create the OAuth client GitHub Actions uses to invoke the external trigger.
   * Returns { clientId, clientSecret, triggerUrl } with triggerUrl absolute —
   * ISC returns it relative to the tenant API host.
   *
   * The workflow must be disabled; ISC rejects the call otherwise. The secret is
   * only returned here, and ISC exposes no list or delete endpoint, so every
   * re-run leaves another valid client behind. Remove stale ones in the UI.
   */
  async createExternalTriggerClient(workflowId) {
    try {
      const created = await this.post(`/workflows/${workflowId}/external/oauth-clients`, {});
      const url = created?.url ?? '';
      return {
        clientId: created?.id,
        clientSecret: created?.secret,
        triggerUrl: url.startsWith('http') ? url : `${this.baseUrl}${url}`,
      };
    } catch (err) {
      return {
        warning: `Could not auto-provision the external trigger client (${err.message}). `
          + 'Create it in the ISC UI under the workflow → Trigger, then paste the values.',
      };
    }
  }

  /** Workflows are enabled with a JSON Patch; there is no /enable endpoint. */
  async enableWorkflow(workflowId) {
    return this.request(
      'PATCH',
      `/workflows/${workflowId}`,
      [{ op: 'replace', path: '/enabled', value: true }],
      { contentType: 'application/json-patch+json' },
    );
  }
}

/**
 * Shape an exported workflow for POST/PUT.
 * Exports carry `creator`; the write API requires `owner` and rejects an owner
 * change that only sends `creator`.
 */
export function toWorkflowWriteBody(body, { id } = {}) {
  const payload = { ...body };
  if (!payload.owner && payload.creator) {
    payload.owner = payload.creator;
  }
  delete payload.creator;
  if (id) payload.id = id;
  return payload;
}

export function normalizeBaseUrl(url) {
  return String(url ?? '').trim().replace(/\/+$/, '');
}

export function deriveUiUrl(apiUrl) {
  // https://tenant.api.identitynow.com → https://tenant.identitynow.com
  // https://tenant.api.identitynow-demo.com → https://tenant.identitynow-demo.com
  return normalizeBaseUrl(apiUrl).replace('.api.identitynow', '.identitynow');
}

/**
 * Derive the ISC API base from a tenant (UI) URL.
 * https://tenant.identitynow.com → https://tenant.api.identitynow.com
 * https://tenant.identitynow-demo.com → https://tenant.api.identitynow-demo.com
 * Already-api hosts are left unchanged.
 */
export function deriveApiUrl(tenantUrl) {
  const base = normalizeBaseUrl(tenantUrl);
  if (base.includes('.api.identitynow')) return base;
  return base.replace('.identitynow', '.api.identitynow');
}

export function deriveTenantName(url) {
  try {
    // tenant.identitynow.com and tenant.api.identitynow.com both start with the tenant label
    return new URL(normalizeBaseUrl(url)).hostname.split('.')[0];
  } catch {
    return 'tenant';
  }
}
