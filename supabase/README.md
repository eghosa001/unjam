# UNJAM Supabase monetization backend

Google Play Billing remains the Android purchase rail. Supabase replaces the previous Cloud Run + Firestore backend for purchase verification state.

- `migrations/20260922_create_purchase_ledger.sql` creates the atomic/idempotent Postgres claim ledger.
- `functions/unjam-purchase/index.ts` verifies Play purchase tokens, issues/commits claims, and exposes a readiness action.
- The app sends the project's publishable key in the `apikey` header. No player account is required for this purchase flow.
- Supabase's server-side secret/service-role key is used only inside the Edge Function and is never shipped in the app.

Required Edge Function secrets:
- `GOOGLE_PLAY_SERVICE_ACCOUNT_EMAIL`
- `GOOGLE_PLAY_SERVICE_ACCOUNT_PRIVATE_KEY` (PKCS#8 PEM)

The Google service account must have purchase-read access to the UNJAM app in Play Console. Never commit service-role keys or Google private keys.
