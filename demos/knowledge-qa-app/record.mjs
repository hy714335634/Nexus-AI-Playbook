// Demo① 录制：知识问答助手 从应用到发布到真实使用到迭代。
// 选此应用因其问答秒级稳定出结果（KB 检索），能完整展示"输入→结果"。
// 修复：无抖动、完整帧、高亮圈注、开场/结尾卡、真实结果+发布+匿名使用。
// 登录态录制前自动续期。用法: node record.mjs
import { chromium } from '/Users/qangz/Downloads/99.Project/Nexus-AI-Playbook/scripts/screenshots/node_modules/playwright/index.mjs';
import { gotoReady, installOverlay, spotlight, clearSpotlight, titleCard, hold, recordScene, refreshAuth, sleep }
  from '../lib/record-helpers.mjs';
import fs from 'node:fs';

const BASE = 'https://d3sx15z6kvxyn3.cloudfront.net';
const AUTH = '/tmp/pw-auth.json';
const RAW = new URL('./raw/', import.meta.url).pathname;
const APP = 'app_177cb4be76e8';        // Nexus-AI 帮助中心（问答，秒级稳定出结果）
const PUB = `${BASE}/a/${APP}`;
fs.mkdirSync(RAW, { recursive: true });

const b = await chromium.launch();
await refreshAuth(b, AUTH);            // 录制前登录一次
const S = (id, fn) => recordScene(b, { rawDir: RAW, id, authState: AUTH }, fn);
const Sanon = (id, fn) => recordScene(b, { rawDir: RAW, id, authState: null }, fn);

// 公开页真实提问并等答案出现（离开"还没有提问记录"空态且出现指引文本即成功）。
async function askAndWait(page, question, maxMs = 120000) {
  const ta = page.locator('textarea').first();
  await ta.click(); await ta.fill('');
  await ta.type(question, { delay: 32 });
  await sleep(600);
  await page.getByRole('button', { name: '提问' }).click().catch(() => {});
  const end = Date.now() + maxMs;
  while (Date.now() < end) {
    const empty = await page.getByText('还没有提问记录', { exact: false }).count();
    const answered = await page.getByText(/user-guide|第一步|步骤|应用中心/, { exact: false }).count();
    if (empty === 0 && answered > 0) { await sleep(3000); return true; }
    await sleep(3000);
  }
  return false;
}

// s0 开场标题卡
await S('s0-intro', async (p) => {
  await gotoReady(p, '/apps', { waitText: '应用中心' });
  await installOverlay(p);
  await titleCard(p, { badge: 'Nexus-AI', title: '应用中心', subtitle: '把 AI 助手变成全公司都能用的网页应用' }, 6.5);
});

// s1 痛点：工作台全景（静止，高亮创建入口，无抖动）
await S('s1-problem', async (p) => {
  await gotoReady(p, '/', { waitText: '工作台' });
  await installOverlay(p);
  await hold(p, 9);
  await spotlight(p, 'text=创建 Agent'); await sleep(6000); await clearSpotlight(p);
  await sleep(4000);
});

// s2 打开应用中心
await S('s2-open-app', async (p) => {
  await gotoReady(p, '/apps', { waitText: '应用中心' });
  await installOverlay(p);
  await hold(p, 7);
  await spotlight(p, 'text=新建应用'); await sleep(5000); await clearSpotlight(p);
  await sleep(3000);
});

// s3 应用详情
await S('s3-app-detail', async (p) => {
  await gotoReady(p, `/apps/${APP}`, { settle: 3500 });
  await installOverlay(p);
  await hold(p, 8);
  await spotlight(p, 'text=打开应用'); await sleep(5000); await clearSpotlight(p);
  await sleep(3000);
});

// s4 发布：高亮发布相关控件
await S('s4-publish', async (p) => {
  await gotoReady(p, `/apps/${APP}`, { settle: 3500 });
  await installOverlay(p);
  await hold(p, 5);
  await spotlight(p, 'text=复制链接'); await sleep(7000); await clearSpotlight(p);
  await sleep(4000);
});

// s5 公开链接
await S('s5-link', async (p) => {
  await gotoReady(p, `/apps/${APP}`, { settle: 3500 });
  await installOverlay(p);
  await hold(p, 4);
  await spotlight(p, 'a[href*="/a/"], code'); await sleep(7000); await clearSpotlight(p);
  await sleep(3000);
});

// s6 同事打开公开页（匿名）
await Sanon('s6-anon-open', async (p) => {
  await gotoReady(p, PUB, { waitText: '提问' });
  await installOverlay(p);
  await titleCard(p, { badge: '同事视角', title: '任何人，一条链接', subtitle: '无需登录 · 无需安装' }, 3.5);
  await hold(p, 6);
  await spotlight(p, 'textarea'); await sleep(4000); await clearSpotlight(p);
});

// s7 真实提问（打字，高亮提问按钮）
await Sanon('s7-anon-ask', async (p) => {
  await gotoReady(p, PUB, { waitText: '提问' });
  await installOverlay(p);
  const ta = p.locator('textarea').first();
  await ta.click(); await ta.type('怎么把一个 Agent 发布成全公司都能用的网页应用？', { delay: 40 });
  await sleep(1500);
  await spotlight(p, 'text=提问'); await sleep(4000); await clearSpotlight(p);
});

// s8 秒级答案（真实提问并等答案）
await Sanon('s8-anon-answer', async (p) => {
  await gotoReady(p, PUB, { waitText: '提问' });
  await installOverlay(p);
  const ok = await askAndWait(p, '怎么把一个 Agent 发布成全公司都能用的网页应用？');
  if (ok) { await sleep(1000); await p.mouse.wheel(0, 300); await sleep(9000); }
  else { await sleep(14000); }
});

// s9 深层问题编排（授权渗透测试）
await Sanon('s9-deep', async (p) => {
  await gotoReady(p, PUB, { waitText: '提问' });
  await installOverlay(p);
  const ok = await askAndWait(p, '我想构建一个 agent 帮我完成对指定应用的授权渗透测试，如何做？', 150000);
  if (ok) { await sleep(1000); await p.mouse.wheel(0, 400); await sleep(10000); }
  else { await sleep(15000); }
});

// s10 一句话迭代
await S('s10-iterate', async (p) => {
  await gotoReady(p, `/apps/${APP}`, { settle: 3000 });
  await installOverlay(p);
  await p.getByRole('button', { name: /版本与更新/ }).click().catch(() => {});
  await sleep(3500);
  await spotlight(p, 'textarea'); await sleep(6000); await clearSpotlight(p);
  await sleep(5000);
});

// s11 结尾标题卡
await S('s11-outro', async (p) => {
  await gotoReady(p, `/apps/${APP}`, { settle: 2500 });
  await installOverlay(p);
  await titleCard(p, { badge: 'Nexus-AI 应用中心', title: '想法 → 生产力', subtitle: '构建 · 发布 · 迭代，全程一句话' }, 8);
});

await b.close();
console.log('done');
