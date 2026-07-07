import { chromium } from 'playwright';
import fs from 'fs';
import path from 'path';

const OUT = path.resolve('flutter');
if (!fs.existsSync(OUT)) fs.mkdirSync(OUT, { recursive: true });

const URL = 'http://127.0.0.1:54321/';
const V = { width: 390, height: 844 };

const ADMIN = { email: 'admin@mysumber.my', password: 'AdminPass123' };
const WORKER = { email: 'worker@mysumber.my', password: 'WorkerPass123' };

const ROLE_Y = { admin: 416, worker: 487, customer: 558 };

async function snap(page, name) {
  await page.waitForTimeout(1500);
  await page.screenshot({ path: path.join(OUT, name + '.png'), fullPage: false });
  console.log('[snap]', name);
}

async function tap(page, x, y) {
  await page.tap('body', { position: { x, y } });
}

async function enableSemantics(page) {
  await page.evaluate(() => {
    const el = document.querySelector('[flt-semantics-placeholder], [aria-label="Enable accessibility"]');
    if (el) el.click();
  });
  await page.waitForTimeout(1500);
}

async function clickByText(page, text) {
  // Semantics-enabled Flutter button click via Playwright locator (dispatches real pointer events)
  const locator = page.locator(`flt-semantics:has-text("${text}")`).first();
  await locator.waitFor({ state: 'attached', timeout: 8000 });
  await locator.click({ force: true });
}

async function newPageCtx(browser) {
  const ctx = await browser.newContext({
    viewport: V, deviceScaleFactor: 2, isMobile: true, hasTouch: true,
  });
  const page = await ctx.newPage();
  return { ctx, page };
}

async function bootstrap(page) {
  console.log('[nav]', URL);
  await page.goto(URL, { waitUntil: 'load', timeout: 90000 });
  await page.waitForTimeout(18000);
  // Do NOT enable semantics before login - it seems to interfere with submitBtn creation
}

async function login(page, role, creds) {
  console.log('[login]', role);
  await tap(page, 195, ROLE_Y[role]);
  await page.waitForTimeout(4500);

  // Focus password field
  await tap(page, 195, 347);
  await page.waitForTimeout(700);
  await page.keyboard.type(creds.password, { delay: 60 });
  await page.waitForTimeout(600);

  // Trigger Flutter's virtual keyboard submit input (fires onSubmitted)
  const submitted = await page.evaluate(() => {
    const btn = document.querySelector('input.submitBtn')
      || document.querySelector('input[type="submit"]');
    if (btn) {
      btn.click();
      return { ok: true };
    }
    return {
      ok: false,
      allInputs: Array.from(document.querySelectorAll('input')).map(i => ({
        type: i.type, className: i.className, value: i.value ? '[filled]' : '[empty]',
      })),
    };
  });
  console.log('[login] submitBtn result:', JSON.stringify(submitted));
  await page.waitForTimeout(13000);
  await enableSemantics(page);
}

(async () => {
  const browser = await chromium.launch({ headless: true });

  try {
    console.log('\n=== ADMIN FLOW ===');
    const { ctx, page } = await newPageCtx(browser);
    await bootstrap(page);
    await login(page, 'admin', ADMIN);
    await snap(page, 'auth_admin_01_dashboard');

    // Bottom nav Alerts (Equipment | Alerts | Oversight)
    await tap(page, 195, 810);
    await page.waitForTimeout(2500);
    await snap(page, 'auth_admin_02_alerts');

    await tap(page, 325, 810);
    await page.waitForTimeout(2500);
    await snap(page, 'auth_admin_03_oversight_queue');

    await enableSemantics(page);
    try { await clickByText(page, 'Reports'); } catch (e) { console.log('[reports-tab] fallback:', e.message); await tap(page, 290, 148); }
    await page.waitForTimeout(2500);
    await snap(page, 'auth_admin_04_oversight_reports');

    await ctx.close();
  } catch (e) {
    console.log('[admin-flow-error]', e.message);
  }

  try {
    console.log('\n=== WORKER FLOW ===');
    const { ctx, page } = await newPageCtx(browser);
    await bootstrap(page);
    await login(page, 'worker', WORKER);
    await snap(page, 'auth_worker_01_water_home');

    // Alert Queue card
    await tap(page, 195, 350);
    await page.waitForTimeout(3500);
    await snap(page, 'auth_worker_02_alert_queue');

    await tap(page, 195, 280);
    await page.waitForTimeout(3000);
    await snap(page, 'auth_worker_03_alert_detail');
    await tap(page, 24, 44);
    await page.waitForTimeout(1800);

    await tap(page, 24, 44);
    await page.waitForTimeout(1800);

    await tap(page, 195, 480);
    await page.waitForTimeout(3500);
    await snap(page, 'auth_worker_04_report_history');
    await tap(page, 24, 44);
    await page.waitForTimeout(1800);

    await tap(page, 292, 810);
    await page.waitForTimeout(2500);
    await snap(page, 'auth_worker_05_electricity_home');

    await ctx.close();
  } catch (e) {
    console.log('[worker-flow-error]', e.message);
  }

  await browser.close();
  console.log('\n[done]');
})();
