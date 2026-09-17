# Google Play Purchase Verifier Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a Cloud Run + Firestore Google Play purchase verifier and make UNJAM consume its idempotent grant/commit protocol.

**Architecture:** A Node.js Cloud Run service verifies purchases with Google Play Developer API v3 and uses Firestore as a token-fingerprint claim ledger. The Godot client persists a per-token claim ID, grants rewards only when the server says `grant=true`, restores non-consumable entitlements when `grant=false`, commits after local persistence, and finalizes Play Billing only after commit.

**Tech Stack:** Node.js 22, built-in node:test + node:http, google-auth-library, @google-cloud/firestore, Google Play Developer API v3, Cloud Run, Firestore, Godot 4.7.2.

**Spec:** `docs/superpowers/specs/2026-09-17-google-play-purchase-verifier-design.md`

## Global Constraints
- Package remains `com.eghosa.unjam` unless the replacement Play listing rejects reuse.
- Never store or log raw Google Play purchase tokens.
- Keep Google service-account private keys out of the repository; Cloud Run uses Application Default Credentials.
- Server must allow only the five product IDs defined by StoreManager.
- `grant=false` must never regrant consumable coins or Starter Pack coins.
- Non-consumable entitlement restore must still work after reinstall.

---

### Task 1: Pure purchase-verification service
**Files:** Create `backend/play-verifier/src/purchase_service.js`; test `backend/play-verifier/test/purchase_service.test.js`.
- [ ] Write failing tests for validation, Play purchase state/product matching, first claim, same-claim retry, different-claim duplicate, and commit.
- [ ] Run `node --test backend/play-verifier/test/purchase_service.test.js` and confirm RED.
- [ ] Implement the pure service with injected Play and ledger adapters.
- [ ] Re-run the test and confirm GREEN.

### Task 2: Cloud Run adapters and HTTP API
**Files:** Create `backend/play-verifier/src/google_play.js`, `src/firestore_ledger.js`, `src/server.js`, `package.json`, `Dockerfile`, `.dockerignore`, `README.md`.
- [ ] Add HTTP-level tests with fake service dependencies where practical.
- [ ] Implement Google Play v2 purchase lookup with ADC and Firestore transaction-backed claim/commit.
- [ ] Add `/healthz`, `/verify`, `/commit`, bounded JSON body, safe errors, and no token logging.
- [ ] Run Node tests.

### Task 3: Godot claim protocol
**Files:** Modify `scripts/core/save_manager.gd`, `scripts/core/robust_save_manager.gd`, `scripts/systems/purchase_verifier.gd`, `scripts/systems/store_manager.gd`; modify monetization/restore validators.
- [ ] Add failing structural/runtime validators for persisted claim IDs and `grant=false` entitlement behavior.
- [ ] Add claim ID save state and robust sanitization.
- [ ] Send claim ID during verification; parse grant/entitlement response; add commit request.
- [ ] Grant locally once, save, commit, then consume/acknowledge. Retry commit during reconciliation without regranting locally.
- [ ] Preserve backward-compatible desktop test behavior.

### Task 4: Deployment and release documentation
**Files:** Create `backend/play-verifier/deploy.sh`; modify `docs/FRESH_PLAY_V1.md`, `RELEASE_CHECKLIST.md`.
- [ ] Document Google Cloud project/API/Firestore/Cloud Run creation and Play Console service-account grant.
- [ ] Document the Cloud Run URL as `UNJAM_PURCHASE_VERIFICATION_URL` and exact release-secret handoff.
- [ ] Run backend tests and repository CI; review diff before merge.
