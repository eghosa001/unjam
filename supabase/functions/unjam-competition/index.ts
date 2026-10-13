import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";

const GAME_IDS = new Set(["rescue_rush", "water_sort", "block_puzzle"]);
const DAY_MS = 86_400_000;

function json(data: unknown, status = 200) {
  return new Response(JSON.stringify(data), { status, headers: { "content-type": "application/json; charset=utf-8", "cache-control": "no-store" } });
}
function envValues(name: string): string[] {
  const raw = Deno.env.get(name) ?? "";
  if (!raw) return [];
  try {
    const parsed = JSON.parse(raw);
    if (parsed && typeof parsed === "object") return Object.values(parsed).filter((v): v is string => typeof v === "string");
  } catch { return [raw]; }
  return [];
}
function validAppKey(key: string): boolean {
  if (!key) return false;
  const accepted = [Deno.env.get("SUPABASE_ANON_KEY") ?? "", ...envValues("SUPABASE_PUBLISHABLE_KEYS")].filter(Boolean);
  return accepted.includes(key);
}
function serviceKey(): string {
  return Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? envValues("SUPABASE_SECRET_KEYS")[0] ?? "";
}
async function sha256Hex(value: string): Promise<string> {
  const digest = await crypto.subtle.digest("SHA-256", new TextEncoder().encode(value));
  return [...new Uint8Array(digest)].map((b) => b.toString(16).padStart(2, "0")).join("");
}
function validCloudId(value: unknown): value is string { return typeof value === "string" && /^[0-9a-f]{64}$/i.test(value); }
function cleanName(value: unknown, cloudId: string): string {
  const raw = typeof value === "string" ? value.replace(/[\r\n\t]/g, " ").trim() : "";
  const safe = raw.replace(/[^\p{L}\p{N} _.-]/gu, "").slice(0, 20);
  return safe || `PLAYER ${cloudId.slice(-6).toUpperCase()}`;
}

const FRIEND_CODE_CHARS = "23456789ABCDEFGHJKLMNPQRSTUVWXYZ";
const MAX_FRIENDS = 50;

function cleanFriendCode(value: unknown): string {
  const code = typeof value === "string" ? value.trim().toUpperCase().replace(/[^A-Z0-9]/g, "") : "";
  return /^[23456789ABCDEFGHJKLMNPQRSTUVWXYZ]{8}$/.test(code) ? code : "";
}

function randomFriendCode(): string {
  const bytes = crypto.getRandomValues(new Uint8Array(8));
  let out = "";
  for (const byte of bytes) out += FRIEND_CODE_CHARS[byte % FRIEND_CODE_CHARS.length];
  return out;
}

async function ensureSocialProfile(sb: any, playerHash: string, displayName: string) {
  const { data: existing, error: readError } = await sb.from("social_profiles")
    .select("friend_code,display_name").eq("player_hash", playerHash).maybeSingle();
  if (readError) throw readError;
  if (existing) {
    if (String(existing.display_name ?? "") !== displayName) {
      const { error: updateError } = await sb.from("social_profiles")
        .update({ display_name: displayName, updated_at: new Date().toISOString() })
        .eq("player_hash", playerHash);
      if (updateError) throw updateError;
    }
    return { friend_code: String(existing.friend_code), display_name: displayName };
  }

  for (let attempt = 0; attempt < 6; attempt++) {
    const friendCode = randomFriendCode();
    const { error: insertError } = await sb.from("social_profiles").insert({
      player_hash: playerHash,
      friend_code: friendCode,
      display_name: displayName,
      updated_at: new Date().toISOString(),
    });
    if (!insertError) return { friend_code: friendCode, display_name: displayName };
    if (insertError.code !== "23505") throw insertError;

    const { data: raceWinner } = await sb.from("social_profiles")
      .select("friend_code,display_name").eq("player_hash", playerHash).maybeSingle();
    if (raceWinner) return {
      friend_code: String(raceWinner.friend_code),
      display_name: String(raceWinner.display_name ?? displayName),
    };
  }
  throw new Error("Could not allocate friend code");
}

async function friendHashes(sb: any, playerHash: string): Promise<string[]> {
  const [{ data: left, error: leftError }, { data: right, error: rightError }] = await Promise.all([
    sb.from("social_friends").select("player_hash_b").eq("player_hash_a", playerHash),
    sb.from("social_friends").select("player_hash_a").eq("player_hash_b", playerHash),
  ]);
  if (leftError) throw leftError;
  if (rightError) throw rightError;
  const hashes = new Set<string>();
  for (const row of left ?? []) hashes.add(String(row.player_hash_b));
  for (const row of right ?? []) hashes.add(String(row.player_hash_a));
  return [...hashes].slice(0, MAX_FRIENDS);
}

async function socialSnapshot(sb: any, playerHash: string, displayName: string, day: Date) {
  const own = await ensureSocialProfile(sb, playerHash, displayName);
  const hashes = await friendHashes(sb, playerHash);
  const allHashes = [playerHash, ...hashes];
  const weekKey = isoDay(weekStart(day));

  const profilesResult = hashes.length
    ? await sb.from("social_profiles").select("player_hash,friend_code,display_name").in("player_hash", hashes)
    : { data: [], error: null };
  if (profilesResult.error) throw profilesResult.error;

  const totalsResult = await sb.from("competition_totals")
    .select("player_hash,display_name,score,games_count")
    .eq("period_type", "weekly").eq("period_key", weekKey)
    .in("player_hash", allHashes);
  if (totalsResult.error) throw totalsResult.error;

  const profileByHash = new Map<string, any>();
  profileByHash.set(playerHash, { player_hash: playerHash, friend_code: own.friend_code, display_name: displayName });
  for (const row of profilesResult.data ?? []) profileByHash.set(String(row.player_hash), row);

  const totalByHash = new Map<string, any>();
  for (const row of totalsResult.data ?? []) totalByHash.set(String(row.player_hash), row);

  const friends = hashes.map((hash) => {
    const profile = profileByHash.get(hash) ?? {};
    return {
      name: String(profile.display_name ?? "PLAYER").slice(0, 20),
      friend_code: String(profile.friend_code ?? ""),
    };
  }).sort((a, b) => a.name.localeCompare(b.name));

  const weekly = allHashes.map((hash) => {
    const profile = profileByHash.get(hash) ?? {};
    const total = totalByHash.get(hash) ?? {};
    return {
      name: String(profile.display_name ?? total.display_name ?? "PLAYER").slice(0, 20),
      score: Number(total.score ?? 0),
      games_count: Number(total.games_count ?? 0),
      friend_code: String(profile.friend_code ?? ""),
      you: hash === playerHash,
    };
  }).sort((a, b) => b.score - a.score || a.name.localeCompare(b.name));

  return {
    ok: true,
    friend_code: own.friend_code,
    friend_count: friends.length,
    max_friends: MAX_FRIENDS,
    friends,
    friends_weekly: rankTies(weekly, "score"),
    week_start: weekKey,
  };
}

async function addFriend(sb: any, playerHash: string, displayName: string, friendCode: string, day: Date, gameId: string) {
  await ensureSocialProfile(sb, playerHash, displayName);
  const hashes = await friendHashes(sb, playerHash);
  if (hashes.length >= MAX_FRIENDS) return { ok: false, reason: "Friend list is full" };

  const { data: target, error: targetError } = await sb.from("social_profiles")
    .select("player_hash").eq("friend_code", friendCode).maybeSingle();
  if (targetError) throw targetError;
  if (!target) return { ok: false, reason: "Friend code not found" };
  const targetHash = String(target.player_hash);
  if (targetHash === playerHash) return { ok: false, reason: "You cannot add your own code" };

  const a = playerHash < targetHash ? playerHash : targetHash;
  const b = playerHash < targetHash ? targetHash : playerHash;
  const { error: insertError } = await sb.from("social_friends").insert({ player_hash_a: a, player_hash_b: b });
  if (insertError && insertError.code !== "23505") throw insertError;
  return await socialProgressSnapshot(sb, playerHash, displayName, day, gameId);
}

async function removeFriend(sb: any, playerHash: string, displayName: string, friendCode: string, day: Date, gameId: string) {
  const { data: target, error: targetError } = await sb.from("social_profiles")
    .select("player_hash").eq("friend_code", friendCode).maybeSingle();
  if (targetError) throw targetError;
  if (!target) return await socialProgressSnapshot(sb, playerHash, displayName, day, gameId);
  const targetHash = String(target.player_hash);
  const a = playerHash < targetHash ? playerHash : targetHash;
  const b = playerHash < targetHash ? targetHash : playerHash;
  const { error: deleteError } = await sb.from("social_friends")
    .delete().eq("player_hash_a", a).eq("player_hash_b", b);
  if (deleteError) throw deleteError;
  return await socialProgressSnapshot(sb, playerHash, displayName, day, gameId);
}

async function rotateFriendCode(sb: any, playerHash: string, displayName: string, day: Date, gameId: string) {
  await ensureSocialProfile(sb, playerHash, displayName);
  for (let attempt = 0; attempt < 6; attempt++) {
    const friendCode = randomFriendCode();
    const { error } = await sb.from("social_profiles")
      .update({ friend_code: friendCode, updated_at: new Date().toISOString() })
      .eq("player_hash", playerHash);
    if (!error) return await socialProgressSnapshot(sb, playerHash, displayName, day, gameId);
    if (error.code !== "23505") throw error;
  }
  throw new Error("Could not rotate friend code");
}
function metric(m: Record<string, unknown>, key: string, min: number, max: number, fallback = 0): number {
  const n = Number(m[key] ?? fallback);
  return Number.isFinite(n) ? Math.max(min, Math.min(max, Math.trunc(n))) : fallback;
}
function clamp(n: number, min: number, max: number) { return Math.max(min, Math.min(max, Math.trunc(n))); }
// Reject fabricated or incomplete daily scores instead of silently giving
// points to missing/default metrics. Keep keys compatible with all three
// currently shipped client completion payloads.
function validDailyMetrics(gameId: string, m: Record<string, unknown>): boolean {
  const integer = (name: string, low: number, high: number): boolean => {
    const n = m[name];
    return typeof n === "number" && Number.isInteger(n) && n >= low && n <= high;
  };
  if (!integer("stars", 1, 3)) return false;
  if (gameId === "rescue_rush") {
    return integer("moves", 1, 500) && integer("par", 1, 500)
      && integer("mistakes", 0, 50) && integer("hints", 0, 50)
      && integer("undos", 0, 50);
  }
  if (gameId === "water_sort") {
    return integer("moves", 1, 1000) && integer("par", 1, 1000);
  }
  if (gameId === "block_puzzle") {
    return integer("score", 0, 100000) && integer("lines", 0, 200)
      && integer("placements", 1, 1000) && integer("par", 1, 1000);
  }
  return false;
}
function scoreForGame(gameId: string, m: Record<string, unknown>): number | null {
  const stars = metric(m, "stars", 1, 3, 1);
  if (gameId === "rescue_rush") {
    const moves = metric(m, "moves", 1, 500, 500), par = metric(m, "par", 1, 500, moves);
    const mistakes = metric(m, "mistakes", 0, 50), hints = metric(m, "hints", 0, 50), undos = metric(m, "undos", 0, 50);
    return clamp(600 + stars * 150 + clamp((par - moves) * 20, -200, 200) - mistakes * 80 - hints * 140 - undos * 100, 1, 1200);
  }
  if (gameId === "water_sort") {
    const moves = metric(m, "moves", 1, 1000, 1000), par = metric(m, "par", 1, 1000, moves);
    return clamp(600 + stars * 150 + clamp((par - moves) * 15, -180, 180), 1, 1200);
  }
  if (gameId === "block_puzzle") {
    const raw = metric(m, "score", 0, 100000), lines = metric(m, "lines", 0, 200), placements = metric(m, "placements", 1, 1000, 1000), par = metric(m, "par", 1, 1000, placements);
    return clamp(350 + stars * 140 + Math.min(450, Math.trunc(raw / 4)) + Math.min(150, lines * 15) - Math.max(0, placements - par) * 8, 1, 1200);
  }
  return null;
}
function parseDay(value: unknown): Date | null {
  if (typeof value !== "string" || !/^\d{4}-\d{2}-\d{2}$/.test(value)) return null;
  const date = new Date(`${value}T00:00:00.000Z`);
  if (Number.isNaN(date.getTime())) return null;
  const today = new Date(); today.setUTCHours(0, 0, 0, 0);
  return Math.abs(date.getTime() - today.getTime()) <= DAY_MS ? date : null;
}
function isoDay(d: Date) { return d.toISOString().slice(0, 10); }
function weekStart(d: Date) { const x = new Date(d); x.setUTCDate(x.getUTCDate() - ((x.getUTCDay() + 6) % 7)); return x; }
// Conventional competition rank: two equal scores both display #1, and the
// next lower score is #3. Align row labels, personal rank and weekly rewards.
function rankTies<T extends Record<string, any>>(rows: T[], key: "score" | "rank_score"): (T & { rank: number })[] {
  let previousScore = NaN;
  let place = 0;
  return rows.map((row, index) => {
    const score = Number(row[key] ?? 0);
    if (index === 0 || score !== previousScore) place = index + 1;
    previousScore = score;
    return { ...row, rank: place };
  });
}
function publicRows(rows: any[] | null | undefined) {
  return rankTies(rows ?? [], "score").map((r) => ({
    name: String(r.display_name ?? "PLAYER").slice(0, 20),
    score: Number(r.score ?? 0), games_count: Number(r.games_count ?? 0),
    rank: r.rank,
  }));
}
async function rankFor(sb: any, type: string, key: string, playerHash: string) {
  const { data: mine } = await sb.from("competition_totals").select("score,games_count").eq("period_type", type).eq("period_key", key).eq("player_hash", playerHash).maybeSingle();
  if (!mine) return { rank: 0, score: 0, games_count: 0 };
  const { count } = await sb.from("competition_totals").select("*", { count: "exact", head: true }).eq("period_type", type).eq("period_key", key).gt("score", Number(mine.score ?? 0));
  return { rank: Number(count ?? 0) + 1, score: Number(mine.score ?? 0), games_count: Number(mine.games_count ?? 0) };
}
function rewardForRank(rank: number) {
  if (rank === 1) return { coins: 1000, crowns: 30 };
  if (rank <= 3) return { coins: 700, crowns: 20 };
  if (rank <= 10) return { coins: 400, crowns: 12 };
  if (rank <= 25) return { coins: 200, crowns: 6 };
  return { coins: 75, crowns: 2 };
}
async function previousReward(sb: any, hash: string, currentWeek: Date) {
  const key = isoDay(new Date(currentWeek.getTime() - 7 * DAY_MS));
  const { data: total } = await sb.from("competition_totals").select("score").eq("period_type", "weekly").eq("period_key", key).eq("player_hash", hash).maybeSingle();
  if (!total) return { eligible: false, claimed: false, period_key: key, rank: 0, coins: 0, crowns: 0 };
  const rank = await rankFor(sb, "weekly", key, hash), reward = rewardForRank(rank.rank);
  const { data: claim } = await sb.from("competition_reward_claims").select("claimed_at").eq("period_key", key).eq("player_hash", hash).maybeSingle();
  return { eligible: true, claimed: Boolean(claim), period_key: key, rank: rank.rank, score: rank.score, ...reward };
}
async function snapshotFor(sb: any, hash: string, day: Date) {
  const dayKey = isoDay(day), weekKey = isoDay(weekStart(day));
  const [{ data: daily }, { data: weekly }, playerDaily, playerWeekly, reward] = await Promise.all([
    sb.from("competition_totals").select("display_name,score,games_count").eq("period_type", "daily").eq("period_key", dayKey).order("score", { ascending: false }).order("updated_at", { ascending: true }).limit(20),
    sb.from("competition_totals").select("display_name,score,games_count").eq("period_type", "weekly").eq("period_key", weekKey).order("score", { ascending: false }).order("updated_at", { ascending: true }).limit(20),
    rankFor(sb, "daily", dayKey, hash), rankFor(sb, "weekly", weekKey, hash), previousReward(sb, hash, weekStart(day)),
  ]);
  return { ok: true, day: dayKey, week_start: weekKey, daily_top: publicRows(daily), weekly_top: publicRows(weekly), player_daily: playerDaily, player_weekly: playerWeekly, previous_week_reward: reward };
}
const ALL_TIME_KEY = "1970-01-01";

function cleanGameId(value: unknown): string {
  const gameId = String(value ?? "");
  return GAME_IDS.has(gameId) ? gameId : "rescue_rush";
}

function publicProgressRows(rows: any[] | null | undefined) {
  return rankTies(rows ?? [], "rank_score").map((row) => ({
    name: String(row.display_name ?? "PLAYER").slice(0, 20),
    levels_completed: Number(row.levels_completed ?? 0),
    highest_level: Number(row.highest_level ?? 0),
    stars: Number(row.stars ?? 0),
    rank: row.rank,
  }));
}

async function progressRankFor(sb: any, scopeType: string, periodKey: string, gameId: string, playerHash: string) {
  const { data: mine, error } = await sb.from("progression_rankings")
    .select("rank_score,levels_completed,highest_level,stars")
    .eq("ledger_backed", true)
    .eq("scope_type", scopeType).eq("period_key", periodKey)
    .eq("game_id", gameId).eq("player_hash", playerHash).maybeSingle();
  if (error) throw error;
  if (!mine || Number(mine.levels_completed ?? 0) <= 0) {
    return { rank: 0, levels_completed: 0, highest_level: 0, stars: 0 };
  }
  const { count, error: countError } = await sb.from("progression_rankings")
    .select("*", { count: "exact", head: true })
    .eq("ledger_backed", true)
    .eq("scope_type", scopeType).eq("period_key", periodKey).eq("game_id", gameId)
    .gt("rank_score", Number(mine.rank_score ?? 0));
  if (countError) throw countError;
  return {
    rank: Number(count ?? 0) + 1,
    levels_completed: Number(mine.levels_completed ?? 0),
    highest_level: Number(mine.highest_level ?? 0),
    stars: Number(mine.stars ?? 0),
  };
}

async function progressTop(sb: any, scopeType: string, periodKey: string, gameId: string) {
  const { data, error } = await sb.from("progression_rankings")
    .select("display_name,levels_completed,highest_level,stars,rank_score")
    .eq("ledger_backed", true)
    .eq("scope_type", scopeType).eq("period_key", periodKey).eq("game_id", gameId)
    .gt("levels_completed", 0)
    .order("rank_score", { ascending: false }).order("updated_at", { ascending: true }).limit(20);
  if (error) throw error;
  return publicProgressRows(data);
}

function progressionRewardForRank(rank: number) {
  if (rank === 1) return { coins: 350, crowns: 10 };
  if (rank <= 3) return { coins: 250, crowns: 7 };
  if (rank <= 10) return { coins: 150, crowns: 4 };
  if (rank <= 25) return { coins: 90, crowns: 2 };
  return { coins: 40, crowns: 1 };
}

async function previousProgressReward(sb: any, playerHash: string, gameId: string, currentWeek: Date) {
  const periodKey = isoDay(new Date(currentWeek.getTime() - 7 * DAY_MS));
  const rank = await progressRankFor(sb, "weekly", periodKey, gameId, playerHash);
  if (rank.rank <= 0 || rank.levels_completed <= 0) {
    return { eligible: false, claimed: false, period_key: periodKey, game_id: gameId, rank: 0, coins: 0, crowns: 0 };
  }
  const reward = progressionRewardForRank(rank.rank);
  const { data: claim, error } = await sb.from("progression_reward_claims")
    .select("claimed_at").eq("player_hash", playerHash).eq("period_key", periodKey).eq("game_id", gameId).maybeSingle();
  if (error) throw error;
  return { eligible: true, claimed: Boolean(claim), period_key: periodKey, game_id: gameId, ...rank, ...reward };
}

async function progressionSnapshotFor(sb: any, playerHash: string, displayName: string, day: Date, progress: unknown) {
  const weekKey = isoDay(weekStart(day));
  // A leaderboard read must never promote untrusted client-side save data.
  // Progress changes are accepted exclusively by the bounded completion path.
  void progress;
  const gameRankings: Record<string, unknown> = {};
  for (const gameId of GAME_IDS) {
    const [allTimeTop, weeklyTop, playerAllTime, playerWeekly, reward] = await Promise.all([
      progressTop(sb, "all_time", ALL_TIME_KEY, gameId),
      progressTop(sb, "weekly", weekKey, gameId),
      progressRankFor(sb, "all_time", ALL_TIME_KEY, gameId, playerHash),
      progressRankFor(sb, "weekly", weekKey, gameId, playerHash),
      previousProgressReward(sb, playerHash, gameId, weekStart(day)),
    ]);
    gameRankings[gameId] = {
      all_time_top: allTimeTop,
      weekly_top: weeklyTop,
      player_all_time: playerAllTime,
      player_weekly: playerWeekly,
      previous_week_reward: reward,
    };
  }
  return { ok: true, week_start: weekKey, game_rankings: gameRankings };
}

async function socialProgressSnapshot(
  sb: any,
  playerHash: string,
  displayName: string,
  day: Date,
  gameId: string,
) {
  const own = await ensureSocialProfile(sb, playerHash, displayName);
  const hashes = await friendHashes(sb, playerHash);
  const allHashes = [playerHash, ...hashes];
  const weekKey = isoDay(weekStart(day));

  const profilesResult = hashes.length
    ? await sb.from("social_profiles").select("player_hash,friend_code,display_name").in("player_hash", hashes)
    : { data: [], error: null };
  if (profilesResult.error) throw profilesResult.error;

  const [allTimeResult, weeklyResult] = await Promise.all([
    sb.from("progression_rankings")
      .select("player_hash,display_name,levels_completed,highest_level,stars,rank_score")
      .eq("ledger_backed", true)
      .eq("scope_type", "all_time").eq("period_key", ALL_TIME_KEY).eq("game_id", gameId)
      .in("player_hash", allHashes),
    sb.from("progression_rankings")
      .select("player_hash,display_name,levels_completed,highest_level,stars,rank_score")
      .eq("ledger_backed", true)
      .eq("scope_type", "weekly").eq("period_key", weekKey).eq("game_id", gameId)
      .in("player_hash", allHashes),
  ]);
  if (allTimeResult.error) throw allTimeResult.error;
  if (weeklyResult.error) throw weeklyResult.error;

  const profileByHash = new Map<string, any>();
  profileByHash.set(playerHash, { player_hash: playerHash, friend_code: own.friend_code, display_name: displayName });
  for (const row of profilesResult.data ?? []) profileByHash.set(String(row.player_hash), row);

  const friendRows = hashes.map((hash) => {
    const profile = profileByHash.get(hash) ?? {};
    return { name: String(profile.display_name ?? "PLAYER").slice(0, 20), friend_code: String(profile.friend_code ?? "") };
  }).sort((a, b) => a.name.localeCompare(b.name));

  const mapRows = (rows: any[]) => {
    const byHash = new Map<string, any>();
    for (const row of rows ?? []) byHash.set(String(row.player_hash), row);
    return allHashes.map((hash) => {
      const profile = profileByHash.get(hash) ?? {};
      const row = byHash.get(hash) ?? {};
      return {
        name: String(profile.display_name ?? row.display_name ?? "PLAYER").slice(0, 20),
        levels_completed: Number(row.levels_completed ?? 0),
        highest_level: Number(row.highest_level ?? 0),
        stars: Number(row.stars ?? 0),
        rank_score: Number(row.rank_score ?? 0),
        friend_code: String(profile.friend_code ?? ""),
        you: hash === playerHash,
      };
    }).sort((a, b) => b.rank_score - a.rank_score || a.name.localeCompare(b.name))
      .map((row, index) => ({ ...row, rank: index + 1 }));
  };

  return {
    ok: true,
    game_id: gameId,
    friend_code: own.friend_code,
    friend_count: friendRows.length,
    max_friends: MAX_FRIENDS,
    friends: friendRows,
    friends_all_time: mapRows(allTimeResult.data ?? []),
    friends_weekly: mapRows(weeklyResult.data ?? []),
    week_start: weekKey,
  };
}

Deno.serve(async (req: Request) => {
  if (req.method !== "POST") return json({ ok: false, reason: "POST required" }, 405);
  if (!validAppKey(req.headers.get("apikey") ?? "")) return json({ ok: false, reason: "Invalid app key" }, 401);
  let body: Record<string, unknown>; try { body = await req.json(); } catch { return json({ ok: false, reason: "Invalid JSON" }, 400); }
  if (String(body.action ?? "") === "health") return json({ ok: true, service: "unjam-competition" });
  const cloudId = body.cloud_save_id;
  if (!validCloudId(cloudId)) return json({ ok: false, reason: "Invalid player identity" }, 400);
  const day = parseDay(body.competition_day); if (!day) return json({ ok: false, reason: "Invalid competition day" }, 400);
  const url = Deno.env.get("SUPABASE_URL") ?? "", secret = serviceKey();
  if (!url || !secret) return json({ ok: false, reason: "Competition service unavailable" }, 503);
  const sb = createClient(url, secret, { auth: { persistSession: false, autoRefreshToken: false } });
  const hash = await sha256Hex(cloudId.toLowerCase()), name = cleanName(body.display_name, cloudId), action = String(body.action ?? "");

  if (action === "progress_snapshot") {
    try { return json(await progressionSnapshotFor(sb, hash, name, day, body.progress)); }
    catch (error) {
      console.error("progress snapshot failed", { error: String(error) });
      return json({ ok: false, reason: "Rankings unavailable" }, 503);
    }
  }
  if (action === "submit_progress") {
    const gameId = String(body.game_id ?? "");
    if (!GAME_IDS.has(gameId)) return json({ ok: false, reason: "Invalid game" }, 400);
    if (typeof body.level_number !== "number" || !Number.isInteger(body.level_number)
      || body.level_number < 1 || body.level_number > 10000
      || typeof body.stars !== "number" || !Number.isInteger(body.stars)
      || body.stars < 1 || body.stars > 3) {
      return json({ ok: false, reason: "Invalid level or stars" }, 400);
    }
    const levelNumber = body.level_number, stars = body.stars;
    const firstClear = body.first_clear === true;
    const weekKey = isoDay(weekStart(day));
    try {
      // Serialize first-clears, best-star upgrades, rate enforcement and both
      // ranking periods in one SQL transaction. Old multi-request flow could
      // lose counts when two HTTP results landed at nearly the same instant.
      const { data: update, error } = await sb.rpc("unjam_record_progress", {
        p_player_hash: hash, p_display_name: name, p_game_id: gameId,
        p_level_number: levelNumber, p_stars: stars,
        p_first_clear: firstClear, p_week: weekKey,
      });
      if (error) throw error;
      if (!update || update.ok !== true) {
        const requestedStatus = Number(update?.status ?? 503);
        const status = [400, 409, 429].includes(requestedStatus) ? requestedStatus : 503;
        return json({ ok: false, reason: String(update?.reason ?? "Rankings unavailable") }, status);
      }
      return json({
        ok: true, game_id: gameId, new_clear: Boolean(update.new_clear),
        stars_upgraded: Boolean(update.stars_upgraded),
        snapshot: await progressionSnapshotFor(sb, hash, name, day, body.all_progress),
      });
    } catch (error) {
      console.error("submit progress transaction failed", { error: String(error) });
      return json({ ok: false, reason: "Rankings unavailable" }, 503);
    }
  }
  if (action === "claim_progress_weekly") {
    const gameId = String(body.game_id ?? "");
    if (!GAME_IDS.has(gameId)) return json({ ok: false, reason: "Invalid game" }, 400);
    const currentWeek = weekStart(day);
    const defaultPeriodKey = isoDay(new Date(currentWeek.getTime() - 7 * DAY_MS));
    const requestedPeriod = body.claim_period_key;
    // Old app versions claim last week exactly as before. New clients can
    // recover an ALREADY STORED receipt up to 52 weeks after a lost reply.
    if (requestedPeriod !== undefined && (typeof requestedPeriod !== "string"
      || !/^\d{4}-\d{2}-\d{2}$/.test(requestedPeriod))) {
      return json({ ok: false, reason: "Invalid claim period" }, 400);
    }
    const periodKey = requestedPeriod === undefined ? defaultPeriodKey : requestedPeriod;
    const periodDate = new Date(`${periodKey}T00:00:00.000Z`);
    const ageWeeks = (currentWeek.getTime() - periodDate.getTime()) / (7 * DAY_MS);
    if (!Number.isFinite(ageWeeks) || !Number.isInteger(ageWeeks)
      || ageWeeks < 1 || ageWeeks > 52 || isoDay(periodDate) !== periodKey
      || periodDate.getUTCDay() !== 1) {
      return json({ ok: false, reason: "Invalid claim period" }, 400);
    }
    // A new client persists a random token before the HTTP claim. Only the
    // SAME receipt can reconcile a lost response; a second installation or
    // conflicting request must not be allowed to credit it again.
    const claimReceipt = body.claim_receipt;
    if (claimReceipt !== undefined && (typeof claimReceipt !== "string"
      || !/^[0-9a-f]{32}$/.test(claimReceipt))) {
      return json({ ok: false, reason: "Invalid claim receipt" }, 400);
    }
    const receiptHash = typeof claimReceipt === "string" ? await sha256Hex(claimReceipt) : null;
    try {
      // A stored receipt must remain redeemable after an earlier league score
      // was reclassified. Existing claims are historical settlement records;
      // recomputing today's rank first could strand a legitimate paid claim.
      const { data: prior, error: priorError } = await sb.from("progression_reward_claims")
        .select("rank,levels_completed,coins,crowns,claim_receipt_hash")
        .eq("player_hash", hash).eq("period_key", periodKey).eq("game_id", gameId).maybeSingle();
      if (priorError) throw priorError;
      if (prior) {
        return json({
          ok: true, period_key: periodKey, game_id: gameId, already_claimed: true,
          receipt_matches: Boolean(receiptHash && prior.claim_receipt_hash === receiptHash),
          rank: Number(prior.rank), levels_completed: Number(prior.levels_completed),
          coins: Number(prior.coins), crowns: Number(prior.crowns),
        });
      }
      // A brand-new reward must be claimed within eight weeks. Older dates
      // are only available for SAME-receipt recovery of previously stored
      // claims, preventing arbitrary backdated reward minting.
      if (ageWeeks > 8) return json({ ok: false, reason: "Claim period expired" }, 410);
      const rank = await progressRankFor(sb, "weekly", periodKey, gameId, hash);
      if (rank.rank <= 0 || rank.levels_completed <= 0) return json({ ok: false, reason: "No completed weekly league" }, 404);
      const reward = progressionRewardForRank(rank.rank);
      const claim = {
        player_hash: hash, period_key: periodKey, game_id: gameId,
        rank: rank.rank, levels_completed: rank.levels_completed,
        coins: reward.coins, crowns: reward.crowns,
        claim_receipt_hash: receiptHash,
      };
      const { error } = await sb.from("progression_reward_claims").insert(claim);
      if (error && error.code !== "23505") return json({ ok: false, reason: "Reward service unavailable" }, 503);
      if (error?.code === "23505") {
        const { data: existing } = await sb.from("progression_reward_claims")
          .select("rank,levels_completed,coins,crowns,claim_receipt_hash")
          .eq("player_hash", hash).eq("period_key", periodKey).eq("game_id", gameId).maybeSingle();
        // Do not send the stored hash or any raw receipt back in responses.
        const receiptMatches = Boolean(receiptHash && existing?.claim_receipt_hash === receiptHash);
        return json({
          ok: true, period_key: periodKey, game_id: gameId, already_claimed: true,
          receipt_matches: receiptMatches,
          rank: Number(existing?.rank ?? 0),
          levels_completed: Number(existing?.levels_completed ?? 0),
          coins: Number(existing?.coins ?? 0), crowns: Number(existing?.crowns ?? 0),
        });
      }
      return json({
        ok: true, period_key: periodKey, game_id: gameId, already_claimed: false,
        receipt_matches: Boolean(receiptHash),
        rank: claim.rank, levels_completed: claim.levels_completed,
        coins: claim.coins, crowns: claim.crowns,
      });
    } catch (error) {
      console.error("claim progression reward failed", { error: String(error) });
      return json({ ok: false, reason: "Reward service unavailable" }, 503);
    }
  }
  if (action === "social_snapshot") {
    try { return json(await socialProgressSnapshot(sb, hash, name, day, cleanGameId(body.game_id))); }
    catch (error) {
      console.error("social snapshot failed", { error: String(error) });
      return json({ ok: false, reason: "Friends service unavailable" }, 503);
    }
  }
  if (action === "add_friend") {
    const friendCode = cleanFriendCode(body.friend_code);
    if (!friendCode) return json({ ok: false, reason: "Enter a valid 8-character friend code" }, 400);
    try {
      const result = await addFriend(sb, hash, name, friendCode, day, cleanGameId(body.game_id));
      return json(result, result.ok ? 200 : 400);
    } catch (error) {
      console.error("add friend failed", { error: String(error) });
      return json({ ok: false, reason: "Friends service unavailable" }, 503);
    }
  }
  if (action === "remove_friend") {
    const friendCode = cleanFriendCode(body.friend_code);
    if (!friendCode) return json({ ok: false, reason: "Invalid friend code" }, 400);
    try { return json(await removeFriend(sb, hash, name, friendCode, day, cleanGameId(body.game_id))); }
    catch (error) {
      console.error("remove friend failed", { error: String(error) });
      return json({ ok: false, reason: "Friends service unavailable" }, 503);
    }
  }
  if (action === "rotate_friend_code") {
    try { return json(await rotateFriendCode(sb, hash, name, day, cleanGameId(body.game_id))); }
    catch (error) {
      console.error("rotate friend code failed", { error: String(error) });
      return json({ ok: false, reason: "Could not create a new friend code" }, 503);
    }
  }
  if (action === "snapshot") return json(await snapshotFor(sb, hash, day));
  if (action === "submit") {
    const gameId = String(body.game_id ?? ""); if (!GAME_IDS.has(gameId)) return json({ ok: false, reason: "Invalid game" }, 400);
    const metrics = body.metrics && typeof body.metrics === "object" && !Array.isArray(body.metrics) ? body.metrics as Record<string, unknown> : {};
    if (!validDailyMetrics(gameId, metrics)) return json({ ok: false, reason: "Incomplete or invalid daily result" }, 400);
    const score = scoreForGame(gameId, metrics); if (!score) return json({ ok: false, reason: "Invalid result" }, 400);
    const dayKey = isoDay(day), weekKey = isoDay(weekStart(day));
    // Commit best-score selection and BOTH ranking totals in one Postgres
    // transaction. Previous read/upsert/refresh requests could race and
    // regress scores when the same player finished multiple games at once.
    try {
      const { data: recorded, error } = await sb.rpc("unjam_record_daily_result", {
        p_player_hash: hash,
        p_display_name: name,
        p_game_id: gameId,
        p_day: dayKey,
        p_week: weekKey,
        p_score: score,
        p_metrics: metrics,
      });
      if (error) throw error;
      if (!recorded || recorded.ok !== true) {
        return json({ ok: false, reason: String(recorded?.reason ?? "Invalid Daily score") }, 400);
      }
      return json({
        ok: true, game_id: gameId, score: Number(recorded.score),
        snapshot: await snapshotFor(sb, hash, day),
      });
    } catch (error) {
      console.error("Daily result transaction failed", { error: String(error) });
      return json({ ok: false, reason: "Leaderboard unavailable" }, 503);
    }
  }
  if (action === "claim_weekly") {
    const periodKey = isoDay(new Date(weekStart(day).getTime() - 7 * DAY_MS));
    const rank = await rankFor(sb, "weekly", periodKey, hash);
    if (rank.rank <= 0 || rank.score <= 0) return json({ ok: false, reason: "No completed weekly competition" }, 404);
    const reward = rewardForRank(rank.rank), claim = { player_hash: hash, period_key: periodKey, rank: rank.rank, score: rank.score, coins: reward.coins, crowns: reward.crowns };
    const { error } = await sb.from("competition_reward_claims").insert(claim);
    if (error && error.code !== "23505") return json({ ok: false, reason: "Reward service unavailable" }, 503);
    if (error?.code === "23505") {
      const { data: existing } = await sb.from("competition_reward_claims").select("rank,score,coins,crowns").eq("player_hash", hash).eq("period_key", periodKey).maybeSingle();
      return json({ ok: true, period_key: periodKey, already_claimed: true, ...(existing ?? claim) });
    }
    return json({ ok: true, period_key: periodKey, already_claimed: false, ...claim });
  }
  return json({ ok: false, reason: "Unknown action" }, 400);
});
