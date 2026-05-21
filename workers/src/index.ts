/**
 * Daily Quest API — proxies task breakdown to DeepSeek with per-device daily rate limiting.
 *
 * Secrets (set via `wrangler secret put DEEPSEEK_API_KEY`):
 *   DEEPSEEK_API_KEY — DeepSeek API key
 *
 * Optional secrets:
 *   API_SHARED_SECRET — if set, clients must send X-API-Secret header
 */

export interface Env {
  DEEPSEEK_API_KEY: string;
  API_SHARED_SECRET?: string;
  MAX_REQUESTS_PER_DAY: string;
}

interface BreakdownRequest {
  mainTask: string;
  sideTasks?: string[];
}

interface StagePayload {
  title: string;
  hint?: string;
}

interface BreakdownResponse {
  main: { stages: StagePayload[] };
  sides: { stages: StagePayload[] }[];
}

const DEEPSEEK_URL = "https://api.deepseek.com/chat/completions";
const MODEL = "deepseek-chat";

export default {
  async fetch(request: Request, env: Env, ctx: ExecutionContext): Promise<Response> {
    const url = new URL(request.url);

    if (request.method === "OPTIONS") {
      return cors(new Response(null, { status: 204 }));
    }

    if (url.pathname === "/health" && request.method === "GET") {
      return cors(json({ ok: true, service: "daily-intent-api" }));
    }

    if (url.pathname === "/v1/breakdown" && request.method === "POST") {
      return cors(await handleBreakdown(request, env, ctx));
    }

    return cors(json({ error: "Not found" }, 404));
  },
};

async function handleBreakdown(
  request: Request,
  env: Env,
  ctx: ExecutionContext
): Promise<Response> {
  if (env.API_SHARED_SECRET) {
    const secret = request.headers.get("X-API-Secret");
    if (secret !== env.API_SHARED_SECRET) {
      return json({ error: "Unauthorized" }, 401);
    }
  }

  const deviceId = request.headers.get("X-Device-ID")?.trim();
  if (!deviceId || deviceId.length < 8 || deviceId.length > 128) {
    return json({ error: "Missing or invalid X-Device-ID header" }, 400);
  }

  let body: BreakdownRequest;
  try {
    body = await request.json<BreakdownRequest>();
  } catch {
    return json({ error: "Invalid JSON body" }, 400);
  }

  const mainTask = body.mainTask?.trim();
  if (!mainTask || mainTask.length > 500) {
    return json({ error: "mainTask is required (max 500 chars)" }, 400);
  }

  const sideTasks = (body.sideTasks ?? [])
    .map((s) => s.trim())
    .filter(Boolean)
    .slice(0, 2);

  for (const side of sideTasks) {
    if (side.length > 300) {
      return json({ error: "Each side task max 300 chars" }, 400);
    }
  }

  const maxPerDay = parseInt(env.MAX_REQUESTS_PER_DAY || "3", 10);
  const questDay =
    request.headers.get("X-Quest-Day")?.trim() ||
    request.headers.get("X-Intent-Day")?.trim() ||
    rateLimitDateKey();
  const allowed = await peekRateLimit(deviceId, questDay, maxPerDay);
  if (!allowed) {
    return json(
      { error: "今日修改次数已用完（每任务日 3 次），请明天再试或使用默认阶段" },
      429
    );
  }

  if (!env.DEEPSEEK_API_KEY) {
    return json({ error: "Server misconfigured" }, 503);
  }

  try {
    const breakdown = await callDeepSeek(
      env.DEEPSEEK_API_KEY,
      mainTask,
      sideTasks
    );
    ctx.waitUntil(commitRateLimit(deviceId, questDay));
    return json(breakdown);
  } catch (err) {
    if (err instanceof BreakdownValidationError) {
      return json({ error: err.message }, 422);
    }
    console.error("breakdown failed", err instanceof Error ? err.message : err);
    return json(
      { error: "AI breakdown temporarily unavailable. Please retry later." },
      502
    );
  }
}

class BreakdownValidationError extends Error {
  constructor(message: string) {
    super(message);
    this.name = "BreakdownValidationError";
  }
}

/** Read-only check — quota is consumed only after a successful breakdown. */
async function peekRateLimit(deviceId: string, questDay: string, maxPerDay: number): Promise<boolean> {
  const count = await getRateLimitCount(deviceId, questDay);
  return count < maxPerDay;
}

async function commitRateLimit(deviceId: string, questDay: string): Promise<void> {
  const cache = caches.default;
  const cacheKey = rateLimitCacheRequest(deviceId, questDay);
  const count = await getRateLimitCount(deviceId, questDay);
  await cache.put(
    cacheKey,
    new Response(String(count + 1), {
      headers: { "Cache-Control": "max-age=86400" },
    })
  );
}

async function getRateLimitCount(deviceId: string, questDay: string): Promise<number> {
  const cache = caches.default;
  const cached = await cache.match(rateLimitCacheRequest(deviceId, questDay));
  if (!cached) return 0;
  return parseInt(await cached.text(), 10) || 0;
}

function rateLimitDateKey(): string {
  return new Date().toISOString().slice(0, 10);
}

function rateLimitCacheRequest(deviceId: string, day: string): Request {
  return new Request(
    `https://rate-limit.daily-intent.internal/${encodeURIComponent(deviceId)}/${day}`
  );
}

async function callDeepSeek(
  apiKey: string,
  mainTask: string,
  sideTasks: string[]
): Promise<BreakdownResponse> {
  const systemPrompt = `你是任务拆解助手。将用户的主线任务拆解为2-3个可执行、可验证、按顺序的阶段；每条支线任务拆解为2-3个阶段。
仅输出 JSON，格式如下：
{"main":{"stages":[{"title":"阶段名","hint":"简短说明"}]},"sides":[{"stages":[{"title":"...","hint":"..."}]}]}
sides 数组长度必须等于支线数量。每个任务的 stages 数组长度必须在 2 到 3 之间。不要输出 markdown 或其他文字。`;

  let userContent = `主线任务：${mainTask}`;
  if (sideTasks.length > 0) {
    userContent += "\n支线任务：";
    sideTasks.forEach((s, i) => {
      userContent += `\n${i + 1}. ${s}`;
    });
  } else {
    userContent += "\n支线任务：无";
  }

  const response = await fetch(DEEPSEEK_URL, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Authorization: `Bearer ${apiKey}`,
    },
    body: JSON.stringify({
      model: MODEL,
      messages: [
        { role: "system", content: systemPrompt },
        { role: "user", content: userContent },
      ],
      response_format: { type: "json_object" },
      temperature: 0.3,
    }),
  });

  if (!response.ok) {
    const text = await response.text();
    throw new Error(`DeepSeek HTTP ${response.status}: ${text.slice(0, 200)}`);
  }

  const data = (await response.json()) as {
    choices?: { message?: { content?: string } }[];
  };

  const content = data.choices?.[0]?.message?.content;
  if (!content) {
    throw new BreakdownValidationError("AI returned empty content");
  }

  let parsed: BreakdownResponse;
  try {
    parsed = JSON.parse(content) as BreakdownResponse;
  } catch {
    throw new BreakdownValidationError("AI returned invalid JSON");
  }

  if (!parsed.main?.stages?.length) {
    throw new BreakdownValidationError("AI breakdown missing main stages");
  }

  const sides = parsed.sides ?? [];
  if (sides.length !== sideTasks.length) {
    throw new BreakdownValidationError(
      `AI sides count (${sides.length}) does not match request (${sideTasks.length})`
    );
  }

  parsed.main.stages = parsed.main.stages.slice(0, 3);
  if (parsed.main.stages.length < 2) {
    throw new BreakdownValidationError("AI breakdown main must have 2-3 stages");
  }

  parsed.sides = sides.map((side, i) => {
    const stages = (side.stages ?? []).slice(0, 3);
    if (stages.length < 2) {
      throw new BreakdownValidationError(`AI breakdown side ${i + 1} must have 2-3 stages`);
    }
    return { stages };
  });

  return parsed;
}

function json(data: unknown, status = 200): Response {
  return new Response(JSON.stringify(data), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}

function cors(response: Response): Response {
  const headers = new Headers(response.headers);
  headers.set("Access-Control-Allow-Origin", "*");
  headers.set("Access-Control-Allow-Methods", "GET, POST, OPTIONS");
  headers.set(
    "Access-Control-Allow-Headers",
    "Content-Type, X-Device-ID, X-API-Secret, X-Quest-Day, X-Intent-Day"
  );
  return new Response(response.body, {
    status: response.status,
    statusText: response.statusText,
    headers,
  });
}
