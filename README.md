# 每日任务 (DailyIntent)

iOS 原生每日任务 App + Cloudflare Worker 后端：历史上的今天 → 领取任务 → AI 拆解 → 节点进度打卡 → 勋章/全息镀层 → 月历回顾。

## 架构

```
iOS App  ──HTTPS──▶  Cloudflare Worker  ──▶  DeepSeek API
              X-Device-ID        DEEPSEEK_API_KEY (Secret)
              X-Quest-Day        （任务日限流，本地 04:00 换日）
```

用户**无需**配置 API Key。历史上的今天优先 **Wikimedia Feed API**（免费），失败时使用内置 JSON 兜底。

## 使用流程

1. **每日**（仅当本任务日尚无计划）：历史上的今天 → 左滑 **每日目标** → **领取任务**（DeepSeek 拆解为每任务 2–3 阶段）
2. **今日**（中间 Tab）：节点进度条 + 当前阶段文案，可连续勾选跳关
3. **日历**（左 Tab）：灰点=进行中，勋章=主线完成，镀膜=主线+支线完成
4. **设置**（右 Tab）：修改今日任务（清空进度，每任务日最多 3 次重新拆解）、提醒时间、使用教程；iCloud 同步预留

**任务日**：按手机本地时区，每天 **04:00** 进入新的一天。

**轻提示**：关键操作生涯各提示一次；完整说明见设置 → 使用教程。

## 快速开始

### 1. 部署 Worker（Mac / Linux）

```bash
cd workers
npm install
npx wrangler login
npx wrangler secret put DEEPSEEK_API_KEY
npm run deploy
```

记下部署 URL，例如 `https://daily-intent-api.<account>.workers.dev`。

### 2. 配置 iOS

编辑 [`DailyIntent/Config/APIConfig.swift`](DailyIntent/Config/APIConfig.swift)：

```swift
static let baseURLString = "https://daily-intent-api.<你的账号>.workers.dev"
static let apiSharedSecret = "<与 Worker API_SHARED_SECRET 相同>"
```

### 3. 运行 App

1. Xcode 15+ 打开 `DailyIntent.xcodeproj`
2. 选择 Development Team
3. iOS 17+ 模拟器或真机 Run

## 功能

| Tab | 功能 |
|-----|------|
| 日历 | 灰点/勋章/镀膜月视图，点击查看当日详情 |
| 今日 | 节点进度条、阶段打卡、勋章庆祝 |
| 设置 | 修改今日任务、提醒、教程、隐私 |

## API 限流与安全

- 每设备每任务日 **3 次** AI 拆解（领取任务 + 设置中修改均计入）
- 仅成功拆解后扣次；请求头 `X-Quest-Day` 与客户端 04:00 换日对齐
- 建议启用 `API_SHARED_SECRET`

## 费用粗算（1000 DAU）

约 1 次拆解/人/任务日 → DeepSeek 通常 **¥1–2/天** 量级（以官网实时价格为准）。Wikimedia 趣闻 **$0**。

## 目录

```
DailyIntent/          # iOS SwiftUI 应用
workers/              # Cloudflare Worker API
```

## 许可证

MIT
