-- Recover earned weekly rewards when the server accepted a claim but the
-- phone lost its HTTP acknowledgement. The client generates a new random
-- 128-bit receipt for each league/week. Store ONLY its SHA-256 fingerprint.
-- Historical claims remain valid with a NULL receipt hash.
alter table public.progression_reward_claims
  add column if not exists claim_receipt_hash text;
alter table public.progression_reward_claims
  drop constraint if exists progression_reward_claims_receipt_format;
alter table public.progression_reward_claims
  add constraint progression_reward_claims_receipt_format check (
    claim_receipt_hash is null or claim_receipt_hash ~ '^[0-9a-f]{64}$'
  );

-- This is not public player authentication: the same service-only/RLS rules
-- still govern claims. A receipt only binds a retry to its original claim.
revoke all on table public.progression_reward_claims from public,anon,authenticated;
