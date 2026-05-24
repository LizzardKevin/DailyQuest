# DailyQuest

iOS 原生「给自己发任务」App：历史上的今天 → 写下主线/支线 → AI 拆解 → 节点打卡 → **每日 AI 独特奖牌** → 勋章月历。

GitHub 仓库名：**DailyQuest** · Xcode 工程名：**DailyQuest**

## 架构

```
iOS App  ──HTTPS──▶  Cloudflare Worker (daily-quest-api)  ──▶  DeepSeek API
         X-Device-ID              DEEPSEEK_API_KEY（服务端 Secret）
         X-Quest-Day              任务日限流（本地 04:00 换日）
```

| 端点 | 说明 |
|------|------|
| `GET /health` | 健康检查 |
| `POST /v1/breakdown` | 任务拆解（每任务日 3 次） |
| `POST /v1/medal/design` | 每日奖牌元数据（每任务日最多 2 次 AI 生成，见下文） |

### 每日奖牌与 `forceRegenerate`

- **首次领取任务**：App 调用 `/v1/medal/design`，DeepSeek 根据主线、支线（及历史上的今天）生成当日奖牌标题、配色与图标；结果会**缓存**到该设备 + 任务日，重复请求直接返回同一设计（省额度）。
- **设置里改任务**：保存并重新拆解时，App 会传 `forceRegenerate: true`，Worker **跳过缓存**并重新生成奖牌，与新的任务内容一致。
- **限额**：每设备每任务日最多 **2 次** AI 奖牌生成（领取 1 次 + 改任务再生成 1 次）；超出后 App 使用本地模板 fallback。
- **断网 / AI 失败**：自动使用按日期与任务种子生成的本地模板，保证每天视觉仍不同。

冒烟测试（部署后）：

```powershell
cd workers
powershell -File scripts\smoke-test.ps1
```

- **历史上的今天**：Wikimedia + 本地 `on_this_day_fallback.json`（不走 DeepSeek）。
- **Release 构建**：仅「领取任务」（AI）；**Debug** 可选「使用默认阶段」方便模拟器。

## 任务日

本地时区每天 **04:00** 换日。请求头 `X-Quest-Day`: `yyyy-MM-dd`。

## 三 Tab

| Tab | 作用 |
|-----|------|
| 日历 | 每日独特奖牌 / 进行中 / 全息镀层 |
| 今日 | 打卡、奖牌预览、庆祝动画 |
| 设置 | 改任务、提醒、教程、Worker URL |

## 快速开始

### 1. 打开工程

```bash
git clone https://github.com/LizzardKevin/DailyQuest.git
cd DailyQuest
```

用 Xcode 打开 **`DailyQuest.xcodeproj`**。

若使用 XcodeGen：

```bash
xcodegen generate
```

### 2. 部署 Worker

```bash
cd workers
npm install
npx wrangler login
npx wrangler secret put DEEPSEEK_API_KEY
npm run deploy
npm run test
```

记下 `https://daily-quest-api.<账号>.workers.dev`，写入 [`DailyQuest/Config/APIConfig.swift`](DailyQuest/Config/APIConfig.swift) 的 `baseURLString`。

### 3. TestFlight

1. Apple Developer Program（$99/年）
2. Signing → Personal Team 或正式 Team
3. **Product → Archive**（Release）
4. Organizer → Distribute → TestFlight

## 目录

```
DailyQuest/           # iOS SwiftUI + SwiftData
  Domain/             # MedalDesign、扩展接口
  MedalKit/           # 奖牌渲染
  Features/           # DailyFlow / Today / Calendar / Settings
workers/              # daily-quest-api
```

## 许可证

MIT
