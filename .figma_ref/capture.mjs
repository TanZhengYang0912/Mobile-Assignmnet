import { chromium } from 'playwright';
import fs from 'fs';
import path from 'path';

const OUT = path.resolve('.figma_ref');
const URL = 'https://react-omen-82271244.figma.site';

// mobile viewport (Pixel 5-ish)
const MOBILE = { width: 390, height: 844, deviceScaleFactor: 2, isMobile: true, hasTouch: true };

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

  console.log('[nav]', URL);
  await page.goto(URL, { waitUntil: 'networkidle', timeout: 60000 });
  await page.waitForTimeout(3000);

  // Save landing page
  await page.screenshot({ path: path.join(OUT, '00_landing_full.png'), fullPage: true });
  await page.screenshot({ path: path.join(OUT, '00_landing_view.png'), fullPage: false });

  // Dump HTML after JS render
  const html = await page.content();
  fs.writeFileSync(path.join(OUT, 'rendered.html'), html);

  // Extract structural info: all visible text, all clickable elements, links
  const info = await page.evaluate(() => {
    const clickables = [];
    document.querySelectorAll('button, [role="button"], a, [onclick]').forEach((el, i) => {
      const rect = el.getBoundingClientRect();
      if (rect.width === 0 || rect.height === 0) return;
      clickables.push({
        i,
        tag: el.tagName,
        text: (el.innerText || el.textContent || '').trim().slice(0, 120),
        href: el.getAttribute('href') || null,
        role: el.getAttribute('role') || null,
        aria: el.getAttribute('aria-label') || null,
        x: Math.round(rect.x),
        y: Math.round(rect.y),
        w: Math.round(rect.width),
        h: Math.round(rect.height),
      });
    });
    // grab all headings / labels for a quick screen-content map
    const texts = [];
    document.querySelectorAll('h1,h2,h3,h4,h5,h6,label,button,[role="button"],p,span').forEach((el) => {
      const t = (el.innerText || '').trim();
      if (t && t.length < 200) texts.push({ tag: el.tagName, text: t });
    });
    return { clickables, texts };
  });
  fs.writeFileSync(path.join(OUT, 'landing_structure.json'), JSON.stringify(info, null, 2));

  // Try to visit each unique in-app link/button by clicking, take screenshot, then navigate back
  const visited = new Set(['/']);
  const queue = [];
  info.clickables.forEach((c) => {
    if (c.href && c.href.startsWith('/') && !visited.has(c.href)) queue.push({ type: 'href', href: c.href, name: c.text || c.href });
  });
  // also queue any button that looks like a nav item (text-based click), keep dedup
  const clickTargets = info.clickables
    .filter((c) => !c.href && c.text && c.text.length > 0 && c.text.length < 40)
    .slice(0, 30);

  let idx = 1;
  // href-based sub-routes
  for (const item of queue) {
    if (visited.has(item.href)) continue;
    visited.add(item.href);
    const url = new URL(item.href, URL).toString();
    console.log('[nav]', url);
    try {
      await page.goto(url, { waitUntil: 'networkidle', timeout: 30000 });
      await page.waitForTimeout(1500);
      const safe = String(idx).padStart(2, '0') + '_' + item.name.replace(/[^a-z0-9]+/gi, '_').slice(0, 30);
      await page.screenshot({ path: path.join(OUT, safe + '_full.png'), fullPage: true });
      await page.screenshot({ path: path.join(OUT, safe + '_view.png'), fullPage: false });
      idx++;
    } catch (e) {
      console.log('[skip]', item.href, e.message);
    }
  }

  // click-based navigation (React SPA buttons)
  for (const target of clickTargets) {
    try {
      await page.goto(URL, { waitUntil: 'networkidle', timeout: 30000 });
      await page.waitForTimeout(1500);
      const btn = page.locator(`text="${target.text}"`).first();
      if (await btn.count() === 0) continue;
      await btn.click({ timeout: 3000 }).catch(() => {});
      await page.waitForTimeout(1500);
      const safe = 'click_' + String(idx).padStart(2, '0') + '_' + target.text.replace(/[^a-z0-9]+/gi, '_').slice(0, 30);
      await page.screenshot({ path: path.join(OUT, safe + '_full.png'), fullPage: true });
      await page.screenshot({ path: path.join(OUT, safe + '_view.png'), fullPage: false });
      idx++;
      if (idx > 40) break;
    } catch (e) { /* ignore */ }
  }

  await browser.close();
  console.log('[done] captures written to', OUT);
})();
