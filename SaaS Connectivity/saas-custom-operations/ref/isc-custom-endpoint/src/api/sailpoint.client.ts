export interface ClientConfig {
  apiBaseUrl: string;
  token: string;
}

export class SailPointClient {
  private apiBaseUrl: string;
  private token: string;

  constructor(config: ClientConfig) {
    if (!config.apiBaseUrl || !config.token) {
      throw new Error('SailPointClient: apiBaseUrl and token are required.');
    }
    this.apiBaseUrl = config.apiBaseUrl;
    this.token = config.token;
  }

  /**
   * Generische Request-Methode nach dem neuen per-Service Versionierungsmodell.
   * 
   * @param service Der API-Service (z.B. 'recommendations', 'sod-policies')
   * @param version Die Version (z.B. 'v1', 'v2')
   * @param endpoint Der spezifische Pfad (z.B. '/request')
   * @param options Fetch-Optionen wie method, body etc.
   * @param experimental Wenn true, wird der 'X-SailPoint-Experimental' Header gesetzt
   */
  async request<T>(
    service: string,
    version: string,
    endpoint: string,
    options: RequestInit = {},
    experimental: boolean = false // <-- Hier als 5. Parameter deklariert
  ): Promise<T> {
    const cleanEndpoint = endpoint.replace(/^\//, '');
    const url = `${this.apiBaseUrl}/${service}/${version}/${cleanEndpoint}`;

    const headers = new Headers(options.headers || {});
    headers.set('Authorization', `Bearer ${this.token}`);
    headers.set('Accept', 'application/json');

    if (options.method && ['POST', 'PUT', 'PATCH'].includes(options.method.toUpperCase())) {
      headers.set('Content-Type', 'application/json');
    }

    // Setzt den Experimental Header, falls explizit angefordert
    if (experimental) {
      headers.set('X-SailPoint-Experimental', 'true');
    }

    const response = await fetch(url, { ...options, headers });

    if (!response.ok) {
      const errorText = await response.text();
      throw new Error(`SailPoint API Error [${response.status}] at ${url}: ${errorText}`);
    }

    if (response.status === 204) {
      return null as T;
    }

    return response.json() as Promise<T>;
  }
}
