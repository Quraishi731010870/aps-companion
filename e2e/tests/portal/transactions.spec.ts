import { expect, test } from '@playwright/test';
import { MobileClient } from '../../support/mobile-client';
import { signInToPortal } from '../../support/portal';

test('a payment from the app shows up in the portal with its timeline', async ({ page }) => {
  const mobile = await MobileClient.signIn();
  const payment = await mobile.pay(77);
  await mobile.dispose();

  await signInToPortal(page);
  await page.goto('/app/transactions');
  await page.getByLabel('Transaction ID, RRN or reference').fill(payment.id);
  await page.getByRole('button', { name: 'Search', exact: true }).click();

  const row = page.getByRole('row').filter({ hasText: payment.id });
  await expect(row).toBeVisible();
  await row.click();

  await expect(page.getByRole('heading', { name: payment.id })).toBeVisible();
  await expect(page.getByText('CREATED', { exact: true })).toBeVisible();
});
