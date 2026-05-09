import { test as baseTest, expect } from '@playwright/test';

// Custom test fixture with persistent auth
export const test = baseTest.extend<{
  authedPage: Page;
}>({
  authedPage: async ({ browser }, use) => {
    const context = await browser.newContext();
    const page = await context.newPage();
    
    // Login
    await page.goto('/session/test_login');
    const body = await page.locator('body').textContent();
    if (body?.includes('Success') || body?.includes('"success":true')) {
      // Success
    } else {
      throw new Error(`Unexpected response from /session/test_login: ${body}`);
    }
    
    await use(page);
    
    await context.close();
  },
});

export { expect };
