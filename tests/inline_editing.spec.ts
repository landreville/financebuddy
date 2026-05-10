import { test, expect } from './fixtures';

test.describe.configure({ mode: 'serial' });

test('inline editing of transactions', async ({ authedPage: page }) => {
  await page.goto('/accounts');
  await expect(page).toHaveURL(/\/accounts\/\d+/);

  const firstRow = page.locator('tr[data-txn-id]').first();
  await firstRow.click();

  const editRow = page.locator('.transaction-row--editing');
  await expect(editRow).toBeVisible();

  await expect(editRow.getByRole('textbox', { name: /date/i })).toBeVisible();
  await expect(editRow.getByRole('combobox', { name: /payee/i })).toBeVisible();
  await expect(editRow.getByRole('combobox', { name: /category/i })).toBeVisible();
  await expect(editRow.getByRole('textbox', { name: /memo/i })).toBeVisible();

  await editRow.getByRole('button', { name: 'Save' }).click();

  await expect(editRow).not.toBeVisible();
});

test('inline editing blur save', async ({ authedPage: page }) => {
  await page.goto('/accounts');
  await expect(page).toHaveURL(/\/accounts\/\d+/);

  const firstRow = page.locator('tr[data-txn-id]').first();
  await firstRow.click();

  const editRow = page.locator('.transaction-row--editing');
  await expect(editRow).toBeVisible();

  // Focus the date field, then click outside the edit row to trigger blur-save
  await editRow.getByRole('textbox', { name: /date/i }).focus();
  await page.locator('h1').click();

  await expect(editRow).not.toBeVisible();
});

test('inline editing cancel', async ({ authedPage: page }) => {
  await page.goto('/accounts');
  await expect(page).toHaveURL(/\/accounts\/\d+/);

  const firstRow = page.locator('tr[data-txn-id]').first();
  await firstRow.click();

  const editRow = page.locator('.transaction-row--editing');
  await expect(editRow).toBeVisible();

  await editRow.getByRole('button', { name: 'Cancel' }).click();

  await expect(editRow).not.toBeVisible();
});

test('inline editing with escape key', async ({ authedPage: page }) => {
  await page.goto('/accounts');
  await expect(page).toHaveURL(/\/accounts\/\d+/);

  const firstRow = page.locator('tr[data-txn-id]').first();
  await firstRow.click();

  const editRow = page.locator('.transaction-row--editing');
  await expect(editRow).toBeVisible();

  await editRow.getByRole('textbox', { name: /date/i }).focus();
  await page.keyboard.press('Escape');

  await expect(editRow).not.toBeVisible();
});

test('inline editing with enter key', async ({ authedPage: page }) => {
  await page.goto('/accounts');
  await expect(page).toHaveURL(/\/accounts\/\d+/);

  const firstRow = page.locator('tr[data-txn-id]').first();
  await firstRow.click();

  const editRow = page.locator('.transaction-row--editing');
  await expect(editRow).toBeVisible();

  await editRow.getByRole('textbox', { name: /date/i }).focus();
  await page.keyboard.press('Enter');

  await expect(editRow).not.toBeVisible();
});

test('save button submits via Turbo and does not render raw turbostream HTML', async ({ authedPage: page }) => {
  await page.goto('/accounts');
  await expect(page).toHaveURL(/\/accounts\/\d+/);

  const firstRow = page.locator('tr[data-txn-id]').first();
  await firstRow.click();

  const editRow = page.locator('.transaction-row--editing');
  await expect(editRow).toBeVisible();

  const testMemo = `Regression test ${Date.now()}`;
  await editRow.getByRole('textbox', { name: /memo/i }).fill(testMemo);

  await editRow.getByRole('button', { name: 'Save' }).click();

  await expect(page.locator('body')).not.toContainText('<turbo-stream');
  await expect(page.locator('body')).not.toContainText('action="replace"');

  await expect(editRow).not.toBeVisible();
  await expect(page.locator('tr.transaction-row td').filter({ hasText: testMemo })).toBeVisible();
});

test('blur save submits via Turbo and does not render raw turbostream HTML', async ({ authedPage: page }) => {
  await page.goto('/accounts');
  await expect(page).toHaveURL(/\/accounts\/\d+/);

  const firstRow = page.locator('tr[data-txn-id]').first();
  await firstRow.click();

  const editRow = page.locator('.transaction-row--editing');
  await expect(editRow).toBeVisible();

  const testMemo = `Blur regression ${Date.now()}`;
  await editRow.getByRole('textbox', { name: /memo/i }).fill(testMemo);
  await editRow.getByRole('textbox', { name: /memo/i }).blur();

  await expect(page.locator('body')).not.toContainText('<turbo-stream');
  await expect(page.locator('body')).not.toContainText('action="replace"');

  await expect(editRow).not.toBeVisible();
  await expect(page.locator('tr.transaction-row td').filter({ hasText: testMemo })).toBeVisible();
});
