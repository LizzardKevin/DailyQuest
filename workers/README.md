# daily-quest-api

Cloudflare Worker for DailyQuest iOS app.

## Endpoints

- `GET /health` → `{ "ok": true, "service": "daily-quest-api" }`
- `POST /v1/breakdown` — task stage breakdown (DeepSeek)
- `POST /v1/medal/design` — daily medal metadata (DeepSeek)

### `POST /v1/medal/design` body

```json
{
  "mainTask": "string (required)",
  "sideTasks": ["optional"],
  "questDay": "yyyy-MM-dd (optional, prefer X-Quest-Day header)",
  "triviaTitle": "optional",
  "triviaYear": 1990,
  "forceRegenerate": false
}
```

- Default (`forceRegenerate: false`): return cached design for same `X-Device-ID` + quest day if present.
- `forceRegenerate: true`: delete cache and call DeepSeek again (used when user edits today's quest in Settings).

## Headers

- `X-Device-ID` (required)
- `X-Quest-Day` (recommended, `yyyy-MM-dd`)
- `X-API-Secret` (optional, if `API_SHARED_SECRET` is set)

## Deploy

```bash
npm install
npx wrangler secret put DEEPSEEK_API_KEY
npm run deploy
npm run test
```

## Rate limits

- Breakdown: `MAX_REQUESTS_PER_DAY` (default 3) per device per quest day
- Medal design: `MAX_MEDAL_DESIGNS_PER_DAY` (default 2) per device per quest day — typically one on claim, one on settings regenerate

## Smoke test

```powershell
powershell -File scripts/smoke-test.ps1
```

Checks `/health`, `/v1/breakdown`, medal cache hit, and `forceRegenerate` producing a new design.
