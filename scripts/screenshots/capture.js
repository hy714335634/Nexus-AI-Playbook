#!/usr/bin/env node
/**
 * Playwright screenshot runner.
 * Usage: node capture.js --targets "name1,name2" --base-url http://localhost:3000 --user admin --password nexus --output-dir ../../docs/public/images
 * If --targets is "all", captures every target in targets.yaml.
 */
import { chromium } from 'playwright';
import fs from 'node:fs';
import path from 'node:path';
import url from 'node:url';
import yaml from 'js-yaml';

const __dirname = path.dirname(url.fileURLToPath(import.meta.url));

function parseArgs(argv) {
  const args = { targets: 'all' };
  for (let i = 2; i < argv.length; i++) {
    const a = argv[i];
    if (a === '--targets') args.targets = argv[++i];
    else if (a === '--base-url') args.baseUrl = argv[++i];
    else if (a === '--user') args.user = argv[++i];
    else if (a === '--password') args.password = argv[++i];
    else if (a === '--output-dir') args.outputDir = argv[++i];
  }
  return args;
}

async function isServiceUp(baseUrl) {
  try {
    const res = await fetch(baseUrl, { method: 'GET' });
    return res.status < 500;
  } catch {
    return false;
  }
}

async function login(page, baseUrl, user, password) {
  await page.goto(baseUrl + '/login', { waitUntil: 'networkidle', timeout: 30000 });
  // Best-effort: fill any visible username/password fields. If site uses SSO,
  // this no-ops and the caller falls through to taking screenshots of what's visible.
  try {
    await page.fill('input[type="text"]', user, { timeout: 2000 });
    await page.fill('input[type="password"]', password, { timeout: 2000 });
    await page.click('button:has-text("登录")', { timeout: 2000 });
    await page.waitForLoadState('networkidle', { timeout: 30000 }).catch(() => {});
    await page.waitForTimeout(5000);  // Fixed wait for post-login hydration
  } catch {
    // Login form not present or shape differs — continue without blocking.
  }
}

async function main() {
  const args = parseArgs(process.argv);
  const baseUrl = args.baseUrl || 'http://localhost:3000';
  // Default outputDir is relative to this script's location, not the CWD.
  const outputDir = args.outputDir
    ? path.resolve(args.outputDir)
    : path.resolve(__dirname, '../../docs/public/images');

  if (!await isServiceUp(baseUrl)) {
    console.error(JSON.stringify({ status: 'service_down', baseUrl }));
    process.exit(2);  // distinct exit code: service not running
  }

  const cfg = yaml.load(fs.readFileSync(path.join(__dirname, 'targets.yaml'), 'utf8'));
  const wanted = args.targets === 'all'
    ? cfg.targets.map(t => t.name)
    : args.targets.split(',').map(s => s.trim()).filter(Boolean);
  const targets = cfg.targets.filter(t => wanted.includes(t.name));

  if (!targets.length) {
    console.error(JSON.stringify({ status: 'no_targets_matched', wanted }));
    process.exit(3);
  }

  fs.mkdirSync(outputDir, { recursive: true });

  const browser = await chromium.launch();
  const context = await browser.newContext({ viewport: { width: 1440, height: 900 } });
  const page = await context.newPage();

  try {
    if (args.user && args.password) {
      await login(page, baseUrl, args.user, args.password);
    }

    const results = [];
    for (const t of targets) {
      const target = baseUrl.replace(/\/$/, '') + t.url;
      try {
        await page.goto(target, { waitUntil: 'networkidle', timeout: 30000 });
        await page.waitForTimeout(8000);  // Fixed wait for SPA hydration (proven necessary)
        if (t.wait_for_selector) {
          await page.waitForSelector(t.wait_for_selector, { timeout: 5000 }).catch(() => {});
        }
        const outPath = path.join(outputDir, t.output);
        await page.screenshot({ path: outPath, fullPage: false });  // Viewport-only (fullPage breaks virtualized lists)
        results.push({ name: t.name, status: 'ok', path: outPath });
      } catch (err) {
        results.push({ name: t.name, status: 'error', error: String(err) });
      }
    }
    console.log(JSON.stringify({ status: 'done', results }, null, 2));
  } finally {
    await browser.close();
  }
}

main().catch(err => {
  console.error(err);
  process.exit(1);
});
