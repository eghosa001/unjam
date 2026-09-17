from pathlib import Path

root = Path(__file__).resolve().parents[1]
checks = {
    'scripts/core/save_manager.gd': ['purchase_claim_ids'],
    'scripts/core/robust_save_manager.gd': ['_sanitize_purchase_claim_ids', 'purchase_claim_ids'],
    'scripts/systems/purchase_verifier.gd': ['claim_id', '"grant"', '"entitlement"', 'func commit('],
    'scripts/systems/store_manager.gd': ['_claim_id_for_token', 'purchase_claim_ids', 'claim_state', '_on_claim_committed'],
    'backend/play-verifier/src/firestore_ledger.js': ['play_purchase_claims', "state: 'committed'"],
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
