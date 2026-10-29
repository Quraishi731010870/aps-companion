import { expect, test } from '@playwright/test';
import { env } from '../../support/env';
import { signInToPortal } from '../../support/portal';

test('a wrong password is refused and the right one opens the dashboard', async ({ page }) => {
  await page.goto('/login');
  await page.getByLabel('Email or operator ID').fill(env.adminEmail);
  await page.getByLabel('Password').fill('definitely-not-the-password');
  await page.getByRole('button', { name: 'Sign in', exact: true }).click();
  await expect(page.locator('.MuiAlert-standardError')).toBeVisible();
  await expect(page).toHaveURL(/\/login$/);

  // A successful sign-in also resets the failed-attempt counter.
  await signInToPortal(page);
  await expect(page.getByRole('heading', { name: 'Overview' })).toBeVisible();
  await expect(page.getByText('API RESPONDING')).toBeVisible();
});
