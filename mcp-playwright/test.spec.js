const { test, expect } = require('@playwright/test');

test('basic test', async ({ page }) => {
  await page.goto('https://playwright.dev/');
  const title = await page.title();
  console.log(`Page title: ${title}`);

  // Take a screenshot
  await page.screenshot({ path: 'screenshot.png' });
});
