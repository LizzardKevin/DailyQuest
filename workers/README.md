# Daily Quest API (Cloudflare Worker)

代理 DeepSeek 任务拆解，API Key 仅存服务端。

## 部署

```bash
cd workers
npm install
npx wrangler login
npx wrangler secret put DEEPSEEK_API_KEY
# 强烈建议：防刷鉴权（与 iOS APIConfig.apiSharedSecret 保持一致）
npx wrangler secret put API_SHARED_SECRET

npm run deploy
npm run test
```

部署成功后记下 URL，例如：

```
https://daily-intent-api.<你的子域>.workers.dev
```

将其填入 iOS 的 `DailyIntent/Config/APIConfig.swift`（或 `APIBaseURL` build setting）。

## 本地开发

```bash
npm run dev
# 本地需 .dev.vars：
# DEEPSEEK_API_KEY=sk-...
```

`.dev.vars` 示例见 `.dev.vars.example`。

## API

### `GET /health`

健康检查。

### `POST /v1/breakdown`

**Headers**

| Header | 必填 | 说明 |
|--------|------|------|
| `Content-Type` | 是 | `application/json` |
| `X-Device-ID` | 是 | 客户端设备 UUID（8–128 字符） |
| `X-API-Secret` | 否 | 若配置了 `API_SHARED_SECRET` 则必填 |

**Body**

```json
{
  "mainTask": "完成产品原型",
  "sideTasks": ["运动30分钟"]
}
```

**Response** — 与 iOS `TaskBreakdownResponse` 同结构。

**Headers（补充）**

| `X-Quest-Day` | 否 | 客户端任务日 `yyyy-MM-dd`（本地 04:00 换日）；用于限流桶 |

**限流**：每设备每任务日默认 **3** 次（`MAX_REQUESTS_PER_DAY`）。**仅在 DeepSeek 成功返回后扣次**；失败不消耗额度。

**校验**：`sides` 数组长度必须等于请求中 `sideTasks` 数量，否则 422。

## 费用参考

约 1000 DAU × 1 次/天 ≈ 百万 tokens 量级以下，DeepSeek 成本通常很低（请以官网实时价格为准）。
