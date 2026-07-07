import { chromium } from 'playwright';
import fs from 'fs';
import path from 'path';

const OUT = path.resolve('..', '.figma_ref', 'flutter');
if (!fs.existsSync(OUT)) fs.mkdirSync(OUT, { recursive: true });

const URL = 'http://127.0.0.1:54321/';
const MOBILE = { width: 390, height: 844, deviceScaleFactor: 2, isMobile: true, hasTouch: true };

async function snap(page, name) {
  await page.waitForTimeout(1500);
  const p = path.join(OUT, name + '.png');
  await page.screenshot({ path: p, fullPage: true });
  console.log('[snap]', p);
}

async function click(page, text) {
  try {
    const el = page.getByText(text, { exact: false }).first();
    if (await el.count() === 0) return false;
    await el.scrollIntoViewIfNeeded().catch(()=>{});
    await el.click({ timeout: 5000 });
    await page.waitForTimeout(1500);
    return true;
  } catch (e) {
    console.log('[click-fail]', text, e.message);
    return false;
  }
}

(async () => {
  const browser = await chromium.launch({ headless: true });
  const ctx = await browser.newContext({
    viewport: { width: MOBILE.width, height: MOBILE.height },
    deviceScaleFactor: MOBILE.deviceScaleFactor,
    isMobile: MOBILE.isMobile,
    hasTouch: MOBILE.hasTouch,
  });
  const page = await ctx.newPage();
  page.on('console', msg => {
    if (msg.type() === 'error') console.log('[console-err]', msg.text().slice(0, 150));
  });

  console.log('[nav]', URL);
  await page.goto(URL, { waitUntil: 'load', timeout: 90000 });
  // Flutter web takes time to bootstrap
  await page.waitForTimeout(15000);
  await snap(page, '00_landing');

  // Try clicking each role
  if (await click(page, 'Continue as Admin')) {
    await page.waitForTimeout(2000);
    await snap(page, '01_admin_login');
    // Try type password admin and press Sign In (skip if fails - admin needs valid supabase)
    try {
      const passwordField = page.locator('input[type="password"], input').nth(1);
      await passwordField.fill('admin', { timeout: 3000 });
      await click(page, 'Sign In');
      await page.waitForTimeout(4000);
      await snap(page, '02_admin_dashboard');
    } catch (e) {
      console.log('[admin-login-fail]', e.message);
    }
  }

  // Back to landing
  await page.goto(URL, { waitUntil: 'load' });
  await page.waitForTimeout(5000);

  if (await click(page, 'Continue as Worker')) {
    await page.waitForTimeout(2000);
    await snap(page, '10_worker_login');
  }

  await page.goto(URL, { waitUntil: 'load' });
  await page.waitForTimeout(5000);

  if (await click(page, 'Continue as Customer')) {
    await page.waitForTimeout(2000);
    await snap(page, '20_customer_login');
  }

  await browser.close();
  console.log('[done]');
})();
