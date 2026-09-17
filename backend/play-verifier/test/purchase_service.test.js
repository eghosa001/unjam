import test from 'node:test';
import assert from 'node:assert/strict';
import { createPurchaseService } from '../src/purchase_service.js';

const PACKAGE = 'com.eghosa.unjam';
const REMOVE_ADS = 'unjam_remove_ads';
const COINS = 'unjam_coins_500';

function purchased(productId = REMOVE_ADS) {
  return {
    purchaseState: 'PURCHASED',
    productIds: [productId],
    orderId: 'GPA.1',
    purchaseCompletionTime: '2026-09-17T12:00:00Z',
  };
}

function fakeLedger() {
  const docs = new Map();
  return {
    async issue({ tokenHash, packageName, productId, claimId, purchase }) {
      const current = docs.get(tokenHash);
      if (!current) {
        docs.set(tokenHash, { packageName, productId, claimId, state: 'issued', purchase });
        return { grant: true, state: 'issued' };
      }
      if (current.packageName !== packageName || current.productId !== productId) {
        return { conflict: true };
      }
      return { grant: current.state === 'issued' && current.claimId === claimId, state: current.state };
    },
    async commit({ tokenHash, packageName, productId, claimId }) {
      const current = docs.get(tokenHash);
      if (!current || current.packageName !== packageName || current.productId !== productId || current.claimId !== claimId) {
        return false;
      }
      current.state = 'committed';
      return true;
    },
  };
}

function service({ playResult = purchased(), ledger = fakeLedger() } = {}) {
  return createPurchaseService({
    allowedPackage: PACKAGE,
    products: {
      [REMOVE_ADS]: { nonConsumable: true },
      [COINS]: { nonConsumable: false },
    },
    play: { async getPurchase() { return playResult; } },
    ledger,
  });
}

test('rejects package names outside the allowlist', async () => {
  const result = await service().verify({ package_name: 'evil.app', product_id: REMOVE_ADS, purchase_token: 'tok', claim_id: 'claim-aaa' });
  assert.equal(result.valid, false);
  assert.match(result.reason, /package/i);
});

test('rejects a Play purchase that is not PURCHASED', async () => {
  const result = await service({ playResult: { ...purchased(), purchaseState: 'PENDING' } }).verify({ package_name: PACKAGE, product_id: REMOVE_ADS, purchase_token: 'tok', claim_id: 'claim-aaa' });
  assert.equal(result.valid, false);
  assert.match(result.reason, /purchased/i);
});

test('rejects a token whose Play line item does not match the requested product', async () => {
  const result = await service({ playResult: purchased(COINS) }).verify({ package_name: PACKAGE, product_id: REMOVE_ADS, purchase_token: 'tok', claim_id: 'claim-aaa' });
  assert.equal(result.valid, false);
  assert.match(result.reason, /product/i);
});

test('first verified claim grants a consumable once', async () => {
  const result = await service({ playResult: purchased(COINS) }).verify({ package_name: PACKAGE, product_id: COINS, purchase_token: 'tok', claim_id: 'claim-aaa' });
  assert.deepEqual({ valid: result.valid, grant: result.grant, entitlement: result.entitlement }, { valid: true, grant: true, entitlement: false });
});

test('same claim id can safely retry before commit', async () => {
  const s = service({ playResult: purchased(COINS) });
  const request = { package_name: PACKAGE, product_id: COINS, purchase_token: 'tok', claim_id: 'claim-aaa' };
  assert.equal((await s.verify(request)).grant, true);
  assert.equal((await s.verify(request)).grant, true);
});

test('different claim id cannot regrant the same token', async () => {
  const s = service({ playResult: purchased(COINS) });
  await s.verify({ package_name: PACKAGE, product_id: COINS, purchase_token: 'tok', claim_id: 'claim-aaa' });
  const second = await s.verify({ package_name: PACKAGE, product_id: COINS, purchase_token: 'tok', claim_id: 'claim-bbb' });
  assert.equal(second.valid, true);
  assert.equal(second.grant, false);
  assert.equal(second.entitlement, false);
});

test('duplicate non-consumable still restores entitlement without reward', async () => {
  const s = service();
  const request = { package_name: PACKAGE, product_id: REMOVE_ADS, purchase_token: 'tok', claim_id: 'claim-aaa' };
  await s.verify(request);
  assert.equal((await s.commit(request)).committed, true);
  const restored = await s.verify({ ...request, claim_id: 'new-install-claim' });
  assert.equal(restored.valid, true);
  assert.equal(restored.grant, false);
  assert.equal(restored.entitlement, true);
});

test('commit rejects a claim id that did not receive the claim', async () => {
  const s = service({ playResult: purchased(COINS) });
  const request = { package_name: PACKAGE, product_id: COINS, purchase_token: 'tok', claim_id: 'claim-aaa' };
  await s.verify(request);
  const result = await s.commit({ ...request, claim_id: 'claim-bbb' });
  assert.equal(result.committed, false);
});
