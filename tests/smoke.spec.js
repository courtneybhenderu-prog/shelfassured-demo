const { test, expect } = require('@playwright/test');

test('brand onboarding smoke test', async ({ page }) => {
  const base = 'http://127.0.0.1:8081/brand-onboarding.html';
  await page.goto(base, { waitUntil: 'domcontentloaded' });

  // Page basic checks
  await expect(page).toHaveTitle(/Brand Onboarding|ShelfAssured/);
  await expect(page.locator('h1')).toHaveText('Brand Onboarding');

  // Fill brand name
  await page.fill('#brand_name', 'Test Brand Co');

  // Move to Products step
  await page.click('#nextStep');
  await page.waitForSelector('#addProduct', { state: 'visible' });

  // Add product
  await page.click('#addProduct');
  // Fill last product fields
  const productCards = page.locator('#products .pill');
  const lastProduct = productCards.nth(-1);
  await lastProduct.locator('[data-k="name"]').fill('Test Product');
  await lastProduct.locator('[data-k="barcode"]').fill('123456789012');

  // Move to Stores step
  await page.click('#nextStep');
  await page.waitForSelector('#addStore', { state: 'visible' });

  // Add store
  await page.click('#addStore');
  const storeCards = page.locator('#stores .pill');
  const lastStore = storeCards.nth(-1);
  await lastStore.locator('[data-k="name"]').fill('Test Store');
  await lastStore.locator('[data-k="city"]').fill('Test City');

  // Verify summary counts update (wait for autosave debounce maybe)
  await page.waitForTimeout(500);
  const productsText = await page.locator('#summary-products').textContent();
  const storesText = await page.locator('#summary-stores').textContent();
  if (!productsText.includes('1')) throw new Error('Products count not updated: ' + productsText);
  if (!storesText.includes('1')) throw new Error('Stores count not updated: ' + storesText);

  // Click Save Draft and verify localStorage
  await page.click('#saveDraft');
  await page.waitForTimeout(300);

  const draft = await page.evaluate(() => localStorage.getItem('brandDraft'));
  if (!draft) throw new Error('brandDraft not found in localStorage');
  const parsed = JSON.parse(draft);
  if (parsed.brand.name !== 'Test Brand Co') throw new Error('Brand name mismatch in draft');
  if (!Array.isArray(parsed.products) || parsed.products.length < 1) throw new Error('Products not saved in draft');
  if (!Array.isArray(parsed.stores) || parsed.stores.length < 1) throw new Error('Stores not saved in draft');

  // Cleanup: remove draft
  await page.evaluate(() => localStorage.removeItem('brandDraft'));
});
