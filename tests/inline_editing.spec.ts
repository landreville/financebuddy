import { test, expect } from '@playwright/test';

test('inline editing of transactions', async ({ page }) => {
  // Login
  await page.goto('/test/login');
  await expect(page.getByText('Success')).toBeVisible();

  // Navigate to accounts page
  await page.goto('/accounts/1');
  await expect(page).toHaveURL(/\/accounts\/\d+/);

  // Click on a transaction row to enter edit mode
  const firstRow = page.locator('tr[data-txn-id]').first();
  await firstRow.click();
  
  // Verify edit mode is active
  await expect(page.locator('.transaction-row--editing')).toBeVisible();
  
  // Verify form inputs are present
  await expect(page.getByRole('textbox', { name: /date/i })).toBeVisible();
  await expect(page.getByRole('combobox', { name: /payee/i })).toBeVisible();
  await expect(page.getByRole('combobox', { name: /category/i })).toBeVisible();
  await expect(page.getByRole('textbox', { name: /memo/i })).toBeVisible();
  
  // Save the transaction
  await page.getByRole('button', { name: 'Save' }).click();
  
  // Verify we're back to read mode
  await expect(page.locator('.transaction-row--editing')).not.toBeVisible();
});

test('inline editing blur save', async ({ page }) => {
  // Login
  await page.goto('/test/login');
  await expect(page.getByText('Success')).toBeVisible();

  // Navigate to accounts page
  await page.goto('/accounts/1');
  
  // Click on a transaction row
  const firstRow = page.locator('tr[data-txn-id]').first();
  await firstRow.click();
  
  // Verify edit mode is active
  await expect(page.locator('.transaction-row--editing')).toBeVisible();
  
  // Blur the date field to trigger save
  await page.getByRole('textbox', { name: /date/i }).blur();
  
  // Verify we're back to read mode
  await expect(page.locator('.transaction-row--editing')).not.toBeVisible();
});

test('inline editing cancel', async ({ page }) => {
  // Login
  await page.goto('/test/login');
  await expect(page.getByText('Success')).toBeVisible();

  // Navigate to accounts page
  await page.goto('/accounts/1');
  
  // Click on a transaction row
  const firstRow = page.locator('tr[data-txn-id]').first();
  await firstRow.click();
  
  // Verify edit mode is active
  await expect(page.locator('.transaction-row--editing')).toBeVisible();
  
  // Click cancel button
  await page.getByRole('button', { name: 'Cancel' }).click();
  
  // Verify we're back to read mode
  await expect(page.locator('.transaction-row--editing')).not.toBeVisible();
});

test('inline editing with escape key', async ({ page }) => {
  // Login
  await page.goto('/test/login');
  await expect(page.getByText('Success')).toBeVisible();

  // Navigate to accounts page
  await page.goto('/accounts/1');
  
  // Click on a transaction row
  const firstRow = page.locator('tr[data-txn-id]').first();
  await firstRow.click();
  
  // Verify edit mode is active
  await expect(page.locator('.transaction-row--editing')).toBeVisible();
  
  // Press escape key
  await page.keyboard.press('Escape');
  
  // Verify we're back to read mode
  await expect(page.locator('.transaction-row--editing')).not.toBeVisible();
});

test('inline editing with enter key', async ({ page }) => {
  // Login
  await page.goto('/test/login');
  await expect(page.getByText('Success')).toBeVisible();

  // Navigate to accounts page
  await page.goto('/accounts/1');
  
  // Click on a transaction row
  const firstRow = page.locator('tr[data-txn-id]').first();
  await firstRow.click();
  
  // Verify edit mode is active
  await expect(page.locator('.transaction-row--editing')).toBeVisible();
  
  // Press enter key
  await page.keyboard.press('Enter');
  
  // Verify we're back to read mode
  await expect(page.locator('.transaction-row--editing')).not.toBeVisible();
});
