# Daily Quest API (Cloudflare Worker)

代理 DeepSeek 任务拆解；API Key 仅存服务端，iOS 通过 HTTPS 调用。

## 部署

```bash
cd workers
npm install
npx wrangler login
npx wrangler secret put DEEPSEEK_API_KEY
# 强烈建议（与 iOS APIConfig.apiSharedSecret 一致）：
npx wrangler secret put API_SHARED_SECRET

npm run deploy
npm run test
```

部署成功后记下 URL，例如：

```
https://daily-intent-api.<你的子域>.workers.dev
```

填入 iOS [`DailyIntent/Config/APIConfig.swift`](../DailyIntent/Config/APIConfig.swift) 的 `baseURLString`。

**注意**：拆解地址必须为 `https://xxx.workers.dev/v1/breakdown`。不要用会把 `/` 编成 `%2F` 的错误拼接方式。

## 本地开发

```bash
npm run dev
```

创建 `workers/.dev.vars`（勿提交 Git）：

```
DEEPSEEK_API_KEY=sk-...
API_SHARED_SECRET=可选
```

示例见 `.dev.vars.example`。

## API

### `GET /health`

健康检查。浏览器可访问以确认网络（含大陆是否可达 Worker）。

```json
{"ok":true,"service":"daily-intent-api"}
```

### `POST /v1/breakdown`

**Headers**

| Header | 必填 | 说明 |
|--------|------|------|
| `Content-Type` | 是 | `application/json` |
| `X-Device-ID` | 是 | 设备 UUID，8–128 字符 |
| `X-Quest-Day` | 否 | 任务日 `yyyy-MM-dd`（App 本地 04:00 换日）；用于限流桶 |
| `X-API-Secret` | 否 | 配置了 `API_SHARED_SECRET` 时必填 |
| `X-Intent-Day` | 否 | 已废弃，仍兼容旧客户端 |

**Body**

```json
{
  "mainTask": "完成产品原型",
  "sideTasks": ["运动30分钟"]
}
```

支线最多 2 条；`mainTask` 最长 500 字，每条支线最长 300 字。

**Response**

```json
{
  "main": { "stages": [{ "title": "阶段名", "hint": "可选说明" }] },
  "sides": [{ "stages": [{ "title": "...", "hint": "..." }] }]
}
```

- 主线阶段：**2–3** 个
- 每条支线阶段：**2–3** 个
- `sides` 数组长度必须等于请求中 `sideTasks` 数量，否则 **422**

**限流**

- 默认每设备每任务日 **3** 次（`wrangler.jsonc` → `MAX_REQUESTS_PER_DAY`）
- **仅在 DeepSeek 成功返回后扣次**；失败不消耗额度
- 超额返回 **429**

**错误示例**

| 状态码 | 含义 |
|--------|------|
| 400 | 缺少/无效 `X-Device-ID` 或 body |
| 401 | `X-API-Secret` 错误 |
| 422 | AI 返回支线数量或阶段数不合规 |
| 429 | 当日拆解次数用尽 |
| 502 | DeepSeek 暂时不可用 |
| 503 | 未配置 `DEEPSEEK_API_KEY` |

## 配置

`wrangler.jsonc`：

```json
"vars": {
  "MAX_REQUESTS_PER_DAY": "3"
}
```

## 费用参考

约 1000 DAU × 1 次拆解/任务日 → 百万 tokens 量级以下，DeepSeek 成本通常很低（以官网实时价格为准）。Wikimedia 由 iOS 直连，不经本 Worker。
