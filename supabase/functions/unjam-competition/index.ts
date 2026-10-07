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
  }).sort((a, b) => b.score - a.score || a.name.localeCompare(b.name))
    .map((row, index) => ({ ...row, rank: index + 1 }));

  return {
    ok: true,
    friend_code: own.friend_code,
    friend_count: friends.length,
    max_friends: MAX_FRIENDS,
    friends,
    friends_weekly: weekly,
    week_start: weekKey,
  };
}

async function addFriend(sb: any, playerHash: string, displayName: string, friendCode: string, day: Date) {
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
  return await socialSnapshot(sb, playerHash, displayName, day);
}

async function removeFriend(sb: any, playerHash: string, displayName: string, friendCode: string, day: Date) {
  const { data: target, error: targetError } = await sb.from("social_profiles")
    .select("player_hash").eq("friend_code", friendCode).maybeSingle();
  if (targetError) throw targetError;
  if (!target) return await socialSnapshot(sb, playerHash, displayName, day);
  const targetHash = String(target.player_hash);
  const a = playerHash < targetHash ? playerHash : targetHash;
  const b = playerHash < targetHash ? targetHash : playerHash;
  const { error: deleteError } = await sb.from("social_friends")
    .delete().eq("player_hash_a", a).eq("player_hash_b", b);
  if (deleteError) throw deleteError;
  return await socialSnapshot(sb, playerHash, displayName, day);
}

async function rotateFriendCode(sb: any, playerHash: string, displayName: string, day: Date) {
  await ensureSocialProfile(sb, playerHash, displayName);
  for (let attempt = 0; attempt < 6; attempt++) {
    const friendCode = randomFriendCode();
    const { error } = await sb.from("social_profiles")
      .update({ friend_code: friendCode, updated_at: new Date().toISOString() })
      .eq("player_hash", playerHash);
    if (!error) return await socialSnapshot(sb, playerHash, displayName, day);
    if (error.code !== "23505") throw error;
  }
  throw new Error("Could not rotate friend code");
}
function metric(m: Record<string, unknown>, key: string, min: number, max: number, fallback = 0): number {
  const n = Number(m[key] ?? fallback);
  return Number.isFinite(n) ? Math.max(min, Math.min(max, Math.trunc(n))) : fallback;
}
function clamp(n: number, min: number, max: number) { return Math.max(min, Math.min(max, Math.trunc(n))); }
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
function publicRows(rows: any[] | null | undefined) {
  return (rows ?? []).map((r) => ({ name: String(r.display_name ?? "PLAYER").slice(0, 20), score: Number(r.score ?? 0), games_count: Number(r.games_count ?? 0) }));
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
async function refreshTotals(sb: any, hash: string, name: string, day: Date) {
  const dayKey = isoDay(day), weekKey = isoDay(weekStart(day));
  const { data: de, error: deErr } = await sb.from("competition_entries").select("score").eq("player_hash", hash).eq("competition_day", dayKey);
  if (deErr) throw deErr;
  const dailyScore = (de ?? []).reduce((a: number, r: any) => a + Number(r.score ?? 0), 0);
  const { error: dErr } = await sb.from("competition_totals").upsert({ period_type: "daily", period_key: dayKey, player_hash: hash, display_name: name, score: dailyScore, games_count: (de ?? []).length, updated_at: new Date().toISOString() }, { onConflict: "period_type,period_key,player_hash" });
  if (dErr) throw dErr;
  const { data: we, error: weErr } = await sb.from("competition_entries").select("score").eq("player_hash", hash).eq("week_start", weekKey);
  if (weErr) throw weErr;
  const weeklyScore = (we ?? []).reduce((a: number, r: any) => a + Number(r.score ?? 0), 0);
  const { error: wErr } = await sb.from("competition_totals").upsert({ period_type: "weekly", period_key: weekKey, player_hash: hash, display_name: name, score: weeklyScore, games_count: (we ?? []).length, updated_at: new Date().toISOString() }, { onConflict: "period_type,period_key,player_hash" });
  if (wErr) throw wErr;
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

  if (action === "social_snapshot") {
    try { return json(await socialSnapshot(sb, hash, name, day)); }
    catch (error) {
      console.error("social snapshot failed", { error: String(error) });
      return json({ ok: false, reason: "Friends service unavailable" }, 503);
    }
  }
  if (action === "add_friend") {
    const friendCode = cleanFriendCode(body.friend_code);
    if (!friendCode) return json({ ok: false, reason: "Enter a valid 8-character friend code" }, 400);
    try {
      const result = await addFriend(sb, hash, name, friendCode, day);
      return json(result, result.ok ? 200 : 400);
    } catch (error) {
      console.error("add friend failed", { error: String(error) });
      return json({ ok: false, reason: "Friends service unavailable" }, 503);
    }
  }
  if (action === "remove_friend") {
    const friendCode = cleanFriendCode(body.friend_code);
    if (!friendCode) return json({ ok: false, reason: "Invalid friend code" }, 400);
    try { return json(await removeFriend(sb, hash, name, friendCode, day)); }
    catch (error) {
      console.error("remove friend failed", { error: String(error) });
      return json({ ok: false, reason: "Friends service unavailable" }, 503);
    }
  }
  if (action === "rotate_friend_code") {
    try { return json(await rotateFriendCode(sb, hash, name, day)); }
    catch (error) {
      console.error("rotate friend code failed", { error: String(error) });
      return json({ ok: false, reason: "Could not create a new friend code" }, 503);
    }
  }
  if (action === "snapshot") return json(await snapshotFor(sb, hash, day));
  if (action === "submit") {
    const gameId = String(body.game_id ?? ""); if (!GAME_IDS.has(gameId)) return json({ ok: false, reason: "Invalid game" }, 400);
    const metrics = body.metrics && typeof body.metrics === "object" && !Array.isArray(body.metrics) ? body.metrics as Record<string, unknown> : {};
    const score = scoreForGame(gameId, metrics); if (!score) return json({ ok: false, reason: "Invalid result" }, 400);
    const dayKey = isoDay(day), weekKey = isoDay(weekStart(day));
    const { data: existing, error: readError } = await sb.from("competition_entries").select("score").eq("player_hash", hash).eq("competition_day", dayKey).eq("game_id", gameId).maybeSingle();
    if (readError) return json({ ok: false, reason: "Leaderboard unavailable" }, 503);
    const bestScore = Math.max(score, Number(existing?.score ?? 0));
    if (!existing || score > Number(existing.score ?? 0)) {
      const { error } = await sb.from("competition_entries").upsert({ player_hash: hash, display_name: name, competition_day: dayKey, week_start: weekKey, game_id: gameId, score, metrics, updated_at: new Date().toISOString() }, { onConflict: "player_hash,competition_day,game_id" });
      if (error) return json({ ok: false, reason: "Leaderboard unavailable" }, 503);
    }
    try { await refreshTotals(sb, hash, name, day); } catch { return json({ ok: false, reason: "Leaderboard unavailable" }, 503); }
    return json({ ok: true, game_id: gameId, score: bestScore, snapshot: await snapshotFor(sb, hash, day) });
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
