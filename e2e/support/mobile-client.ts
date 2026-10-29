import { expect, request, type APIRequestContext, type APIResponse } from '@playwright/test';
import { randomUUID } from 'node:crypto';
import { TestDevice } from './device';
import { E2E_MARKER, env } from './env';

export interface Wallet { walletId: string; currency: string; availableBalance: number }
export interface CreatedTransaction { id: string; status: string }

/** The mobile app's view of the API: device-bound customer session, every request signed. */
export class MobileClient {
  private constructor(private readonly api: APIRequestContext, readonly device: TestDevice, private accessToken: string) {}

  /** Signs in as the seeded test customer unless other credentials are given. */
  static async signIn(device = new TestDevice(), credentials = { phone: env.customerPhone, password: env.customerPassword }): Promise<MobileClient> {
    return MobileClient.start('/api/v1/auth/login', { identifier: credentials.phone, password: credentials.password }, device);
  }

  /** Self sign-up; returns a client signed in as the new customer. */
  static async register(customer: { displayName: string; phone: string; password: string }, device = new TestDevice()): Promise<MobileClient> {
    return MobileClient.start('/api/v1/auth/register', customer, device);
  }

  /** Raw signed POST to an auth endpoint, for asserting failures. */
  static async authRequest(path: string, body: object, device = new TestDevice()): Promise<APIResponse> {
    const api = await request.newContext({ baseURL: env.apiUrl });
    const data = JSON.stringify({ ...body, device: device.binding() });
    return api.post(path, { data, headers: { 'Content-Type': 'application/json', ...device.sign('POST', path, data) } });
  }

  private static async start(path: string, body: object, device: TestDevice): Promise<MobileClient> {
    const api = await request.newContext({ baseURL: env.apiUrl });
    const data = JSON.stringify({ ...body, device: device.binding() });
    const response = await api.post(path, { data, headers: { 'Content-Type': 'application/json', ...device.sign('POST', path, data) } });
    expect(response.status(), await response.text()).toBe(201);
    const json = await response.json();
    expect(json.principal.type).toBe('MOBILE_USER');
    return new MobileClient(api, device, json.accessToken);
  }

  get(path: string, signature: Record<string, string> | null = this.device.sign('GET', path)): Promise<APIResponse> {
    return this.api.get(path, { headers: { Authorization: `Bearer ${this.accessToken}`, ...(signature ?? {}) } });
  }

  /** [signedBody] lets a test sign one body and send another. */
  post(path: string, body: object, { signedBody, signature }: { signedBody?: string; signature?: Record<string, string> } = {}): Promise<APIResponse> {
    const data = JSON.stringify(body);
    return this.api.post(path, {
      data,
      headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${this.accessToken}`, ...(signature ?? this.device.sign('POST', path, signedBody ?? data)) },
    });
  }

  async wallet(): Promise<Wallet> {
    const response = await this.get('/api/v1/wallet');
    expect(response.status()).toBe(200);
    return response.json();
  }

  /** A Purchase (774) to an E2E-tagged merchant, so teardown can find it. */
  paymentBody(walletId: string, amount: number) {
    return {
      transactionType: 774,
      source: walletId,
      destination: `${E2E_MARKER}-MERCHANT-${Date.now()}`,
      amount,
      currency: 'AFN',
      reference: 'e2e test purchase',
      idempotencyKey: randomUUID(),
    };
  }

  async pay(amount: number): Promise<CreatedTransaction & { destination: string }> {
    const body = this.paymentBody((await this.wallet()).walletId, amount);
    const response = await this.post('/api/v1/transactions', body);
    expect(response.status(), await response.text()).toBe(201);
    return { ...(await response.json()), destination: body.destination };
  }

  dispose(): Promise<void> { return this.api.dispose(); }
}
