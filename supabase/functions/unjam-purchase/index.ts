import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "npm:@supabase/supabase-js@2";

const PACKAGE_NAME = "com.eghosa.unjamgam";
const GOOGLE_SCOPE = "https://www.googleapis.com/auth/androidpublisher";
const GOOGLE_TOKEN_URL = "https://oauth2.googleapis.com/token";
const PRODUCTS: Record<string, { nonConsumable: boolean }> = {
  unjam_remove_ads: { nonConsumable: true },
  unjam_starter_pack: { nonConsumable: true },
  unjam_coins_500: { nonConsumable: false },
  unjam_coins_1500: { nonConsumable: false },
  unjam_coins_4000: { nonConsumable: false },
};
let cachedToken = "";
let cachedExpiry = 0;

function response(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), { status, headers: {
    "content-type": "application/json; charset=utf-8", "cache-control": "no-store",
    "x-content-type-options": "nosniff"
  }});
}
function publishableKeys(): string[] {
  const keys: string[] = [];
  const named = Deno.env.get("SUPABASE_PUBLISHABLE_KEYS") ?? "";
  if (named) try {
    for (const value of Object.values(JSON.parse(named))) if (typeof value === "string" && value) keys.push(value);
  } catch {}
  const legacy = Deno.env.get("SUPABASE_ANON_KEY") ?? "";
  const modern = Deno.env.get("SUPABASE_PUBLISHABLE_KEY") ?? "";
  if (legacy) keys.push(legacy);
  if (modern) keys.push(modern);
  return [...new Set(keys)];
}
function secretKey(): string {
  const named = Deno.env.get("SUPABASE_SECRET_KEYS") ?? "";
  if (named) try {
    const values = Object.values(JSON.parse(named)).filter((v) => typeof v === "string" && v) as string[];
    if (values.length) return values[0];
  } catch {}
  return Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? Deno.env.get("SUPABASE_SECRET_KEY") ?? "";
}
function b64url(bytes: Uint8Array): string {
  let binary = "";
  for (const b of bytes) binary += String.fromCharCode(b);
  return btoa(binary).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/g, "");
}
function b64text(text: string): string { return b64url(new TextEncoder().encode(text)); }
function pkcs8(pem: string): ArrayBuffer {
  const raw = pem.replace(/\\n/g, "\n")
    .replace("-----BEGIN PRIVATE KEY-----", "").replace("-----END PRIVATE KEY-----", "").replace(/\s/g, "");
  const bin = atob(raw);
  const out = new Uint8Array(bin.length);
  for (let i = 0; i < bin.length; i++) out[i] = bin.charCodeAt(i);
  return out.buffer;
}
async function googleToken(): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  if (cachedToken && cachedExpiry > now + 120) return cachedToken;
  const email = Deno.env.get("GOOGLE_PLAY_SERVICE_ACCOUNT_EMAIL") ?? "";
  const privateKey = Deno.env.get("GOOGLE_PLAY_SERVICE_ACCOUNT_PRIVATE_KEY") ?? "";
  if (!email || !privateKey) throw new Error("Google Play service account secrets missing");
  const header = b64text(JSON.stringify({ alg: "RS256", typ: "JWT" }));
  const claims = b64text(JSON.stringify({ iss: email, scope: GOOGLE_SCOPE, aud: GOOGLE_TOKEN_URL, iat: now, exp: now + 3600 }));
  const unsigned = `${header}.${claims}`;
  const key = await crypto.subtle.importKey("pkcs8", pkcs8(privateKey), { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" }, false, ["sign"]);
  const sig = new Uint8Array(await crypto.subtle.sign("RSASSA-PKCS1-v1_5", key, new TextEncoder().encode(unsigned)));
  const assertion = `${unsigned}.${b64url(sig)}`;
  const tokenResponse = await fetch(GOOGLE_TOKEN_URL, {
    method: "POST", headers: { "content-type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({ grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer", assertion })
  });
  if (!tokenResponse.ok) throw new Error("Google OAuth token exchange failed");
  const data = await tokenResponse.json();
  cachedToken = String(data.access_token ?? "");
  cachedExpiry = now + Number(data.expires_in ?? 3600);
  if (!cachedToken) throw new Error("Google OAuth returned no access token");
  return cachedToken;
}
async function playResponse(packageName: string, purchaseToken: string): Promise<Response> {
  const accessToken = await googleToken();
  const url = `https://androidpublisher.googleapis.com/androidpublisher/v3/applications/${encodeURIComponent(packageName)}/purchases/productsv2/tokens/${encodeURIComponent(purchaseToken)}`;
  return fetch(url, { headers: { authorization: `Bearer ${accessToken}`, accept: "application/json" } });
}
function normalize(data: any) {
  return {
    state: String(data?.purchaseStateContext?.purchaseState ?? "PURCHASE_STATE_UNSPECIFIED").replace(/^PURCHASE_STATE_/, ""),
    productIds: Array.isArray(data?.productLineItem) ? data.productLineItem.map((x: any) => String(x?.productId ?? "")).filter(Boolean) : [],
    orderId: String(data?.orderId ?? ""),
    completion: String(data?.purchaseCompletionTime ?? "")
  };
}
async function hashToken(value: string): Promise<string> {
  const bytes = new Uint8Array(await crypto.subtle.digest("SHA-256", new TextEncoder().encode(value)));
  return Array.from(bytes).map((x) => x.toString(16).padStart(2, "0")).join("");
}
function validate(input: any): string {
  if (!input || typeof input !== "object") return "Invalid request body";
  if (input.package_name !== PACKAGE_NAME) return "Package name is not allowed";
  if (typeof input.product_id !== "string" || !PRODUCTS[input.product_id]) return "Product is not allowed";
  if (typeof input.purchase_token !== "string" || input.purchase_token.length < 1 || input.purchase_token.length > 4096) return "Purchase token is invalid";
  if (typeof input.claim_id !== "string" || input.claim_id.length < 8 || input.claim_id.length > 128) return "Claim id is invalid";
  return "";
}
function bad(reason: string, productId = "", claimId = "") {
  return { valid: false, grant: false, entitlement: false, claim_state: "", product_id: productId, claim_id: claimId, reason };
}

Deno.serve(async (req) => {
  if (req.method !== "POST") return response({ error: "method not allowed" }, 405);
  const apiKey = req.headers.get("apikey") ?? "";
  if (!apiKey || !publishableKeys().includes(apiKey)) return response({ error: "invalid api key" }, 401);
  const url = Deno.env.get("SUPABASE_URL") ?? "";
  const adminKey = secretKey();
  if (!url || !adminKey) return response({ error: "Supabase server configuration unavailable" }, 503);
  const admin = createClient(url, adminKey, { auth: { persistSession: false, autoRefreshToken: false } });

  let input: any;
  try { input = await req.json(); } catch { return response({ error: "invalid json" }, 400); }

  if (input?.action === "readiness") {
    const dependencies = { postgres: false, google_play: false };
    let googlePlayDetail = "";
    try {
      const { error } = await admin.from("play_purchase_claims").select("token_hash").limit(1);
      dependencies.postgres = !error;
    } catch {}
    try {
      const probe = await playResponse(PACKAGE_NAME, "unjam-readiness-probe-invalid-token");
      dependencies.google_play = probe.ok || probe.status === 400 || probe.status === 404;
      if (!dependencies.google_play) googlePlayDetail = `play_api_http_${probe.status}`;
    } catch (error) {
      const message = error instanceof Error ? error.message : "";
      if (message.includes("service account secrets missing")) {
        googlePlayDetail = "service_account_secrets_missing";
      } else if (message.includes("OAuth token exchange failed")) {
        googlePlayDetail = "google_oauth_token_exchange_failed";
      } else {
        googlePlayDetail = "google_play_probe_failed";
      }
    }
    const ok = dependencies.postgres && dependencies.google_play;
    return response({ ok, dependencies, google_play_detail: googlePlayDetail, package_name: PACKAGE_NAME }, ok ? 200 : 503);
  }

  const errorMessage = validate(input);
  if (errorMessage) {
    if (input?.action === "commit") return response({ committed: false, product_id: String(input?.product_id ?? ""), reason: errorMessage }, 400);
    return response(bad(errorMessage, String(input?.product_id ?? ""), String(input?.claim_id ?? "")), 400);
  }
  const tokenHash = await hashToken(input.purchase_token);

  if (input.action === "verify") {
    let purchase;
    try {
      const play = await playResponse(PACKAGE_NAME, input.purchase_token);
      if (!play.ok) return response(bad("Google Play verification failed", input.product_id, input.claim_id), 400);
      purchase = normalize(await play.json());
    } catch {
      return response(bad("Google Play verification failed", input.product_id, input.claim_id), 503);
    }
    if (purchase.state !== "PURCHASED") return response(bad("Google Play purchase is not in PURCHASED state", input.product_id, input.claim_id), 400);
    if (!purchase.productIds.includes(input.product_id)) return response(bad("Google Play purchase does not contain the requested product", input.product_id, input.claim_id), 400);

    const { data, error } = await admin.rpc("issue_play_purchase_claim", {
      p_token_hash: tokenHash, p_package_name: PACKAGE_NAME, p_product_id: input.product_id,
      p_claim_id: input.claim_id, p_order_id: purchase.orderId, p_purchase_completion_time: purchase.completion
    });
    if (error || !data) return response(bad("Purchase ledger unavailable", input.product_id, input.claim_id), 503);
    if (data.conflict === true) return response(bad("Purchase token is already bound to another product", input.product_id, input.claim_id), 409);
    const grant = data.grant === true;
    return response({
      valid: true, grant, entitlement: PRODUCTS[input.product_id].nonConsumable,
      product_id: input.product_id, claim_id: input.claim_id, claim_state: String(data.state ?? ""),
      reason: grant ? "verified" : "already claimed"
    });
  }

  if (input.action === "commit") {
    const { data, error } = await admin.rpc("commit_play_purchase_claim", {
      p_token_hash: tokenHash, p_package_name: PACKAGE_NAME, p_product_id: input.product_id, p_claim_id: input.claim_id
    });
    const committed = !error && data === true;
    return response({ committed, product_id: input.product_id, reason: committed ? "committed" : "claim not found" }, committed ? 200 : 409);
  }
  return response({ error: "unknown action" }, 400);
});
