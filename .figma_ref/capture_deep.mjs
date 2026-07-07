import { chromium } from 'playwright';
import fs from 'fs';
import path from 'path';

const OUT = path.resolve('..', '.figma_ref');
const URL = 'https://react-omen-82271244.figma.site';

const MOBILE = { width: 390, height: 844, deviceScaleFactor: 2, isMobile: true, hasTouch: true };

async function snap(page, name) {
  await page.waitForTimeout(1200);
  const p = path.join(OUT, name + '.png');
  await page.screenshot({ path: p, fullPage: true });
  console.log('[snap]', p);
}

async function goHome(page) {
  await page.goto(URL, { waitUntil: 'networkidle', timeout: 60000 });
  await page.waitForTimeout(1500);
}

async function pickRole(page, role) {
  await goHome(page);
  const btn = page.locator(`text="Continue as ${role}"`).first();
  await btn.click({ timeout: 5000 });
  await page.waitForTimeout(1500);
}

async function tryClick(page, textOrLocator, waitMs = 1500) {
  try {
    const loc = typeof textOrLocator === 'string'
      ? page.locator(textOrLocator).first()
      : textOrLocator;
    if (await loc.count() === 0) return false;
    await loc.scrollIntoViewIfNeeded().catch(()=>{});
    await loc.click({ timeout: 3000 });
    await page.waitForTimeout(waitMs);
    return true;
  } catch (e) {
    console.log('[click-fail]', e.message);
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
    userAgent: 'Mozilla/5.0 (Linux; Android 13; Pixel 5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36',
  });
  const page = await ctx.newPage();

  // ==== CUSTOMER ====
  await pickRole(page, 'Customer');
  await snap(page, '10_customer_home');
  // Try tabs on customer (usually Usage / Report)
  for (const label of ['Report', 'Compare', 'Usage', 'Problem', 'Submit']) {
    const loc = page.locator(`text="${label}"`).first();
    if (await loc.count() > 0) {
      await loc.click({ timeout: 3000 }).catch(()=>{});
      await page.waitForTimeout(1500);
      await snap(page, '11_customer_' + label.toLowerCase());
      // go back to customer home via bottom nav or role
      await pickRole(page, 'Customer');
    }
  }

  // ==== WORKER deep dive ====
  await pickRole(page, 'Worker');
  await snap(page, '20_worker_water_home');

  // Click View button on Alert Queue
  if (await tryClick(page, 'text="View"')) {
    await snap(page, '21_worker_alert_queue');
    // Click first alert row
    const firstRow = page.locator('button, [role="button"], div').filter({ hasText: /Household|Pahang|H-/i }).first();
    if (await tryClick(page, firstRow)) {
      await snap(page, '22_worker_alert_detail');
      // Try "Submit Report" / "Create Report" / "Investigate"
      for (const t of ['Submit Report', 'Create Report', 'Investigate', 'Start Investigation', 'File Report']) {
        if (await tryClick(page, `text="${t}"`)) {
          await snap(page, '23_worker_report_form_' + t.replace(/\s+/g,'_'));
          break;
        }
      }
    }
  }

  // Report History
  await pickRole(page, 'Worker');
  const rh = page.locator('text=/REPORT HISTORY/i').first();
  if (await rh.count() > 0) {
    await rh.click({ timeout: 3000 }).catch(()=>{});
    await page.waitForTimeout(1500);
    await snap(page, '24_worker_report_history');
  }

  // Latest Alert click
  await pickRole(page, 'Worker');
  const la = page.locator('text=/LATEST ALERT/i').first();
  if (await la.count() > 0) {
    // click the container (parent)
    const parent = la.locator('xpath=ancestor::*[self::div or self::button][1]');
    if (await tryClick(page, parent)) {
      await snap(page, '25_worker_latest_alert_detail');
    }
  }

  // Switch to Electricity bottom tab
  await pickRole(page, 'Worker');
  if (await tryClick(page, 'text="Electricity"')) {
    await snap(page, '26_worker_electricity');
  }

  // ==== ADMIN deep dive ====
  await pickRole(page, 'Admin');
  await snap(page, '30_admin_equipment_home');

  // Alerts bottom tab
  if (await tryClick(page, 'text="Alerts"')) {
    await snap(page, '31_admin_alerts');
  }

  // Oversight bottom tab
  await pickRole(page, 'Admin');
  if (await tryClick(page, 'text="Oversight"')) {
    await snap(page, '32_admin_oversight');
  }

  // Filter chips
  await pickRole(page, 'Admin');
  for (const chip of ['Water (2)', 'Electricity (1)']) {
    const c = page.locator(`text="${chip}"`).first();
    if (await c.count() > 0) {
      await c.click({ timeout: 3000 }).catch(()=>{});
      await page.waitForTimeout(1200);
      await snap(page, '33_admin_filter_' + chip.replace(/[^a-z]/gi,'_').toLowerCase());
    }
  }

  // Equipment row click
  await pickRole(page, 'Admin');
  // Scroll down to reach equipment list
  await page.evaluate(() => window.scrollTo(0, document.body.scrollHeight));
  await page.waitForTimeout(1000);
  await snap(page, '34_admin_scrolled');
  const items = page.locator('button, [role="button"]');
  const count = await items.count();
  for (let i = 0; i < Math.min(count, 15); i++) {
    const t = (await items.nth(i).innerText().catch(()=>'')).toLowerCase();
    if (t.includes('meter') || t.includes('pump') || t.includes('sensor') || t.includes('node')) {
      await items.nth(i).click({ timeout: 3000 }).catch(()=>{});
      await page.waitForTimeout(1200);
      await snap(page, '35_admin_equipment_detail_' + i);
      break;
    }
  }

  // Import button
  await pickRole(page, 'Admin');
  if (await tryClick(page, 'text="Import"')) {
    await snap(page, '36_admin_import');
  }

  await browser.close();
  console.log('[done]');
})();
