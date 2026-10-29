import { expect, test } from '@playwright/test';
import { AdminClient, mobileFeature } from '../../support/admin-client';
import { signInToPortal } from '../../support/portal';

const key = 'cash_out';

test('switching a flag in the portal changes the mobile configuration', async ({ page }) => {
  const original = await mobileFeature(key);
  expect(original, `feature flag ${key} must exist`).toBeDefined();
  try {
    await signInToPortal(page);
    await page.goto('/app/configuration');
    await expect(page.getByRole('heading', { name: 'Application configuration' })).toBeVisible();
    const toggle = page.locator('.MuiStack-root', { has: page.getByText(new RegExp(`^${key} ·`)) }).last().getByRole('checkbox');

    // The switch is controlled: it flips once the backend has saved the change.
    await toggle.click();
    await expect(toggle).toBeChecked({ checked: !original });
    await expect.poll(() => mobileFeature(key)).toBe(!original);

    await toggle.click();
    await expect(toggle).toBeChecked({ checked: Boolean(original) });
    await expect.poll(() => mobileFeature(key)).toBe(original);
  } finally {
    // Never leave the flag changed, even if an assertion failed.
    const admin = await AdminClient.signIn();
    await admin.setFeature(key, Boolean(original));
    await admin.dispose();
  }
});
