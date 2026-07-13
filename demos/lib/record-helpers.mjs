// Shared recording helpers for demo videos.
// Solves: jitter (no wheel back-and-forth), incomplete frames (wait hydration),
// no highlight (spotlight box), no title cards (intro/outro overlays).
//
// All overlays are injected as DOM so they show up in the recorded video.

export const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

const BASE = 'https://d3sx15z6kvxyn3.cloudfront.net';

// Refresh the Playwright storageState by logging in fresh. Call before a long
// recording run (session expires ~1h). Writes to authPath.
export async function refreshAuth(browser, authPath, { user = 'admin', password = 'nexus' } = {}) {
  const ctx = await browser.newContext({ viewport: { width: 1920, height: 1080 } });
  const p = await ctx.newPage();
  await p.goto(BASE + '/login', { waitUntil: 'domcontentloaded' });
  await p.waitForLoadState('networkidle').catch(() => {});
  await sleep(5000);
  const u = await p.$('input[type="text"], input[placeholder*="用户"], input[name*="user" i]');
  const pw = await p.$('input[type="password"]');
  if (u && pw) {
    await u.fill(user); await pw.fill(password);
    await p.click('button:has-text("登录"), button[type="submit"]').catch(() => {});
    await p.waitForLoadState('networkidle').catch(() => {});
    await sleep(5000);
  }
  await ctx.storageState({ path: authPath });
  await ctx.close();
}

// Navigate and wait until the SPA is fully hydrated (avoids blank/partial frames).
export async function gotoReady(page, path, { waitText, settle = 2500 } = {}) {
  await page.goto(path.startsWith('http') ? path : BASE + path, { waitUntil: 'domcontentloaded' });
  await page.waitForLoadState('networkidle').catch(() => {});
  await sleep(6000);
  if (waitText) {
    await page.getByText(waitText, { exact: false }).first().waitFor({ timeout: 20000 }).catch(() => {});
  }
  await sleep(settle);
}

// Inject a reusable overlay stylesheet + helpers once per page.
export async function installOverlay(page) {
  await page.addStyleTag({ content: `
    #demo-spot { position:fixed; z-index:2147483000; border:3px solid #6366f1;
      border-radius:12px; box-shadow:0 0 0 4000px rgba(15,23,42,.55), 0 8px 30px rgba(99,102,241,.5);
      transition:all .5s cubic-bezier(.4,0,.2,1); pointer-events:none; }
    #demo-caption { position:fixed; z-index:2147483001; left:50%; transform:translateX(-50%);
      bottom:96px; background:rgba(15,23,42,.92); color:#fff; padding:10px 22px; border-radius:999px;
      font:600 20px/1.4 "PingFang SC",system-ui,sans-serif; letter-spacing:.02em; white-space:nowrap;
      box-shadow:0 8px 30px rgba(0,0,0,.35); opacity:0; transition:opacity .4s; }
    #demo-card { position:fixed; inset:0; z-index:2147483002; display:flex; flex-direction:column;
      align-items:center; justify-content:center; gap:20px; text-align:center;
      background:radial-gradient(circle at 50% 40%, #1e293b 0%, #0f172a 70%); color:#fff;
      opacity:0; transition:opacity .6s; }
    #demo-card h1 { font:800 56px/1.2 "PingFang SC",system-ui,sans-serif; margin:0;
      background:linear-gradient(120deg,#818cf8,#c084fc); -webkit-background-clip:text; background-clip:text; color:transparent; }
    #demo-card p { font:400 26px/1.5 "PingFang SC",system-ui,sans-serif; margin:0; color:#cbd5e1; max-width:70%; }
    #demo-card .badge { font:600 18px/1 system-ui; color:#818cf8; letter-spacing:.3em; text-transform:uppercase; }
  ` });
  await page.evaluate(() => {
    if (!document.getElementById('demo-spot')) {
      for (const id of ['demo-spot', 'demo-caption']) {
        const el = document.createElement('div'); el.id = id;
        el.style.display = id === 'demo-spot' ? 'none' : ''; document.body.appendChild(el);
      }
    }
  });
}

// Spotlight a region (dims the rest). selector = CSS, or "text=某文字" to match by
// button/link text (CSS :has-text() is Playwright-only and throws in querySelector).
// Pass null to hide.
export async function spotlight(page, selector, { pad = 10 } = {}) {
  await page.evaluate(({ selector, pad }) => {
    const spot = document.getElementById('demo-spot');
    if (!selector) { spot.style.display = 'none'; return; }
    let el = null;
    if (selector.startsWith('text=')) {
      const needle = selector.slice(5);
      el = [...document.querySelectorAll('button,a,[role=button]')]
        .find((x) => (x.textContent || '').includes(needle));
    } else {
      try { el = document.querySelector(selector); } catch { el = null; }
    }
    if (!el) { spot.style.display = 'none'; return; }
    const r = el.getBoundingClientRect();
    if (r.width < 2 || r.height < 2) { spot.style.display = 'none'; return; }
    spot.style.display = 'block';
    spot.style.left = (r.left - pad) + 'px'; spot.style.top = (r.top - pad) + 'px';
    spot.style.width = (r.width + pad * 2) + 'px'; spot.style.height = (r.height + pad * 2) + 'px';
  }, { selector, pad });
}

export async function clearSpotlight(page) {
  await page.evaluate(() => { const s = document.getElementById('demo-spot'); if (s) s.style.display = 'none'; });
}

// A full-screen title card. secs = how long to hold it.
export async function titleCard(page, { badge = '', title, subtitle = '' }, secs = 3.5) {
  await page.evaluate(({ badge, title, subtitle }) => {
    let c = document.getElementById('demo-card');
    if (!c) { c = document.createElement('div'); c.id = 'demo-card'; document.body.appendChild(c); }
    c.innerHTML = `${badge ? `<div class="badge">${badge}</div>` : ''}<h1>${title}</h1>${subtitle ? `<p>${subtitle}</p>` : ''}`;
    requestAnimationFrame(() => { c.style.opacity = '1'; });
  }, { badge, title, subtitle });
  await sleep(secs * 1000);
  await page.evaluate(() => { const c = document.getElementById('demo-card'); if (c) c.style.opacity = '0'; });
  await sleep(600);
}

// Smoothly type into a field (visible, human-paced) — no jitter.
export async function typeInto(page, selector, text, { delay = 45 } = {}) {
  const el = page.locator(selector).first();
  await el.scrollIntoViewIfNeeded().catch(() => {});
  await el.click().catch(() => {});
  await el.fill('');
  await el.type(text, { delay });
}

// Hold on the current view for `secs`, optionally spotlighting a selector.
export async function hold(page, secs, selector = null) {
  if (selector) await spotlight(page, selector);
  await sleep(secs * 1000);
  if (selector) await clearSpotlight(page);
}

// Scene recorder: fresh context with video, run fn, save to raw/<id>.webm.
export async function recordScene(browser, { rawDir, id, authState }, fn) {
  const fs = await import('node:fs');
  const ctx = await browser.newContext({
    viewport: { width: 1920, height: 1080 },
    ...(authState ? { storageState: authState } : {}),
    recordVideo: { dir: rawDir, size: { width: 1920, height: 1080 } },
  });
  const page = await ctx.newPage();
  try { await fn(page); }
  catch (e) { console.log(`  [${id}] WARN ${e.message}`); }
  const video = page.video();
  await ctx.close();
  const tmp = await video.path();
  fs.renameSync(tmp, `${rawDir}/${id}.webm`);
  console.log(`  recorded ${id}.webm`);
}
