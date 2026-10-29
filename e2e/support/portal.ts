import { expect, type Page } from '@playwright/test';
import { env } from './env';

/** Signs in through the real login form. */
export async function signInToPortal(page: Page): Promise<void> {
  await page.goto('/login');
  await page.getByLabel('Email or operator ID').fill(env.adminEmail);
  await page.getByLabel('Password').fill(env.adminPassword);
  await page.getByRole('button', { name: 'Sign in', exact: true }).click();
  await expect(page).toHaveURL(/\/app\/dashboard$/);
}
