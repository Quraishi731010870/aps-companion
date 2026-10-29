import { expect, test } from '@playwright/test';
import { AdminClient } from '../../support/admin-client';
import { MobileClient } from '../../support/mobile-client';

test.describe('mobile app → backend → admin', () => {
  let mobile: MobileClient;
  let admin: AdminClient;

  test.beforeAll(async () => {
    mobile = await MobileClient.signIn();
    admin = await AdminClient.signIn();
  });
  test.afterAll(async () => {
    await mobile?.dispose();
    await admin?.dispose();
  });

  test('the customer sees their own wallet', async () => {
    const wallet = await mobile.wallet();
    expect(wallet.walletId).toMatch(/^WALLET-[A-Z0-9]{4,20}$/);
    expect(wallet.currency).toBe('AFN');
    expect(typeof wallet.availableBalance).toBe('number');
  });

  test('a payment made in the app is visible to the admin', async () => {
    const payment = await mobile.pay(123.45);
    expect(payment.status).toBe('PENDING');

    // The customer's own history has it.
    const own = await (await mobile.get('/api/v1/transactions?page=0&pageSize=10')).json();
    expect(own.items.map((item: { id: string }) => item.id)).toContain(payment.id);

    // The admin finds it by id, with what the app sent.
    const search = await admin.get(`/api/v1/transactions?transactionId=${encodeURIComponent(payment.id)}`);
    expect(search.status()).toBe(200);
    const [row] = (await search.json()).items;
    expect(row).toMatchObject({ id: payment.id, status: 'pending', channel: 'MOBILE', amount: 123.45, currency: 'AFN', destination: payment.destination, customer: 'Demo Customer 001' });

    const detail = await (await admin.get(`/api/v1/transactions/${encodeURIComponent(payment.id)}`)).json();
    expect(detail.timeline.map((event: { label: string }) => event.label)).toContain('CREATED');
  });

  test('the admin dashboard answers', async () => {
    const summary = await admin.get('/api/v1/dashboard/summary');
    expect(summary.status()).toBe(200);
  });

  test('a customer cannot use admin endpoints', async () => {
    expect((await mobile.get('/api/v1/customers')).status()).toBe(403);
    expect((await mobile.get('/api/v1/features')).status()).toBe(403);
  });
});
