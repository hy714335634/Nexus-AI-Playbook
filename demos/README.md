# Demo 视频产线

故事化功能演示视频的制作流水线：**分镜（审）→ 录制 → 配音 → 合成**。中英双版本，1080p mp4，字幕+配音。

## 目录约定

```
demos/
├── lib/                      # 共用脚本
│   ├── tts.sh                # edge-tts 逐场景配音（zh: Yunjian / en: Andrew）
│   ├── gen_srt.py            # narration.yaml + mp3 实测时长 → SRT
│   └── compose.sh            # ffmpeg 拼段+混音+烧字幕 → output/<lang>.mp4
└── <story-slug>/
    ├── storyboard.zh.md      # 分镜脚本（先审后录）
    ├── storyboard.en.md
    ├── narration.yaml        # scenes: [{id, title, zh, en, max_sec}]
    ├── record.spec.ts        # Playwright 分段录制（每场景一段 webm）
    ├── raw/                  # 场景片段 <id>.webm（gitignored）
    ├── narration/            # <id>.<lang>.mp3（gitignored）
    ├── subtitles/            # zh.srt / en.srt（生成物）
    └── output/               # zh.mp4 / en.mp4 成片（gitignored，本地保存）
```

## 制作四步

```bash
D=demos/<story-slug>
# 1. 分镜：写 storyboard + narration.yaml，用户审过才开录
# 2. 录制：按分镜逐场景录 raw/<id>.webm
#    - Playwright: video:{mode:'on',size:{width:1920,height:1080}}，或
#    - agent-browser record start/stop（走查式录制）
#    - 构建等待期不录空镜：等完成再录结果场景，或后期截断
# 3. 配音: ./demos/lib/tts.sh $D zh && ./demos/lib/tts.sh $D en
# 4. 合成: ./demos/lib/compose.sh $D zh && ./demos/lib/compose.sh $D en
#    （合成内部自动生成 SRT；视频段比旁白短会自动定格补齐）
```

## 三个故事

| slug | 故事 | 素材来源 |
|---|---|---|
| app-center-publish | 市场部小王：一句话需求 → 构建 → 应用中心发布 → 全公司用 → NL 迭代 | 重录（快速创建应用流程 ~6min 可控） |
| tool-skill-extend | 数据分析师小李：Agent 不会查数 → tool_build 造工具 → 挂载 → 复用 | 重录 |
| kb-qa-assistant | 支持团队被"怎么用"淹没 → 手册入 KB → 建助手 Agent → 发布公开应用 | Phase C 实录（raw/ 已有素材）+ 补录 |

## 经验

- 旁白每段 ≤ 25s（中文 ~110 字），场景视频与旁白长度差控制在 ±5s 内观感最好
- 录屏用 1920x1080 viewport；鼠标移动放慢（Playwright `slowMo: 300`）
- 中文字幕 18pt 足够；`MarginV=30` 避开平台底部工具条
- edge-tts 经 `uvx edge-tts` 调用，无需安装
