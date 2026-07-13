// Demo② 录制：给 Agent 添加工具与技能。
// 展示真实产物（工具库154个/生成工具/技能库），构建入口展示弹窗不跑长构建。
// 用法: node record.mjs
import { chromium } from '/Users/qangz/Downloads/99.Project/Nexus-AI-Playbook/scripts/screenshots/node_modules/playwright/index.mjs';
import { gotoReady, installOverlay, spotlight, clearSpotlight, titleCard, hold, recordScene, refreshAuth, sleep }
  from '../lib/record-helpers.mjs';
import fs from 'node:fs';

const BASE = 'https://d3sx15z6kvxyn3.cloudfront.net';
const AUTH = '/tmp/pw-auth.json';
const RAW = new URL('./raw/', import.meta.url).pathname;
fs.mkdirSync(RAW, { recursive: true });

const b = await chromium.launch();
await refreshAuth(b, AUTH);
const S = (id, fn) => recordScene(b, { rawDir: RAW, id, authState: AUTH }, fn);

// s0 开场标题卡
await S('s0-intro', async (p) => {
  await gotoReady(p, '/ability/tools', { waitText: '能力工具' });
  await installOverlay(p);
  await titleCard(p, { badge: 'Nexus-AI', title: '给 Agent 添加能力', subtitle: '工具与技能 · 让 Agent 从会聊天变成能干活' }, 6.5);
});

// s1 痛点：对话页（Agent 会聊但缺工具）
await S('s1-problem', async (p) => {
  await gotoReady(p, '/chat', { waitText: '会话' });
  await installOverlay(p);
  await hold(p, 8);
  await spotlight(p, 'textarea'); await sleep(5000); await clearSpotlight(p);
  await sleep(3000);
});

// s2 工具库总览：154 个工具
await S('s2-toolhub', async (p) => {
  await gotoReady(p, '/ability/tools', { waitText: '能力工具' });
  await installOverlay(p);
  await hold(p, 9);
  await spotlight(p, 'text=全部'); await sleep(5000); await clearSpotlight(p);
  await sleep(3000);
});

// s3 工具分类：内置/系统/模板/生成
await S('s3-categories', async (p) => {
  await gotoReady(p, '/ability/tools', { waitText: '能力工具' });
  await installOverlay(p);
  await hold(p, 4);
  await spotlight(p, 'text=生成工具'); await sleep(5000); await clearSpotlight(p);
  await sleep(6000);
});

// s4 构建工具入口：点开构建弹窗，展示表单
await S('s4-build-entry', async (p) => {
  await gotoReady(p, '/ability/tools', { waitText: '能力工具' });
  await installOverlay(p);
  await hold(p, 3);
  await spotlight(p, 'text=构建工具'); await sleep(3000); await clearSpotlight(p);
  // eval 直点触发弹窗（无 role=dialog，用类名探测过）
  await p.evaluate(() => { const btn=[...document.querySelectorAll('button')].find(x=>(x.textContent||'').trim()==='构建工具'); if(btn) btn.click(); });
  await sleep(3500);
  // 弹窗里填需求（不点开始构建，仅展示"一句话造工具")
  await p.evaluate(() => {
    const ta=[...document.querySelectorAll('textarea')].find(t=>(t.placeholder||'').includes('例如')||(t.placeholder||'').includes('网页抓取'));
    if(ta){ Object.getOwnPropertyDescriptor(HTMLTextAreaElement.prototype,'value').set.call(ta,'创建一个查询实时汇率的工具，输入货币代码，返回当前汇率'); ta.dispatchEvent(new Event('input',{bubbles:true})); }
  });
  await sleep(6000);
});

// s5 真实生成工具：展示生成工具分类的真实产物
await S('s5-generated', async (p) => {
  await gotoReady(p, '/ability/tools', { waitText: '能力工具' });
  await installOverlay(p);
  await p.evaluate(() => { const b=[...document.querySelectorAll('button')].find(x=>(x.textContent||'').trim()==='生成工具'); if(b) b.click(); });
  await sleep(3500);
  await hold(p, 11);
});

// s6 挂载到 Agent：创建 Agent 页（工具勾选意象）
await S('s6-attach', async (p) => {
  await gotoReady(p, '/agents/new', { settle: 3000 });
  await installOverlay(p);
  await hold(p, 6);
  // 高亮"引导创建/快速创建"，说明创建时能配工具
  await spotlight(p, 'text=快速创建'); await sleep(5000); await clearSpotlight(p);
  await sleep(4000);
});

// s7 技能库：社区/系统/生成技能
await S('s7-skills', async (p) => {
  await gotoReady(p, '/ability/skills', { waitText: 'Skills' });
  await installOverlay(p);
  await hold(p, 9);
  await spotlight(p, 'text=Skills 构建'); await sleep(5000); await clearSpotlight(p);
  await sleep(2000);
});

// s8 沉淀复用：技能库分组展示
await S('s8-reuse', async (p) => {
  await gotoReady(p, '/ability/skills', { waitText: 'Skills' });
  await installOverlay(p);
  await hold(p, 8);
  await spotlight(p, 'text=组合'); await sleep(5000); await clearSpotlight(p);
  await sleep(3000);
});

// s9 结尾标题卡
await S('s9-outro', async (p) => {
  await gotoReady(p, '/ability/tools', { waitText: '能力工具' });
  await installOverlay(p);
  await titleCard(p, { badge: 'Nexus-AI 能力扩展', title: '能力，不断生长', subtitle: '一句话造工具 · 勾选即挂载 · 存成技能反复用' }, 8);
});

await b.close();
console.log('done');
