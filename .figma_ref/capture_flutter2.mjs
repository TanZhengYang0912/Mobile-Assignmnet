import { chromium } from 'playwright';
import fs from 'fs';
import path from 'path';

const OUT = path.resolve('..', '.figma_ref', 'flutter');
if (!fs.existsSync(OUT)) fs.mkdirSync(OUT, { recursive: true });

const URL = 'http://127.0.0.1:54321/';
const V = { width: 390, height: 844 };

async function snap(page, name) {
  await page.waitForTimeout(1500);
  await page.screenshot({ path: path.join(OUT, name + '.png'), fullPage: true });
  console.log('[snap]', name);
}

async function newPageCtx(browser) {
  const ctx = await browser.newContext({
    viewport: V,
    deviceScaleFactor: 2,
    isMobile: true,
    hasTouch: true,
  });
  const page = await ctx.newPage();
  return { ctx, page };
}

(async () => {
  const browser = await chromium.launch({ headless: true });

  // Landing already captured. Test each role flow.

  // === ADMIN FLOW ===
  {
    const { ctx, page } = await newPageCtx(browser);
    await page.goto(URL, { waitUntil: 'load' });
    await page.waitForTimeout(15000);
    // Click Admin button (approx y=416 in viewport)
    await page.mouse.click(195, 416);
    await page.waitForTimeout(2500);
    await snap(page, '01_admin_login');
    // Try Sign In directly (email is pre-filled)
    // Password field is second input, tab to it and type
    await page.keyboard.press('Tab');
    await page.keyboard.press('Tab');
    await page.keyboard.type('admin', { delay: 30 });
    await page.waitForTimeout(500);
    await snap(page, '01b_admin_login_filled');
    await ctx.close();
  }

  // === WORKER FLOW ===
  {
    const { ctx, page } = await newPageCtx(browser);
    await page.goto(URL, { waitUntil: 'load' });
    await page.waitForTimeout(15000);
    await page.mouse.click(195, 487);
    await page.waitForTimeout(2500);
    await snap(page, '10_worker_login');
    await ctx.close();
  }

  // === CUSTOMER FLOW ===
  {
    const { ctx, page } = await newPageCtx(browser);
    await page.goto(URL, { waitUntil: 'load' });
    await page.waitForTimeout(15000);
    await page.mouse.click(195, 558);
    await page.waitForTimeout(2500);
    await snap(page, '20_customer_login');
    await ctx.close();
  }

  await browser.close();
  console.log('[done]');
})();
