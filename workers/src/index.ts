/**
 * Daily Quest API — task breakdown + daily medal design via DeepSeek.
 *
 * Secrets: DEEPSEEK_API_KEY, optional API_SHARED_SECRET
 */

export interface Env {
  DEEPSEEK_API_KEY: string;
  API_SHARED_SECRET?: string;
  MAX_REQUESTS_PER_DAY: string;
  MAX_MEDAL_DESIGNS_PER_DAY?: string;
}

interface BreakdownRequest {
  mainTask: string;
  sideTasks?: string[];
}

interface MedalDesignRequest {
  mainTask: string;
  sideTasks?: string[];
  questDay?: string;
  triviaTitle?: string;
  triviaYear?: number;
  /** 设置里改任务后传 true，跳过当日缓存并重新调用 AI */
  forceRegenerate?: boolean;
}

interface StagePayload {
  title: string;
  hint?: string;
}

interface BreakdownResponse {
  main: { stages: StagePayload[] };
  sides: { stages: StagePayload[] }[];
}

interface MedalPalettePayload {
  primaryHex: string;
  secondaryHex: string;
  accentHex: string;
}

interface MedalVisualSpecPayload {
  symbolName: string;
  palette: MedalPalettePayload;
  pattern?: string;
}

interface MedalDesignResponse {
  questDayKey: string;
  schemaVersion: number;
  title: string;
  subtitle?: string;
  themeTags: string[];
  visual: MedalVisualSpecPayload;
  source: "ai" | "fallbackTemplate";
  createdAt: string;
}

const DEEPSEEK_URL = "https://api.deepseek.com/chat/completions";
const MODEL = "deepseek-chat";

const ALLOWED_SYMBOLS = new Set([
  "seal.fill", "star.fill", "flame.fill", "leaf.fill", "bolt.fill",
  "moon.stars.fill", "sun.max.fill", "sparkles", "crown.fill", "flag.fill",
  "book.fill", "figure.walk", "heart.fill", "globe.americas.fill", "wand.and.stars",
  "trophy.fill", "medal.fill", "target", "checkmark.seal.fill", "lightbulb.fill"
]);

export default {
  async fetch(request: Request, env: Env, ctx: ExecutionContext): Promise<Response> {
    const url = new URL(request.url);

    if (request.method === "OPTIONS") {
      return cors(new Response(null, { status: 204 }));
    }

    if (url.pathname === "/health" && request.method === "GET") {
      return cors(json({ ok: true, service: "daily-quest-api" }));
    }

    if (url.pathname === "/v1/breakdown" && request.method === "POST") {
      return cors(await handleBreakdown(request, env, ctx));
    }

    if (url.pathname === "/v1/medal/design" && request.method === "POST") {
      return cors(await handleMedalDesign(request, env, ctx));
    }

    return cors(json({ error: "Not found" }, 404));
  },
};

function timingSafeEqual(a: string, b: string): boolean {
  if (a.length !== b.length) return false;
  let mismatch = 0;
  for (let i = 0; i < a.length; i++) {
    mismatch |= a.charCodeAt(i) ^ b.charCodeAt(i);
  }
  return mismatch === 0;
}

/** `0` = unlimited (development). Positive values cap per device per quest day. */
export function resolveMaxPerDay(raw: string | undefined, fallback: number): number {
  const parsed = parseInt(raw ?? "", 10);
  if (!Number.isFinite(parsed)) return fallback;
  if (parsed <= 0) return 0;
  return Math.min(parsed, 20);
}

export function isUnlimitedRateLimit(maxPerDay: number): boolean {
  return maxPerDay <= 0;
}

const QUEST_DAY_RE = /^\d{4}-\d{2}-\d{2}$/;
const HEX_RE = /^#[0-9A-Fa-f]{6}$/;

function normalizeQuestDay(raw: string | undefined): string | null {
  const day = raw?.trim();
  if (!day || !QUEST_DAY_RE.test(day)) return null;
  return day;
}

function parseBreakdownBody(body: unknown): BreakdownRequest | null {
  if (!body || typeof body !== "object") return null;
  const record = body as Record<string, unknown>;
  if (typeof record.mainTask !== "string") return null;
  if (record.sideTasks !== undefined && !Array.isArray(record.sideTasks)) {
    return null;
  }
  const sideTasks = (record.sideTasks ?? []).filter(
    (item): item is string => typeof item === "string"
  );
  return { mainTask: record.mainTask, sideTasks };
}

function parseMedalDesignBody(body: unknown): MedalDesignRequest | null {
  if (!body || typeof body !== "object") return null;
  const record = body as Record<string, unknown>;
  if (typeof record.mainTask !== "string") return null;
  if (record.sideTasks !== undefined && !Array.isArray(record.sideTasks)) {
    return null;
  }
  const sideTasks = (record.sideTasks ?? []).filter(
    (item): item is string => typeof item === "string"
  );
  const questDay =
    typeof record.questDay === "string" ? record.questDay : undefined;
  const triviaTitle =
    typeof record.triviaTitle === "string" ? record.triviaTitle : undefined;
  const triviaYear =
    typeof record.triviaYear === "number" ? record.triviaYear : undefined;
  const forceRegenerate = record.forceRegenerate === true;
  return { mainTask: record.mainTask, sideTasks, questDay, triviaTitle, triviaYear, forceRegenerate };
}

function sanitizeStage(stage: unknown): StagePayload | null {
  if (!stage || typeof stage !== "object") return null;
  const record = stage as Record<string, unknown>;
  if (typeof record.title !== "string") return null;
  const title = record.title.trim();
  if (!title || title.length > 120) return null;
  let hint: string | undefined;
  if (record.hint !== undefined) {
    if (typeof record.hint !== "string") return null;
    const trimmed = record.hint.trim();
    if (trimmed.length > 200) return null;
    hint = trimmed || undefined;
  }
  return { title, hint };
}

async function handleBreakdown(
  request: Request,
  env: Env,
  ctx: ExecutionContext
): Promise<Response> {
  if (env.API_SHARED_SECRET) {
    const secret = request.headers.get("X-API-Secret") ?? "";
    if (!timingSafeEqual(secret, env.API_SHARED_SECRET)) {
      return json({ error: "Unauthorized" }, 401);
    }
  }

  const deviceId = request.headers.get("X-Device-ID")?.trim();
  if (!deviceId || deviceId.length < 8 || deviceId.length > 128) {
    return json({ error: "Missing or invalid X-Device-ID header" }, 400);
  }

  let rawBody: unknown;
  try {
    rawBody = await request.json();
  } catch {
    return json({ error: "Invalid JSON body" }, 400);
  }

  const body = parseBreakdownBody(rawBody);
  if (!body) {
    return json({ error: "Invalid request body" }, 400);
  }

  const mainTask = body.mainTask.trim();
  if (!mainTask || mainTask.length > 500) {
    return json({ error: "mainTask is required (max 500 chars)" }, 400);
  }

  const sideTasks = body.sideTasks
    .map((s) => s.trim())
    .filter(Boolean)
    .slice(0, 2);

  for (const side of sideTasks) {
    if (side.length > 300) {
      return json({ error: "Each side task max 300 chars" }, 400);
    }
  }

  const maxPerDay = resolveMaxPerDay(env.MAX_REQUESTS_PER_DAY, 3);
  const questDay =
    normalizeQuestDay(request.headers.get("X-Quest-Day") ?? undefined) ||
    normalizeQuestDay(request.headers.get("X-Intent-Day") ?? undefined) ||
    rateLimitDateKey();
  if (!isUnlimitedRateLimit(maxPerDay)) {
    const allowed = await peekRateLimit("breakdown", deviceId, questDay, maxPerDay);
    if (!allowed) {
      return json(
        {
          error: `今日拆解次数已用完（每任务日 ${maxPerDay} 次），请明天再试`,
        },
        429
      );
    }
  }

  if (!env.DEEPSEEK_API_KEY) {
    return json({ error: "Server misconfigured" }, 503);
  }

  try {
    const breakdown = await callDeepSeekBreakdown(
      env.DEEPSEEK_API_KEY,
      mainTask,
      sideTasks
    );
    if (!isUnlimitedRateLimit(maxPerDay)) {
      ctx.waitUntil(commitRateLimit("breakdown", deviceId, questDay));
    }
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

async function handleMedalDesign(
  request: Request,
  env: Env,
  ctx: ExecutionContext
): Promise<Response> {
  if (env.API_SHARED_SECRET) {
    const secret = request.headers.get("X-API-Secret") ?? "";
    if (!timingSafeEqual(secret, env.API_SHARED_SECRET)) {
      return json({ error: "Unauthorized" }, 401);
    }
  }

  const deviceId = request.headers.get("X-Device-ID")?.trim();
  if (!deviceId || deviceId.length < 8 || deviceId.length > 128) {
    return json({ error: "Missing or invalid X-Device-ID header" }, 400);
  }

  let rawBody: unknown;
  try {
    rawBody = await request.json();
  } catch {
    return json({ error: "Invalid JSON body" }, 400);
  }

  const body = parseMedalDesignBody(rawBody);
  if (!body) {
    return json({ error: "Invalid request body" }, 400);
  }

  const mainTask = body.mainTask.trim();
  if (!mainTask || mainTask.length > 500) {
    return json({ error: "mainTask is required (max 500 chars)" }, 400);
  }

  const sideTasks = (body.sideTasks ?? [])
    .map((s) => s.trim())
    .filter(Boolean)
    .slice(0, 2);

  const questDay =
    normalizeQuestDay(body.questDay) ||
    normalizeQuestDay(request.headers.get("X-Quest-Day") ?? undefined) ||
    rateLimitDateKey();

  const maxMedal = resolveMaxPerDay(env.MAX_MEDAL_DESIGNS_PER_DAY, 2);
  const forceRegenerate = body.forceRegenerate === true;

  if (!forceRegenerate) {
    const cached = await caches.default.match(medalCacheRequest(deviceId, questDay));
    if (cached) {
      return cors(cached);
    }
  } else {
    await caches.default.delete(medalCacheRequest(deviceId, questDay));
  }

  const allowed = await peekRateLimit("medal", deviceId, questDay, maxMedal);
  if (!allowed) {
    return json({ error: "今日奖牌设计次数已用完，请明天再试" }, 429);
  }

  if (!env.DEEPSEEK_API_KEY) {
    return json({ error: "Server misconfigured" }, 503);
  }

  try {
    const design = await callDeepSeekMedalDesign(
      env.DEEPSEEK_API_KEY,
      questDay,
      mainTask,
      sideTasks,
      body.triviaTitle,
      body.triviaYear
    );
    const response = json(design);
    ctx.waitUntil(commitRateLimit("medal", deviceId, questDay));
    ctx.waitUntil(caches.default.put(medalCacheRequest(deviceId, questDay), response.clone()));
    return response;
  } catch (err) {
    if (err instanceof BreakdownValidationError) {
      return json({ error: err.message }, 422);
    }
    console.error("medal design failed", err instanceof Error ? err.message : err);
    return json({ error: "Medal design temporarily unavailable." }, 502);
  }
}

class BreakdownValidationError extends Error {
  constructor(message: string) {
    super(message);
    this.name = "BreakdownValidationError";
  }
}

async function peekRateLimit(
  kind: string,
  deviceId: string,
  questDay: string,
  maxPerDay: number
): Promise<boolean> {
  const count = await getRateLimitCount(kind, deviceId, questDay);
  return count < maxPerDay;
}

async function commitRateLimit(
  kind: string,
  deviceId: string,
  questDay: string
): Promise<void> {
  const cache = caches.default;
  const cacheKey = rateLimitCacheRequest(kind, deviceId, questDay);
  const count = await getRateLimitCount(kind, deviceId, questDay);
  await cache.put(
    cacheKey,
    new Response(String(count + 1), {
      headers: { "Cache-Control": "max-age=86400" },
    })
  );
}

async function getRateLimitCount(
  kind: string,
  deviceId: string,
  questDay: string
): Promise<number> {
  const cache = caches.default;
  const cached = await cache.match(rateLimitCacheRequest(kind, deviceId, questDay));
  if (!cached) return 0;
  return parseInt(await cached.text(), 10) || 0;
}

function rateLimitDateKey(): string {
  return new Date().toISOString().slice(0, 10);
}

function rateLimitCacheRequest(kind: string, deviceId: string, day: string): Request {
  return new Request(
    `https://rate-limit.daily-quest.internal/${kind}/${encodeURIComponent(deviceId)}/${encodeURIComponent(day)}`
  );
}

function medalCacheRequest(deviceId: string, questDay: string): Request {
  return new Request(
    `https://medal-cache.daily-quest.internal/${encodeURIComponent(deviceId)}/${encodeURIComponent(questDay)}`
  );
}

async function callDeepSeekBreakdown(
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

  const content = await deepSeekJSON(apiKey, systemPrompt, userContent);
  return validateBreakdownJSON(content, sideTasks.length);
}

async function callDeepSeekMedalDesign(
  apiKey: string,
  questDayKey: string,
  mainTask: string,
  sideTasks: string[],
  triviaTitle?: string,
  triviaYear?: number
): Promise<MedalDesignResponse> {
  const systemPrompt = `你是每日任务 App 的奖牌设计师。根据任务日与任务内容，设计一枚独特的虚拟奖牌元数据（不是图片）。
仅输出 JSON：
{"title":"短标题≤30字","subtitle":"一句话故事≤80字","themeTags":["tag1","tag2"],"visual":{"symbolName":"SF Symbol名","palette":{"primaryHex":"#RRGGBB","secondaryHex":"#RRGGBB","accentHex":"#RRGGBB"},"pattern":"seal"}}
symbolName 必须从以下列表选择：seal.fill, star.fill, flame.fill, leaf.fill, bolt.fill, moon.stars.fill, sun.max.fill, sparkles, crown.fill, flag.fill, book.fill, figure.walk, heart.fill, globe.americas.fill, wand.and.stars, trophy.fill, medal.fill, target, checkmark.seal.fill, lightbulb.fill
hex 必须是 # 加 6 位十六进制。不要 markdown。`;

  let userContent = `任务日：${questDayKey}\n主线：${mainTask}`;
  if (sideTasks.length) {
    userContent += `\n支线：${sideTasks.join("；")}`;
  }
  if (triviaTitle) {
    userContent += `\n历史上的今天：${triviaYear ? triviaYear + "年 " : ""}${triviaTitle}`;
  }

  const raw = await deepSeekJSON(apiKey, systemPrompt, userContent);
  return validateMedalDesignJSON(raw, questDayKey);
}

async function deepSeekJSON(
  apiKey: string,
  systemPrompt: string,
  userContent: string
): Promise<string> {
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
      temperature: 0.5,
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
  return content;
}

function validateBreakdownJSON(content: string, sideCount: number): BreakdownResponse {
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
  if (sides.length !== sideCount) {
    throw new BreakdownValidationError(
      `AI sides count (${sides.length}) does not match request (${sideCount})`
    );
  }

  const mainStages = parsed.main.stages
    .map(sanitizeStage)
    .filter((stage): stage is StagePayload => stage !== null)
    .slice(0, 3);
  if (mainStages.length < 2) {
    throw new BreakdownValidationError("AI breakdown main must have 2-3 stages");
  }
  parsed.main.stages = mainStages;

  parsed.sides = sides.map((side, i) => {
    const stages = (side.stages ?? [])
      .map(sanitizeStage)
      .filter((stage): stage is StagePayload => stage !== null)
      .slice(0, 3);
    if (stages.length < 2) {
      throw new BreakdownValidationError(`AI breakdown side ${i + 1} must have 2-3 stages`);
    }
    return { stages };
  });

  return parsed;
}

function validateMedalDesignJSON(
  content: string,
  questDayKey: string
): MedalDesignResponse {
  let raw: Record<string, unknown>;
  try {
    raw = JSON.parse(content) as Record<string, unknown>;
  } catch {
    throw new BreakdownValidationError("AI returned invalid JSON");
  }

  const title = typeof raw.title === "string" ? raw.title.trim() : "";
  if (!title || title.length > 60) {
    throw new BreakdownValidationError("Invalid medal title");
  }

  let subtitle: string | undefined;
  if (raw.subtitle !== undefined) {
    if (typeof raw.subtitle !== "string") {
      throw new BreakdownValidationError("Invalid medal subtitle");
    }
    subtitle = raw.subtitle.trim().slice(0, 120) || undefined;
  }

  const themeTags = Array.isArray(raw.themeTags)
    ? raw.themeTags
        .filter((t): t is string => typeof t === "string")
        .map((t) => t.trim().slice(0, 32))
        .filter(Boolean)
        .slice(0, 8)
    : [];

  const visualRaw = raw.visual;
  if (!visualRaw || typeof visualRaw !== "object") {
    throw new BreakdownValidationError("Invalid medal visual");
  }
  const visual = visualRaw as Record<string, unknown>;
  const symbolName =
    typeof visual.symbolName === "string" ? visual.symbolName.trim() : "";
  if (!ALLOWED_SYMBOLS.has(symbolName)) {
    throw new BreakdownValidationError("Invalid SF Symbol name");
  }

  const paletteRaw = visual.palette;
  if (!paletteRaw || typeof paletteRaw !== "object") {
    throw new BreakdownValidationError("Invalid medal palette");
  }
  const palette = paletteRaw as Record<string, unknown>;
  const primaryHex = sanitizeHex(palette.primaryHex);
  const secondaryHex = sanitizeHex(palette.secondaryHex);
  const accentHex = sanitizeHex(palette.accentHex);
  if (!primaryHex || !secondaryHex || !accentHex) {
    throw new BreakdownValidationError("Invalid hex colors");
  }

  const pattern =
    typeof visual.pattern === "string" ? visual.pattern.trim().slice(0, 32) : undefined;

  return {
    questDayKey,
    schemaVersion: 1,
    title,
    subtitle,
    themeTags,
    visual: {
      symbolName,
      palette: { primaryHex, secondaryHex, accentHex },
      pattern,
    },
    source: "ai",
    createdAt: new Date().toISOString(),
  };
}

function sanitizeHex(value: unknown): string | null {
  if (typeof value !== "string") return null;
  const trimmed = value.trim();
  const withHash = trimmed.startsWith("#") ? trimmed : `#${trimmed}`;
  return HEX_RE.test(withHash) ? withHash : null;
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
