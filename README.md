# 每日任务 (DailyIntent)

iOS 原生「给自己发任务」App：历史上的今天 → 写下主线/支线 → AI 或默认阶段拆解 → 节点进度打卡 → 勋章月历。

GitHub 仓库名：**DailyQuest** · Xcode 工程名：**DailyIntent**

## 架构

```
iOS App  ──HTTPS──▶  Cloudflare Worker  ──▶  DeepSeek API
         X-Device-ID              DEEPSEEK_API_KEY（服务端 Secret）
         X-Quest-Day              任务日限流（本地 04:00 换日）
```

- 用户**无需**在 App 里配置 DeepSeek Key。
- **历史上的今天**：优先 [Wikimedia Feed API](https://api.wikimedia.org/)（免费），失败时用内置 `on_this_day_fallback.json`。
- **AI 拆解**在 Worker 云端完成；大陆用户只要能访问 `*.workers.dev`（Safari 打开 `/health` 有 `ok: true`），一般**不需要 VPN**。

## 核心概念：任务日

- 按手机**本地时区**，每天 **04:00** 进入新的任务日（不是 0 点）。
- 限流、日历、今日计划均按任务日计算。
- 请求头 `X-Quest-Day` 格式：`yyyy-MM-dd`，与 App 内任务日一致。

## 使用流程

### 首次或本任务日尚无「有效计划」

**有效计划** = 有主线文字，且主线至少 1 个阶段。仅有空数据不算。

1. **每日**（全屏横向滑动）
   - 第 1 页：**历史上的今天**
   - 左滑第 2 页：**每日目标** → 填主线（必填）、支线（最多 2 条）
   - **领取任务**：调用 Worker / DeepSeek，每条任务拆成 **2–3** 个阶段
   - **使用默认阶段**：不联网也可继续（主线 3 阶段、支线各 2 阶段）

2. **今日**（中间 Tab，与上并列的入口）
   - 若跳过每日流、或计划无效，在**今日** Tab 也会看到同样的录入表单
   - 提交成功后显示节点进度条打卡界面

### 已有有效计划之后

| Tab | 作用 |
|-----|------|
| **日历**（左） | 灰点 = 有计划未完成；勋章 = 主线完成；镀膜 = 主线 + 全部支线完成 |
| **今日**（中） | 主线/支线节点进度条、当前阶段文案；可连续勾选跳关 |
| **设置**（右） | 修改今日任务（清空进度，每任务日最多 3 次重新拆解）、提醒时间、使用教程；iCloud 预留 |

### 引导方式

- **无**独立 Onboarding 全屏向导。
- **轻提示**：关键操作生涯各提示一次（左滑、领取任务、三 Tab、设置改任务、提醒）。
- **使用教程**：设置 Tab → 展开教程，查看完整说明。

## 快速开始（Mac + Xcode）

### 1. 获取代码

```bash
git clone https://github.com/LizzardKevin/DailyQuest.git
cd DailyQuest
```

用 Xcode 打开 **`DailyIntent.xcodeproj`**（不是只打开文件夹）。

### 2. 运行 iOS App（无需付费开发者账号）

1. Xcode 15+，菜单 **Xcode → Settings → Accounts** 登录 Apple ID（免费即可）。
2. 工程 **Signing & Capabilities** → **Team** 选 Personal Team。
3. 顶部设备选 **iPhone 模拟器**（iOS 17+），勿选 “Any iOS Device (Build Only)”。
4. **Product → Run**（⌘R）。

模拟器调试**不需要** $99/年的 Apple Developer Program。

### 3. 部署 Worker（要用「领取任务」时）

在 Mac 终端：

```bash
cd workers
npm install
npx wrangler login
npx wrangler secret put DEEPSEEK_API_KEY
# 可选但建议：
npx wrangler secret put API_SHARED_SECRET
npm run deploy
npm run test
```

记下输出的 URL，例如 `https://daily-intent-api.<你的账号>.workers.dev`。

**验证网络**：在 Mac Safari 打开：

`https://你的-worker地址/health`

应看到：`{"ok":true,"service":"daily-intent-api"}`

### 4. 配置 iOS 连接 Worker

编辑 [`DailyIntent/Config/APIConfig.swift`](DailyIntent/Config/APIConfig.swift)：

```swift
static let baseURLString = "https://你的-worker.workers.dev"
static let apiSharedSecret = ""  // 若 Worker 设置了 API_SHARED_SECRET，填相同值
```

设置 Tab → **AI 服务** 可查看当前拆解接口完整 URL（应为 `.../v1/breakdown`，路径中勿出现 `%2F`）。

Pull 代码后若遇编译错误，执行 **Product → Clean Build Folder**（⇧⌘K）再编译。

## 功能一览

| 能力 | 说明 |
|------|------|
| 主线 + 支线 | 主线 1 条必填，支线 0–2 条 |
| AI 拆解 | 每任务 2–3 阶段，含可选 hint |
| 默认阶段 | AI 失败或不想联网时使用 |
| 节点进度条 | 主线大条、支线小条，旁显示当前阶段 |
| 勋章 | 主线完成 → 基础勋章；主线 + 支线全完成 → 全息镀层 |
| 修改任务 | 仅设置 Tab，会清空当日进度，占 1 次拆解额度 |

## API 限流与安全

- 每设备每任务日 **3 次** 成功拆解（领取任务 + 设置里「保存并重新拆解」均计入）。
- 仅 **成功** 返回后扣次；失败不扣。
- 建议配置 `API_SHARED_SECRET`，与 App 内 `apiSharedSecret` 一致。

详见 [`workers/README.md`](workers/README.md)。

## 常见问题

| 现象 | 处理 |
|------|------|
| Build input file not found（旧文件） | `git pull` 最新代码，清理后重编 |
| Build Only 设备无法运行 | 改选 iPhone **模拟器** |
| 启动黑屏，切回 App 又正常 | 模拟器刷新问题；可 Clean Build 或重启模拟器 |
| 领取任务「无法连接服务器」 | Safari 测 `/health`；检查 `APIConfig` URL；Pull 含 URL 修复的提交 |
| 使用默认阶段没反应 | Pull 最新代码；今日 Tab 也应出现录入表单 |
| 今日主界面空白 | 无有效主线时应在「今日」Tab 录入；Pull `fa85f33` 及之后 |
| `container to push is nil` | 多为系统分页日志，界面正常可忽略 |
| 大陆能否不 VPN 使用 | 以本机 Safari 能否打开 `/health` 为准 |

## 费用粗算（1000 DAU）

- 约 1 次拆解 / 人 / 任务日 → DeepSeek 约 **¥1–2/天**（以官网实时价为准）。
- Wikimedia 趣闻：**$0**。

## 目录

```
DailyIntent/              # iOS SwiftUI（SwiftData 本地存储）
  App/                    # RootView、Tab
  Features/Daily/         # 每日流、录入组件
  Features/Today/         # 今日打卡
  Features/Calendar/      # 勋章日历
  Features/Settings/      # 设置、改任务、教程
  Config/APIConfig.swift  # Worker 地址
workers/                  # Cloudflare Worker API
```

## 许可证

MIT
