import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";

// Only anonymous aggregates. No installation/player IDs, IPs, user-agent,
// purchase data, device IDs, free-form properties or raw per-player records.
const NAMES = new Set(["session_start", "level_start", "level_complete", "level_restart", "hint_used", "undo_used", "level_fail"]);
const GAMES = new Set(["all", "rescue_rush", "water_sort", "block_puzzle"]);
const BANDS = new Set([0, 1, 10, 50, 100, 500, 1000, 5000, 10000]);
function output(data: unknown, status = 200) {
  return new Response(JSON.stringify(data), { status, headers: { "content-type": "application/json", "cache-control": "no-store" } });
}
function values(name: string): string[] {
  const raw = Deno.env.get(name) ?? "";
  if (!raw) return [];
  try {
    const obj = JSON.parse(raw);
    if (obj && typeof obj === "object") return Object.values(obj).filter((x): x is string => typeof x === "string");
  } catch { return [raw]; }
  return [];
}
Deno.serve(async (req: Request) => {
  if (req.method !== "POST") return output({ ok: false }, 405);
  // Publishable keys are public identifiers, not player authentication.
  // Reject unknown app keys and validate all payloads regardless.
  const appKey = req.headers.get("apikey") ?? "";
  const permitted = [Deno.env.get("SUPABASE_ANON_KEY") ?? "", ...values("SUPABASE_PUBLISHABLE_KEYS")].filter(Boolean);
  if (!appKey || !permitted.includes(appKey)) return output({ ok: false }, 401);
  let body: Record<string, unknown>;
  try {
    if (Number(req.headers.get("content-length") ?? "0") > 4096) return output({ ok: false }, 413);
    body = await req.json();
  } catch { return output({ ok: false }, 400); }
  if (body.consent !== true || !Array.isArray(body.events) || body.events.length < 1 || body.events.length > 24) {
    return output({ ok: false }, 400);
  }
  // Per-BATCH random IDs are used for retry idempotency only. Do not accept
  // persistent installation identifiers or attach these receipts to players.
  const batchId = body.batch_id;
  if (batchId !== undefined && (typeof batchId !== "string" || !/^[0-9a-f]{32}$/.test(batchId))) {
    return output({ ok: false }, 400);
  }
  const counts = new Map<string, { event_name: string; game_id: string; level_band: number; n: number }>();
  for (const raw of body.events) {
    if (!raw || typeof raw !== "object" || Array.isArray(raw)) return output({ ok: false }, 400);
    const entry = raw as Record<string, unknown>;
    const event_name = String(entry.name ?? "");
    const game_id = String(entry.game ?? "all");
    const level_band = Number(entry.level_band ?? 0);
    if (!NAMES.has(event_name) || !GAMES.has(game_id) || !BANDS.has(level_band)) return output({ ok: false }, 400);
    const k = [event_name, game_id, level_band].join("|");
    const old = counts.get(k);
    if (old) old.n++;
    else counts.set(k, { event_name, game_id, level_band, n: 1 });
  }
  const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
  const key = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? values("SUPABASE_SECRET_KEYS")[0] ?? "";
  if (!supabaseUrl || !key) return output({ ok: false }, 503);
  const sb = createClient(supabaseUrl, key, { auth: { persistSession: false, autoRefreshToken: false } });
  // Commit the full batch in one transaction. A transient SQL error must
  // never leave a partially applied batch that is blindly retried.
  const p_events = [...counts.values()].map(row => ({
    event_name: row.event_name, game_id: row.game_id,
    level_band: row.level_band, n: row.n,
  }));
  // Old clients that do not send batch_id remain compatible. New clients
  // use a single transactional receipt so a lost acknowledgement cannot
  // cause a duplicate aggregate count when the same batch is retried.
  const { error } = batchId === undefined
    ? await sb.rpc("unjam_increment_telemetry_batch", { p_events })
    : await sb.rpc("unjam_increment_telemetry_batch_v2", { p_batch_id: batchId, p_events });
  if (error) {
    console.error("Telemetry batch counter update failed", { message: error.message });
    return output({ ok: false }, 503);
  }
  return output({ ok: true });
});
