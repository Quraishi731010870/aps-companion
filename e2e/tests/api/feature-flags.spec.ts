import { expect, test } from '@playwright/test';
import { AdminClient, mobileFeature } from '../../support/admin-client';

test.describe('admin → backend → mobile configuration', () => {
  const key = 'cash_out';
  let admin: AdminClient;
  let original: boolean | undefined;

  test.beforeAll(async () => {
    admin = await AdminClient.signIn();
    original = await mobileFeature(key);
    expect(original, `feature flag ${key} must exist`).toBeDefined();
  });
  test.afterAll(async () => {
    if (original !== undefined) await admin.setFeature(key, original);
    await admin?.dispose();
  });

  test('turning a feature off and on reaches the mobile configuration', async () => {
    await admin.setFeature(key, false);
    expect(await mobileFeature(key)).toBe(false);

    await admin.setFeature(key, true);
    expect(await mobileFeature(key)).toBe(true);
  });
});
