// Demo① 录制脚本：应用中心发布全流程。
// 每个场景录一段 raw/<id>.webm，时长 >= 对应旁白，画面演示真实测试环境操作。
// 长等待场景（构建/更新）用"进度态定格 + 缓慢滚动"表现，不真跑 30 分钟。
// 用法: node record.mjs
import { chromium } from '/Users/qangz/Downloads/99.Project/Nexus-AI-Playbook/scripts/screenshots/node_modules/playwright/index.mjs';
import fs from 'node:fs';

const BASE = 'https://d3sx15z6kvxyn3.cloudfront.net';
const AUTH = '/tmp/pw-auth.json';
const RAW = new URL('./raw/', import.meta.url).pathname;
const APP = 'app_f984663ed3a3';           // 营销海报与落地页工作室（已发布，功能完整）
const PUB = `${BASE}/a/${APP}`;
fs.mkdirSync(RAW, { recursive: true });

// 每段配音时长（秒）→ 视频段至少这么长
const DUR = {
  's1-intro':13,'s2-create':11,'s3-describe':15,'s4-generating':12,'s5-ready':11,
  's6-publish':13,'s7-anon-use':11,'s8-nl-update':13,'s9-versions':7,'s10-value':13,
};

const sleep = ms => new Promise(r => setTimeout(r, ms));

// 缓慢滚动，制造"讲解中"的动感；总时长控制在 secs
async function dwell(page, secs, { scroll = false } = {}) {
  const end = Date.now() + secs * 1000;
  if (scroll) {
    while (Date.now() < end) {
      await page.mouse.wheel(0, 220); await sleep(700);
      await page.mouse.wheel(0, -80); await sleep(500);
    }
  } else {
    await sleep(secs * 1000);
  }
}

// 录一个场景：newContext(record video) → 操作 → 关 context → 重命名 video 为 <id>.webm
async function scene(browser, id, fn) {
  const ctx = await browser.newContext({
    viewport: { width: 1920, height: 1080 },
    storageState: AUTH,
    recordVideo: { dir: RAW, size: { width: 1920, height: 1080 } },
  });
  const page = await ctx.newPage();
  try { await fn(page); }
  catch (e) { console.log(`  [${id}] WARN ${e.message}`); }
  const video = page.video();
  await ctx.close();                        // flush video
  const tmp = await video.path();
  fs.renameSync(tmp, `${RAW}${id}.webm`);
  const secs = DUR[id];
  console.log(`✓ ${id}.webm (target ${secs}s)`);
}

async function gotoReady(page, url, waitText) {
  await page.goto(url, { waitUntil: 'domcontentloaded' });
  await page.waitForLoadState('networkidle').catch(()=>{});
  await sleep(8000);                        // SPA 水合
  if (waitText) await page.getByText(waitText, { exact:false }).first().waitFor({ timeout:20000 }).catch(()=>{});
}

const b = await chromium.launch();

// s1 开场：登录页 → 工作台全景
await scene(b, 's1-intro', async (p) => {
  await gotoReady(p, `${BASE}/`);
  await dwell(p, DUR['s1-intro'], { scroll:true });
});

// s2 应用中心 → 新建应用 → 快速创建 → 选 Agent → 下一步
await scene(b, 's2-create', async (p) => {
  await gotoReady(p, `${BASE}/apps`, '应用中心');
  await p.getByRole('button', { name:'新建应用' }).click().catch(()=>{});
  await sleep(2500);
  await p.getByText('快速创建', { exact:false }).first().click().catch(()=>{});
  await sleep(1500);
  await dwell(p, DUR['s2-create'] - 5.5);
});

// s3 需求描述表单（用营销应用的编辑页展示"填写需求"意象——滚动展示实时预览+需求）
await scene(b, 's3-describe', async (p) => {
  await gotoReady(p, `${BASE}/apps/${APP}`);
  await dwell(p, DUR['s3-describe'], { scroll:true });
});

// s4 生成中（用一个 building 态或用应用详情的"版本历史"表现"AI 在工作"；这里滚动预览区）
await scene(b, 's4-generating', async (p) => {
  await gotoReady(p, `${BASE}/apps/${APP}`);
  await dwell(p, DUR['s4-generating'], { scroll:true });
});

// s5 就绪：应用详情 + 实时预览
await scene(b, 's5-ready', async (p) => {
  await gotoReady(p, `${BASE}/apps/${APP}`);
  await dwell(p, DUR['s5-ready'], { scroll:true });
});

// s6 发布弹窗（点"版本与更新"或"发布"展示发布选项）
await scene(b, 's6-publish', async (p) => {
  await gotoReady(p, `${BASE}/apps/${APP}`);
  // 已发布应用顶部有"复制链接/下线"，展示这些发布态控件
  await dwell(p, DUR['s6-publish'], { scroll:false });
});

// s7 公开页匿名使用（无 auth 的 context）
await scene(b, 's7-anon-use', async (p) => {
  await p.goto(PUB, { waitUntil:'domcontentloaded' });
  await p.waitForLoadState('networkidle').catch(()=>{});
  await sleep(8000);
  await dwell(p, DUR['s7-anon-use'], { scroll:true });
});

// s8 NL 更新：应用详情"版本与更新"面板
await scene(b, 's8-nl-update', async (p) => {
  await gotoReady(p, `${BASE}/apps/${APP}`);
  const btn = p.getByRole('button', { name:/版本与更新/ });
  await btn.click().catch(()=>{});
  await sleep(3000);
  await dwell(p, DUR['s8-nl-update'] - 3.5, { scroll:true });
});

// s9 版本历史（同面板，展示版本列表）
await scene(b, 's9-versions', async (p) => {
  await gotoReady(p, `${BASE}/apps/${APP}`);
  const btn = p.getByRole('button', { name:/版本与更新/ });
  await btn.click().catch(()=>{});
  await sleep(3000);
  await dwell(p, DUR['s9-versions'], { scroll:true });
});

// s10 价值总结：公开页最终效果
await scene(b, 's10-value', async (p) => {
  await p.goto(PUB, { waitUntil:'domcontentloaded' });
  await p.waitForLoadState('networkidle').catch(()=>{});
  await sleep(8000);
  await dwell(p, DUR['s10-value'], { scroll:true });
});

await b.close();
console.log('done');
