import { expect, request, type APIRequestContext, type APIResponse } from '@playwright/test';
import { env } from './env';

/**
 * The admin portal's view of the API, through the portal's own nginx proxy:
 * cookie session plus CSRF header, exactly as the browser app does it.
 */
export class AdminClient {
  private constructor(private readonly api: APIRequestContext, private readonly csrf: string) {}

  static async signIn(): Promise<AdminClient> {
    const api = await request.newContext({ baseURL: env.portalUrl });
    const { csrfToken } = await (await api.get('/api/admin/v1/auth/csrf')).json();
    const response = await api.post('/api/admin/v1/auth/login', {
      data: { operator: env.adminEmail, password: env.adminPassword },
      headers: { 'X-CSRF-Token': csrfToken },
    });
    expect(response.status(), await response.text()).toBe(201);
    return new AdminClient(api, csrfToken);
  }

  get(path: string): Promise<APIResponse> { return this.api.get(path); }

  put(path: string, data: object): Promise<APIResponse> {
    return this.api.put(path, { data, headers: { 'X-CSRF-Token': this.csrf } });
  }

  async setFeature(key: string, enabled: boolean): Promise<void> {
    const response = await this.put(`/api/v1/features/${key}`, { enabled });
    expect(response.status(), await response.text()).toBe(200);
  }

  dispose(): Promise<void> { return this.api.dispose(); }
}

/** Public mobile configuration, as the app fetches it. */
export async function mobileFeature(key: string): Promise<boolean | undefined> {
  const api = await request.newContext({ baseURL: env.apiUrl });
  try {
    const json = await (await api.get('/api/v1/configuration/mobile/current')).json();
    return (json.features as Array<{ key: string; enabled: boolean }>).find((feature) => feature.key === key)?.enabled;
  } finally {
    await api.dispose();
  }
}
