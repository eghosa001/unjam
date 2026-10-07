import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";

const ALLOWED_KEYS = new Set([
  "highest_level",
  "stars",
  "rescued",
  "coins",
  "sound",
  "vibration",
  "music",
  "reduce_motion",
  "fast_animation",
  "decorations",
  "collection_levels",
  "crown_tokens",
  "competition_claimed_periods",
  "competition_display_name",
  "reward_double_claims",
  "lantern_shield_month",
  "lantern_shield_uses",
  "garden_last_gift_date",
  "garden_gifts_claimed",
  "daily_last_date",
  "daily_streak",
  "daily_best_streak",
  "daily_completed",
  "daily_game_choices",
  "hints_used",
  "undos_used",
  "rewarded_ads_watched",
  "privacy_consent_status",
  "total_levels_completed",
  "total_rescues",
  "perfect_clears",
  "perfect_streak",
  "best_perfect_streak",
  "milestone_chests",
  "world_badges",
  "prestige_points",
  "achievements",
  "achievement_points",
]);

const MAX_PAYLOAD_BYTES = 96 * 1024;

function json(data: unknown, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: {
      "content-type": "application/json; charset=utf-8",
      "cache-control": "no-store",
    },
  });
}

async function sha256Hex(value: string): Promise<string> {
  const bytes = new TextEncoder().encode(value);
  const digest = await crypto.subtle.digest("SHA-256", bytes);
  return [...new Uint8Array(digest)]
    .map((b) => b.toString(16).padStart(2, "0"))
    .join("");
}

function validCloudId(value: unknown): value is string {
  return typeof value === "string" && /^[0-9a-f]{64}$/i.test(value);
}

function sanitizeSave(value: unknown): Record<string, unknown> | null {
  if (!value || typeof value !== "object" || Array.isArray(value)) return null;
  const input = value as Record<string, unknown>;
  const clean: Record<string, unknown> = {};
  for (const key of ALLOWED_KEYS) {
    if (Object.prototype.hasOwnProperty.call(input, key)) {
      clean[key] = input[key];
    }
  }
  const encoded = JSON.stringify(clean);
  if (new TextEncoder().encode(encoded).byteLength > MAX_PAYLOAD_BYTES) return null;
  return clean;
}

Deno.serve(async (req: Request) => {
  if (req.method !== "POST") return json({ ok: false, reason: "POST required" }, 405);

  const expectedApiKey = Deno.env.get("SUPABASE_ANON_KEY") ?? "";
  const suppliedApiKey = req.headers.get("apikey") ?? "";
  if (expectedApiKey && suppliedApiKey !== expectedApiKey) {
    return json({ ok: false, reason: "Invalid app key" }, 401);
  }

  let body: Record<string, unknown>;
  try {
    body = await req.json();
  } catch {
    return json({ ok: false, reason: "Invalid JSON" }, 400);
  }

  const action = String(body.action ?? "");
  if (action === "health") return json({ ok: true, service: "unjam-cloud-save" });

  const cloudId = body.cloud_save_id;
  if (!validCloudId(cloudId)) {
    return json({ ok: false, reason: "Invalid cloud save identity" }, 400);
  }

  const url = Deno.env.get("SUPABASE_URL") ?? "";
  const serviceRole = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
  if (!url || !serviceRole) return json({ ok: false, reason: "Cloud save unavailable" }, 503);

  const supabase = createClient(url, serviceRole, {
    auth: { persistSession: false, autoRefreshToken: false },
  });
  const saveKeyHash = await sha256Hex(cloudId);

  if (action === "pull") {
    const { data, error } = await supabase
      .from("player_cloud_saves")
      .select("revision,payload,updated_at")
      .eq("save_key_hash", saveKeyHash)
      .maybeSingle();

    if (error) {
      console.error("cloud pull failed", { code: error.code });
      return json({ ok: false, reason: "Cloud pull failed" }, 503);
    }
    if (!data) return json({ ok: true, exists: false, revision: 0, save: {} });

    return json({
      ok: true,
      exists: true,
      revision: Number(data.revision ?? 0),
      save: data.payload ?? {},
      updated_at: data.updated_at ?? "",
    });
  }

  if (action !== "push") return json({ ok: false, reason: "Unsupported action" }, 400);

  const clean = sanitizeSave(body.save);
  if (!clean) return json({ ok: false, reason: "Invalid or oversized save payload" }, 400);

  const baseRevision = Math.max(0, Math.trunc(Number(body.base_revision ?? 0)));
  const { data: current, error: readError } = await supabase
    .from("player_cloud_saves")
    .select("revision,payload,updated_at")
    .eq("save_key_hash", saveKeyHash)
    .maybeSingle();

  if (readError) {
    console.error("cloud preflight failed", { code: readError.code });
    return json({ ok: false, reason: "Cloud save unavailable" }, 503);
  }

  if (current) {
    const currentRevision = Number(current.revision ?? 0);
    if (currentRevision !== baseRevision) {
      return json({
        ok: false,
        conflict: true,
        revision: currentRevision,
        save: current.payload ?? {},
        updated_at: current.updated_at ?? "",
      }, 409);
    }

    const payloadJson = JSON.stringify(clean);
    const payloadSha = await sha256Hex(payloadJson);
    const nextRevision = currentRevision + 1;
    const { data: updated, error: updateError } = await supabase
      .from("player_cloud_saves")
      .update({
        revision: nextRevision,
        payload: clean,
        payload_sha256: payloadSha,
        updated_at: new Date().toISOString(),
      })
      .eq("save_key_hash", saveKeyHash)
      .eq("revision", currentRevision)
      .select("revision,updated_at")
      .maybeSingle();

    if (updateError) {
      console.error("cloud update failed", { code: updateError.code });
      return json({ ok: false, reason: "Cloud update failed" }, 503);
    }
    if (!updated) {
      const { data: latest } = await supabase
        .from("player_cloud_saves")
        .select("revision,payload,updated_at")
        .eq("save_key_hash", saveKeyHash)
        .maybeSingle();
      return json({
        ok: false,
        conflict: true,
        revision: Number(latest?.revision ?? currentRevision),
        save: latest?.payload ?? {},
        updated_at: latest?.updated_at ?? "",
      }, 409);
    }

    return json({ ok: true, revision: Number(updated.revision), updated_at: updated.updated_at });
  }

  if (baseRevision !== 0) {
    return json({ ok: false, conflict: true, revision: 0, save: {} }, 409);
  }

  const payloadJson = JSON.stringify(clean);
  const payloadSha = await sha256Hex(payloadJson);
  const { data: inserted, error: insertError } = await supabase
    .from("player_cloud_saves")
    .insert({
      save_key_hash: saveKeyHash,
      revision: 1,
      payload: clean,
      payload_sha256: payloadSha,
    })
    .select("revision,updated_at")
    .single();

  if (insertError) {
    if (insertError.code === "23505") {
      const { data: latest } = await supabase
        .from("player_cloud_saves")
        .select("revision,payload,updated_at")
        .eq("save_key_hash", saveKeyHash)
        .maybeSingle();
      return json({
        ok: false,
        conflict: true,
        revision: Number(latest?.revision ?? 0),
        save: latest?.payload ?? {},
        updated_at: latest?.updated_at ?? "",
      }, 409);
    }
    console.error("cloud insert failed", { code: insertError.code });
    return json({ ok: false, reason: "Cloud insert failed" }, 503);
  }

  return json({ ok: true, revision: Number(inserted.revision), updated_at: inserted.updated_at });
});
