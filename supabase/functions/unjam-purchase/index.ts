import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "npm:@supabase/supabase-js@2";

const PACKAGE_NAME = "com.eghosa.unjamgam";
const GOOGLE_SCOPE = "https://www.googleapis.com/auth/androidpublisher";
const GOOGLE_TOKEN_URL = "https://oauth2.googleapis.com/token";
const VOID_SYNC_MIN_INTERVAL_SECONDS = 15 * 60;
const RATE_WINDOW_SECONDS = 5 * 60;
const PRODUCTS: Record<string, { nonConsumable: boolean; coins: number }> = {
  unjam_remove_ads: { nonConsumable: true, coins: 0 },
  unjam_starter_pack: { nonConsumable: true, coins: 1000 },
  unjam_coins_500: { nonConsumable: false, coins: 500 },
  unjam_coins_1500: { nonConsumable: false, coins: 1500 },
  unjam_coins_4000: { nonConsumable: false, coins: 4000 },
};

let cachedToken = "";
let cachedExpiry = 0;

function response(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      "content-type": "application/json; charset=utf-8",
      "cache-control": "no-store",
      "x-content-type-options": "nosniff",
    },
  });
}

function publishableKeys(): string[] {
  const keys: string[] = [];
  const named = Deno.env.get("SUPABASE_PUBLISHABLE_KEYS") ?? "";
  if (named) {
    try {
      for (const value of Object.values(JSON.parse(named))) {
        if (typeof value === "string" && value) keys.push(value);
      }
    } catch {}
  }
  const legacy = Deno.env.get("SUPABASE_ANON_KEY") ?? "";
  const modern = Deno.env.get("SUPABASE_PUBLISHABLE_KEY") ?? "";
  if (legacy) keys.push(legacy);
  if (modern) keys.push(modern);
  return [...new Set(keys)];
}

function secretKey(): string {
  const named = Deno.env.get("SUPABASE_SECRET_KEYS") ?? "";
  if (named) {
    try {
      const values = Object.values(JSON.parse(named)).filter(
        (value) => typeof value === "string" && value,
      ) as string[];
      if (values.length) return values[0];
    } catch {}
  }
  return Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ??
    Deno.env.get("SUPABASE_SECRET_KEY") ?? "";
}

function b64url(bytes: Uint8Array): string {
  let binary = "";
  for (const byte of bytes) binary += String.fromCharCode(byte);
  return btoa(binary).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/g, "");
}

function b64text(text: string): string {
  return b64url(new TextEncoder().encode(text));
}

function pkcs8(pem: string): ArrayBuffer {
  const raw = pem.replace(/\\n/g, "\n")
    .replace("-----BEGIN PRIVATE KEY-----", "")
    .replace("-----END PRIVATE KEY-----", "")
    .replace(/\s/g, "");
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
  const claims = b64text(JSON.stringify({
    iss: email,
    scope: GOOGLE_SCOPE,
    aud: GOOGLE_TOKEN_URL,
    iat: now,
    exp: now + 3600,
  }));
  const unsigned = `${header}.${claims}`;
  const key = await crypto.subtle.importKey(
    "pkcs8",
    pkcs8(privateKey),
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const signature = new Uint8Array(
    await crypto.subtle.sign(
      "RSASSA-PKCS1-v1_5",
      key,
      new TextEncoder().encode(unsigned),
    ),
  );
  const assertion = `${unsigned}.${b64url(signature)}`;
  const tokenResponse = await fetch(GOOGLE_TOKEN_URL, {
    method: "POST",
    headers: { "content-type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion,
    }),
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
  const url =
    `https://androidpublisher.googleapis.com/androidpublisher/v3/applications/${encodeURIComponent(packageName)}/purchases/productsv2/tokens/${encodeURIComponent(purchaseToken)}`;
  return fetch(url, {
    headers: { authorization: `Bearer ${accessToken}`, accept: "application/json" },
  });
}

async function voidedPurchasesResponse(
  startTimeMs: number,
  endTimeMs: number,
  pageToken = "",
): Promise<Response> {
  const accessToken = await googleToken();
  const params = new URLSearchParams({
    startTime: String(startTimeMs),
    endTime: String(endTimeMs),
    type: "0",
    includeQuantityBasedPartialRefund: "true",
    "pageSelection.maxResults": "1000",
  });
  if (pageToken) params.set("pageSelection.token", pageToken);
  const url =
    `https://androidpublisher.googleapis.com/androidpublisher/v3/applications/${encodeURIComponent(PACKAGE_NAME)}/purchases/voidedpurchases?${params.toString()}`;
  return fetch(url, {
    headers: { authorization: `Bearer ${accessToken}`, accept: "application/json" },
  });
}

function normalize(data: any) {
  const lineItems = Array.isArray(data?.productLineItem) ? data.productLineItem : [];
  return {
    state: String(
      data?.purchaseStateContext?.purchaseState ?? "PURCHASE_STATE_UNSPECIFIED",
    ).replace(/^PURCHASE_STATE_/, ""),
    productIds: lineItems.map((item: any) => String(item?.productId ?? "")).filter(Boolean),
    orderId: String(data?.orderId ?? ""),
    completion: String(data?.purchaseCompletionTime ?? ""),
    acknowledgementState: String(data?.acknowledgementState ?? ""),
    lineItems,
  };
}

async function hashText(value: string): Promise<string> {
  const bytes = new Uint8Array(
    await crypto.subtle.digest("SHA-256", new TextEncoder().encode(value)),
  );
  return Array.from(bytes).map((value) => value.toString(16).padStart(2, "0")).join("");
}

async function hashToken(value: string): Promise<string> {
  return hashText(value);
}

function validInstallId(value: unknown): value is string {
  return typeof value === "string" && value.length >= 16 && value.length <= 128;
}

function validatePurchaseInput(input: any): string {
  if (!input || typeof input !== "object") return "Invalid request body";
  if (input.package_name !== PACKAGE_NAME) return "Package name is not allowed";
  if (typeof input.product_id !== "string" || !PRODUCTS[input.product_id]) {
    return "Product is not allowed";
  }
  if (
    typeof input.purchase_token !== "string" ||
    input.purchase_token.length < 1 ||
    input.purchase_token.length > 4096
  ) {
    return "Purchase token is invalid";
  }
  if (
    typeof input.claim_id !== "string" ||
    input.claim_id.length < 8 ||
    input.claim_id.length > 128
  ) {
    return "Claim id is invalid";
  }
  if (input.install_id != null && !validInstallId(input.install_id)) return "Install id is invalid";
  return "";
}

function bad(reason: string, productId = "", claimId = "") {
  return {
    valid: false,
    grant: false,
    entitlement: false,
    claim_state: "",
    product_id: productId,
    claim_id: claimId,
    reason,
  };
}

function requestSource(req: Request): string {
  const forwarded = req.headers.get("x-forwarded-for") ?? "";
  const ip = forwarded.split(",")[0]?.trim() ||
    req.headers.get("cf-connecting-ip") ||
    req.headers.get("x-real-ip") ||
    "unknown";
  return ip.slice(0, 128);
}

async function rateAllowed(
  admin: ReturnType<typeof createClient>,
  req: Request,
  input: any,
): Promise<boolean> {
  const action = String(input?.action ?? "unknown");
  const install = validInstallId(input?.install_id)
    ? input.install_id
    : (typeof input?.claim_id === "string" ? input.claim_id : "no-install");
  const keyHash = await hashText(`${action}|${requestSource(req)}|${install}`);
  const limit = action === "sync_revocations" ? 20 : 60;
  const { data, error } = await admin.rpc("consume_play_request_slot", {
    p_key_hash: keyHash,
    p_limit: limit,
    p_window_seconds: RATE_WINDOW_SECONDS,
  });
  return !error && data === true;
}

async function finalizePurchase(
  productId: string,
  purchaseToken: string,
): Promise<{ ok: boolean; detail: string }> {
  const product = PRODUCTS[productId];
  if (!product) return { ok: false, detail: "unknown_product" };

  const latest = await playResponse(PACKAGE_NAME, purchaseToken);
  if (!latest.ok) {
    return { ok: false, detail: `play_verify_http_${latest.status}` };
  }
  const purchase = normalize(await latest.json());
  if (purchase.state !== "PURCHASED" || !purchase.productIds.includes(productId)) {
    return { ok: false, detail: "purchase_not_active" };
  }

  if (product.nonConsumable) {
    if (purchase.acknowledgementState === "ACKNOWLEDGEMENT_STATE_ACKNOWLEDGED") {
      return { ok: true, detail: "already_acknowledged" };
    }
  } else {
    const productLines = purchase.lineItems.filter(
      (line: any) => String(line?.productId ?? "") === productId,
    );
    const alreadyConsumed = productLines.length > 0 &&
      productLines.every(
        (line: any) =>
          String(line?.productOfferDetails?.consumptionState ?? "") ===
            "CONSUMPTION_STATE_CONSUMED",
      );
    if (alreadyConsumed) return { ok: true, detail: "already_consumed" };
  }

  const accessToken = await googleToken();
  const suffix = product.nonConsumable ? "acknowledge" : "consume";
  const url =
    `https://androidpublisher.googleapis.com/androidpublisher/v3/applications/${encodeURIComponent(PACKAGE_NAME)}/purchases/products/${encodeURIComponent(productId)}/tokens/${encodeURIComponent(purchaseToken)}:${suffix}`;
  const finalization = await fetch(url, {
    method: "POST",
    headers: {
      authorization: `Bearer ${accessToken}`,
      accept: "application/json",
      "content-type": "application/json",
    },
    body: product.nonConsumable ? "{}" : undefined,
  });
  if (!finalization.ok) {
    return { ok: false, detail: `play_${suffix}_http_${finalization.status}` };
  }
  return { ok: true, detail: suffix };
}

async function syncVoidedPurchases(
  admin: ReturnType<typeof createClient>,
): Promise<{ ok: boolean; attempted: boolean; updated: number; detail: string }> {
  const { data: lease, error: leaseError } = await admin.rpc(
    "claim_play_voided_sync",
    { p_min_interval_seconds: VOID_SYNC_MIN_INTERVAL_SECONDS },
  );
  if (leaseError) {
    return { ok: false, attempted: false, updated: 0, detail: "voided_sync_lease_failed" };
  }
  if (!lease?.claimed) {
    return { ok: true, attempted: false, updated: 0, detail: "recent_sync_reused" };
  }

  const startTime = Number(lease.start_time_ms ?? Date.now() - 29 * 24 * 60 * 60 * 1000);
  const endTime = Date.now();
  let pageToken = "";
  let updated = 0;

  try {
    do {
      const play = await voidedPurchasesResponse(startTime, endTime, pageToken);
      if (!play.ok) {
        return {
          ok: false,
          attempted: true,
          updated,
          detail: `voided_api_http_${play.status}`,
        };
      }
      const data = await play.json();
      const items = Array.isArray(data?.voidedPurchases) ? data.voidedPurchases : [];
      for (const item of items) {
        const purchaseToken = String(item?.purchaseToken ?? "");
        if (!purchaseToken) continue;
        const tokenHash = await hashToken(purchaseToken);
        const voidedMillis = Number(item?.voidedTimeMillis ?? Date.now());
        const voidedTime = new Date(
          Number.isFinite(voidedMillis) ? voidedMillis : Date.now(),
        ).toISOString();
        const { data: marked, error } = await admin.rpc("mark_play_purchase_voided", {
          p_token_hash: tokenHash,
          p_voided_time: voidedTime,
          p_voided_reason: Number(item?.voidedReason ?? -1),
          p_voided_source: Number(item?.voidedSource ?? -1),
          p_voided_quantity: Math.max(1, Number(item?.voidedQuantity ?? 1)),
        });
        if (!error && marked === true) updated += 1;
      }
      pageToken = String(data?.tokenPagination?.nextPageToken ?? "");
    } while (pageToken);

    const { error: completeError } = await admin.rpc("complete_play_voided_sync");
    if (completeError) {
      return { ok: false, attempted: true, updated, detail: "voided_sync_commit_failed" };
    }
    return { ok: true, attempted: true, updated, detail: "voided_sync_complete" };
  } catch {
    return { ok: false, attempted: true, updated, detail: "voided_sync_exception" };
  }
}

Deno.serve(async (req) => {
  if (req.method !== "POST") return response({ error: "method not allowed" }, 405);

  const apiKey = req.headers.get("apikey") ?? "";
  if (!apiKey || !publishableKeys().includes(apiKey)) {
    return response({ error: "invalid api key" }, 401);
  }

  const url = Deno.env.get("SUPABASE_URL") ?? "";
  const adminKey = secretKey();
  if (!url || !adminKey) {
    return response({ error: "Supabase server configuration unavailable" }, 503);
  }
  const admin = createClient(url, adminKey, {
    auth: { persistSession: false, autoRefreshToken: false },
  });

  let input: any;
  try {
    input = await req.json();
  } catch {
    return response({ error: "invalid json" }, 400);
  }

  if (input?.action === "readiness") {
    const dependencies = {
      postgres: false,
      google_play: false,
      voided_purchases: false,
    };
    let googlePlayDetail = "";
    let voidedDetail = "";

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

    try {
      const now = Date.now();
      const probe = await voidedPurchasesResponse(now - 60_000, now);
      dependencies.voided_purchases = probe.ok;
      if (!probe.ok) voidedDetail = `voided_api_http_${probe.status}`;
    } catch {
      voidedDetail = "voided_api_probe_failed";
    }

    const ok = dependencies.postgres &&
      dependencies.google_play &&
      dependencies.voided_purchases;
    return response({
      ok,
      dependencies,
      google_play_detail: googlePlayDetail,
      voided_purchases_detail: voidedDetail,
      package_name: PACKAGE_NAME,
      capabilities: {
        server_finalization: true,
        voided_purchase_sync: true,
        install_bound_revocations: true,
        database_rate_limit: true,
      },
    }, ok ? 200 : 503);
  }

  if (!await rateAllowed(admin, req, input)) {
    return response({ error: "rate limit exceeded", reason: "Please retry later" }, 429);
  }

  if (input?.action === "sync_revocations") {
    if (input?.package_name !== PACKAGE_NAME || !validInstallId(input?.install_id)) {
      return response({ ok: false, revocations: [], reason: "Invalid revocation sync request" }, 400);
    }

    const sync = await syncVoidedPurchases(admin);
    const { data: revocations, error } = await admin.rpc("get_play_install_revocations", {
      p_install_id: validInstallId(input.install_id)
        ? input.install_id
        : await hashText(`legacy-install|${input.claim_id}`),
    });
    if (error) {
      return response({ ok: false, revocations: [], reason: "Revocation ledger unavailable" }, 503);
    }
    return response({
      ok: true,
      revocations: Array.isArray(revocations) ? revocations : [],
      reason: sync.ok ? sync.detail : sync.detail,
      sync,
    });
  }

  const errorMessage = validatePurchaseInput(input);
  if (errorMessage) {
    if (input?.action === "commit") {
      return response({
        committed: false,
        product_id: String(input?.product_id ?? ""),
        reason: errorMessage,
      }, 400);
    }
    return response(
      bad(
        errorMessage,
        String(input?.product_id ?? ""),
        String(input?.claim_id ?? ""),
      ),
      400,
    );
  }

  const tokenHash = await hashToken(input.purchase_token);

  if (input.action === "verify") {
    let purchase;
    try {
      const play = await playResponse(PACKAGE_NAME, input.purchase_token);
      if (!play.ok) {
        return response(
          bad("Google Play verification failed", input.product_id, input.claim_id),
          400,
        );
      }
      purchase = normalize(await play.json());
    } catch {
      return response(
        bad("Google Play verification failed", input.product_id, input.claim_id),
        503,
      );
    }

    if (purchase.state !== "PURCHASED") {
      return response(
        bad(
          "Google Play purchase is not in PURCHASED state",
          input.product_id,
          input.claim_id,
        ),
        400,
      );
    }
    if (!purchase.productIds.includes(input.product_id)) {
      return response(
        bad(
          "Google Play purchase does not contain the requested product",
          input.product_id,
          input.claim_id,
        ),
        400,
      );
    }

    const { data, error } = await admin.rpc("issue_play_purchase_claim", {
      p_token_hash: tokenHash,
      p_package_name: PACKAGE_NAME,
      p_product_id: input.product_id,
      p_claim_id: input.claim_id,
      p_order_id: purchase.orderId,
      p_purchase_completion_time: purchase.completion,
      p_install_id: input.install_id,
    });
    if (error || !data) {
      return response(
        bad("Purchase ledger unavailable", input.product_id, input.claim_id),
        503,
      );
    }
    if (data.conflict === true) {
      return response(
        bad(
          "Purchase token is already bound to another product",
          input.product_id,
          input.claim_id,
        ),
        409,
      );
    }

    const grant = data.grant === true;
    return response({
      valid: true,
      grant,
      entitlement: PRODUCTS[input.product_id].nonConsumable,
      product_id: input.product_id,
      claim_id: input.claim_id,
      claim_state: String(data.state ?? ""),
      reason: grant ? "verified" : "already claimed",
    });
  }

  if (input.action === "commit") {
    const { data, error } = await admin.rpc("commit_play_purchase_claim", {
      p_token_hash: tokenHash,
      p_package_name: PACKAGE_NAME,
      p_product_id: input.product_id,
      p_claim_id: input.claim_id,
    });
    const ledgerCommitted = !error && data === true;
    if (!ledgerCommitted) {
      return response({
        committed: false,
        product_id: input.product_id,
        reason: "claim not found",
      }, 409);
    }

    let finalization: { ok: boolean; detail: string };
    try {
      finalization = await finalizePurchase(input.product_id, input.purchase_token);
    } catch {
      finalization = { ok: false, detail: "play_finalization_exception" };
    }
    if (!finalization.ok) {
      return response({
        committed: false,
        claim_committed: true,
        product_id: input.product_id,
        reason: "Reward saved; Google Play finalization will retry",
        finalization: finalization.detail,
      }, 503);
    }

    return response({
      committed: true,
      product_id: input.product_id,
      reason: "committed",
      finalization: finalization.detail,
    });
  }

  return response({ error: "unknown action" }, 400);
});
