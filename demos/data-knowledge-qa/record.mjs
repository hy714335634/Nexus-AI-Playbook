// Demo③ 录制：数据连接 + 知识问答。
// 角度=知识/数据如何接入 AI（区别于 Demo① 的"发布应用"视角）。
// 前段展示业务集成中心的数据接入能力，后段展示基于资料的真实问答。
// 用法: node record.mjs
import { chromium } from '/Users/qangz/Downloads/99.Project/Nexus-AI-Playbook/scripts/screenshots/node_modules/playwright/index.mjs';
import { gotoReady, installOverlay, spotlight, clearSpotlight, titleCard, hold, recordScene, refreshAuth, sleep }
  from '../lib/record-helpers.mjs';
import fs from 'node:fs';

const BASE = 'https://d3sx15z6kvxyn3.cloudfront.net';
const AUTH = '/tmp/pw-auth.json';
const RAW = new URL('./raw/', import.meta.url).pathname;
const APP = 'app_177cb4be76e8';        // 帮助中心（真实知识问答案例）
const PUB = `${BASE}/a/${APP}`;
fs.mkdirSync(RAW, { recursive: true });

const b = await chromium.launch();
await refreshAuth(b, AUTH);
const S = (id, fn) => recordScene(b, { rawDir: RAW, id, authState: AUTH }, fn);
const Sanon = (id, fn) => recordScene(b, { rawDir: RAW, id, authState: null }, fn);

async function askAndWait(page, question, maxMs = 120000) {
  const ta = page.locator('textarea').first();
  await ta.click(); await ta.fill('');
  await ta.type(question, { delay: 32 });
  await sleep(600);
  await page.getByRole('button', { name: '提问' }).click().catch(() => {});
  const end = Date.now() + maxMs;
  while (Date.now() < end) {
    const empty = await page.getByText('还没有提问记录', { exact: false }).count();
    const answered = await page.getByText(/user-guide|第一步|步骤|能力中心/, { exact: false }).count();
    if (empty === 0 && answered > 0) { await sleep(3000); return true; }
    await sleep(3000);
  }
  return false;
}

// s0 开场标题卡
await S('s0-intro', async (p) => {
  await gotoReady(p, '/integration', { waitText: '业务集成' });
  await installOverlay(p);
  await titleCard(p, { badge: 'Nexus-AI', title: '让 AI 读懂你的资料', subtitle: '接入文档与数据 · Agent 基于它们回答' }, 6.5);
});

// s1 痛点：业务集成总览（资料躺在那里）
await S('s1-problem', async (p) => {
  await gotoReady(p, '/integration', { waitText: '业务集成' });
  await installOverlay(p);
  await hold(p, 9);
  await spotlight(p, 'text=资产模版'); await sleep(5000); await clearSpotlight(p);
  await sleep(3000);
});

// s2 业务集成中心：四个入口
await S('s2-integration', async (p) => {
  await gotoReady(p, '/integration', { waitText: '业务集成' });
  await installOverlay(p);
  await hold(p, 6);
  await spotlight(p, 'text=数据连接'); await sleep(5000); await clearSpotlight(p);
  await spotlight(p, 'text=密钥管理'); await sleep(5000); await clearSpotlight(p);
  await sleep(2000);
});

// s3 数据连接
await S('s3-dataconn', async (p) => {
  await gotoReady(p, '/integration', { waitText: '业务集成' });
  await installOverlay(p);
  await p.evaluate(() => { const c=[...document.querySelectorAll('[onclick],div')].find(x=>/数据连接/.test(x.textContent||'') && (x.textContent||'').length<20); if(c) c.click(); });
  await sleep(3500);
  await hold(p, 12);
});

// s4 密钥管理
await S('s4-keys', async (p) => {
  await gotoReady(p, '/integration', { waitText: '业务集成' });
  await installOverlay(p);
  await p.evaluate(() => { const c=[...document.querySelectorAll('[onclick],div')].find(x=>/密钥管理/.test(x.textContent||'') && (x.textContent||'').length<20); if(c) c.click(); });
  await sleep(3500);
  await hold(p, 10);
});

// s5 知识问答案例：帮助中心应用详情
await S('s5-kb-story', async (p) => {
  await gotoReady(p, `/apps/${APP}`, { settle: 3500 });
  await installOverlay(p);
  await hold(p, 8);
  await spotlight(p, 'text=打开应用'); await sleep(6000); await clearSpotlight(p);
  await sleep(3000);
});

// s6 真实提问（匿名公开页，不同于 Demo① 的问题）
await Sanon('s6-ask', async (p) => {
  await gotoReady(p, PUB, { waitText: '提问' });
  await installOverlay(p);
  const ta = p.locator('textarea').first();
  await ta.click(); await ta.type('怎么给已有的 Agent 添加新工具？', { delay: 42 });
  await sleep(1500);
  await spotlight(p, 'text=提问'); await sleep(4000); await clearSpotlight(p);
});

// s7 基于资料的真实回答
await Sanon('s7-answer', async (p) => {
  await gotoReady(p, PUB, { waitText: '提问' });
  await installOverlay(p);
  const ok = await askAndWait(p, '怎么给已有的 Agent 添加新工具？');
  if (ok) { await sleep(1000); await p.mouse.wheel(0, 320); await sleep(9000); }
  else { await sleep(14000); }
});

// s8 价值：答案带出处（滚到底部展示手册出处）
await Sanon('s8-value', async (p) => {
  await gotoReady(p, PUB, { waitText: '提问' });
  await installOverlay(p);
  const ok = await askAndWait(p, '怎么给已有的 Agent 添加新工具？');
  if (ok) { await sleep(1000); await p.mouse.wheel(0, 900); await sleep(10000); }
  else { await sleep(14000); }
});

// s9 结尾标题卡
await S('s9-outro', async (p) => {
  await gotoReady(p, '/integration', { waitText: '业务集成' });
  await installOverlay(p);
  await titleCard(p, { badge: 'Nexus-AI 知识接入', title: '让知识开口说话', subtitle: '接入资料 · 建成助手 · 随问随答' }, 8);
});

await b.close();
console.log('done');
