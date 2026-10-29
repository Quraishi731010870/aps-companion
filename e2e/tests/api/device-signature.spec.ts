import { expect, test } from '@playwright/test';
import { TestDevice } from '../../support/device';
import { MobileClient } from '../../support/mobile-client';

test.describe('device signatures on the live stack', () => {
  let mobile: MobileClient;

  test.beforeAll(async () => { mobile = await MobileClient.signIn(); });
  test.afterAll(async () => { await mobile?.dispose(); });

  const code = async (response: { json(): Promise<{ code?: string }> }) => (await response.json()).code;

  test('a signed request is accepted', async () => {
    expect((await mobile.get('/api/v1/wallet')).status()).toBe(200);
  });

  test('an unsigned request is rejected', async () => {
    const response = await mobile.get('/api/v1/wallet', null);
    expect(response.status()).toBe(401);
    expect(await code(response)).toBe('DEVICE_SIGNATURE_REQUIRED');
  });

  test('changing the amount after signing is rejected', async () => {
    const body = mobile.paymentBody((await mobile.wallet()).walletId, 10);
    const response = await mobile.post('/api/v1/transactions', { ...body, amount: 9999 }, { signedBody: JSON.stringify(body) });
    expect(response.status()).toBe(401);
    expect(await code(response)).toBe('DEVICE_SIGNATURE_INVALID');
  });

  test('a replayed request is rejected', async () => {
    const signature = mobile.device.sign('GET', '/api/v1/wallet');
    expect((await mobile.get('/api/v1/wallet', signature)).status()).toBe(200);
    const replay = await mobile.get('/api/v1/wallet', signature);
    expect(replay.status()).toBe(401);
    expect(await code(replay)).toBe('DEVICE_SIGNATURE_REPLAYED');
  });

  test('a stale timestamp is rejected', async () => {
    const response = await mobile.get('/api/v1/wallet', mobile.device.sign('GET', '/api/v1/wallet', '', { timestamp: String(Date.now() - 10 * 60_000) }));
    expect(response.status()).toBe(401);
    expect(await code(response)).toBe('DEVICE_SIGNATURE_EXPIRED');
  });

  test("another device's key cannot use this session", async () => {
    const response = await mobile.get('/api/v1/wallet', new TestDevice('e2e-other-device').sign('GET', '/api/v1/wallet'));
    expect(response.status()).toBe(401);
    expect(await code(response)).toBe('DEVICE_SIGNATURE_INVALID');
  });
});
