import { expect, test } from '@playwright/test';
import { randomInt } from 'node:crypto';
import { TestDevice } from '../../support/device';
import { E2E_MARKER } from '../../support/env';
import { MobileClient } from '../../support/mobile-client';

test.describe('self sign-up', () => {
  test.describe.configure({ mode: 'serial' });
  const customer = {
    displayName: `${E2E_MARKER} Sign-up ${Date.now()}`,
    // +9379 followed by 7 digits: a valid but unlikely number.
    phone: `+9379${String(randomInt(0, 10_000_000)).padStart(7, '0')}`,
    password: 'e2e-password-123',
  };

  test('a new customer gets an empty wallet and can sign in again', async () => {
    const registered = await MobileClient.register(customer, new TestDevice('e2e-signup-device'));
    const wallet = await registered.wallet();
    expect(wallet).toMatchObject({ currency: 'AFN', availableBalance: 0 });
    expect(wallet.walletId).toMatch(/^WALLET-[A-Z0-9]{10}$/);
    await registered.dispose();

    const again = await MobileClient.signIn(new TestDevice('e2e-signup-device'), { phone: customer.phone, password: customer.password });
    expect((await again.wallet()).walletId).toBe(wallet.walletId);
    await again.dispose();
  });

  test('the same phone number cannot register twice', async () => {
    const response = await MobileClient.authRequest('/api/v1/auth/register', customer, new TestDevice('e2e-signup-device'));
    expect(response.status()).toBe(409);
    expect((await response.json()).code).toBe('PHONE_IN_USE');
  });

  test('weak passwords and non-Afghan numbers are refused', async () => {
    for (const body of [{ ...customer, phone: '+15551234567' }, { ...customer, password: 'short' }]) {
      const response = await MobileClient.authRequest('/api/v1/auth/register', body);
      expect(response.status()).toBe(400);
    }
  });
});
