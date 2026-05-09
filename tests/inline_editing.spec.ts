import { test, expect } from './fixtures';

test('inline editing of transactions', async ({ authedPage: page }) => {
  await page.goto('/accounts');
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

test('inline editing blur save', async ({ authedPage: page }) => {
  await page.goto('/accounts');
  await expect(page).toHaveURL(/\/accounts\/\d+/);
  
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

test('inline editing cancel', async ({ authedPage: page }) => {
  await page.goto('/accounts');
  await expect(page).toHaveURL(/\/accounts\/\d+/);
  
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

test('inline editing with escape key', async ({ authedPage: page }) => {
  await page.goto('/accounts');
  await expect(page).toHaveURL(/\/accounts\/\d+/);
  
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

test('inline editing with enter key', async ({ authedPage: page }) => {
  await page.goto('/accounts');
  await expect(page).toHaveURL(/\/accounts\/\d+/);
  
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

test('save button submits via Turbo and does not render raw turbostream HTML', async ({ authedPage: page }) => {
  await page.goto('/accounts');
  await expect(page).toHaveURL(/\/accounts\/\d+/);

  const firstRow = page.locator('tr[data-txn-id]').first();
  await firstRow.click();
  await expect(page.locator('.transaction-row--editing')).toBeVisible();

  // Change memo to a distinct value so we can verify it appears in the row
  const testMemo = `Regression test ${Date.now()}`;
  await page.getByRole('textbox', { name: /memo/i }).fill(testMemo);

  await page.getByRole('button', { name: 'Save' }).click();

  // If form.submit() (not requestSubmit()) is used, Turbo is bypassed and the
  // browser renders the raw turbostream response as text. Assert it is absent.
  await expect(page.locator('body')).not.toContainText('<turbo-stream');
  await expect(page.locator('body')).not.toContainText('action="replace"');

  // Verify edit mode is gone and the updated memo appears in the read-only row
  await expect(page.locator('.transaction-row--editing')).not.toBeVisible();
  await expect(page.locator('tr.transaction-row td').filter({ hasText: testMemo })).toBeVisible();
});

test('blur save submits via Turbo and does not render raw turbostream HTML', async ({ authedPage: page }) => {
  await page.goto('/accounts');
  await expect(page).toHaveURL(/\/accounts\/\d+/);

  const firstRow = page.locator('tr[data-txn-id]').first();
  await firstRow.click();
  await expect(page.locator('.transaction-row--editing')).toBeVisible();

  // Change memo then blur out of all form inputs to trigger the blur-save path
  const testMemo = `Blur regression ${Date.now()}`;
  await page.getByRole('textbox', { name: /memo/i }).fill(testMemo);
  await page.getByRole('textbox', { name: /memo/i }).blur();

  // Same assertion: no raw turbostream text on the page
  await expect(page.locator('body')).not.toContainText('<turbo-stream');
  await expect(page.locator('body')).not.toContainText('action="replace"');

  await expect(page.locator('.transaction-row--editing')).not.toBeVisible();
  await expect(page.locator('tr.transaction-row td').filter({ hasText: testMemo })).toBeVisible();
});
