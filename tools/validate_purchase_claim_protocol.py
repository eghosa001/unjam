from pathlib import Path

root = Path(__file__).resolve().parents[1]
checks = {
    'scripts/core/save_manager.gd': ['purchase_claim_ids'],
    'scripts/core/robust_save_manager.gd': ['_sanitize_purchase_claim_ids', 'purchase_claim_ids'],
    'scripts/systems/purchase_verifier.gd': ['claim_id', '"grant"', '"entitlement"', 'func commit(', 'supabase_publishable_key'],
    'scripts/systems/store_manager.gd': ['_claim_id_for_token', 'purchase_claim_ids', 'claim_state', '_on_claim_committed'],
    'supabase/migrations/20260922_create_purchase_ledger.sql': [
        'play_purchase_claims', 'issue_play_purchase_claim', 'commit_play_purchase_claim',
        "state in ('issued', 'committed')",
    ],
    'supabase/functions/unjam-purchase/index.ts': [
        'GOOGLE_PLAY_SERVICE_ACCOUNT_EMAIL', 'GOOGLE_PLAY_SERVICE_ACCOUNT_PRIVATE_KEY',
        'issue_play_purchase_claim', 'commit_play_purchase_claim', 'SUPABASE_PUBLISHABLE_KEYS',
    ],
    'supabase/config.toml': ['[functions.unjam-purchase]', 'verify_jwt = false'],
}
errors = []
for rel, tokens in checks.items():
    text = (root / rel).read_text(encoding='utf-8')
    for token in tokens:
        if token not in text:
            errors.append(f'{rel}: missing {token}')
if errors:
    print('Purchase claim protocol validation failed:')
    for error in errors:
        print(f' - {error}')
    raise SystemExit(1)
print('Purchase claim protocol validation passed.')
