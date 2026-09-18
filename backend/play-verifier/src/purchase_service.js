import { createHash } from 'node:crypto';

function fingerprint(token) {
  return createHash('sha256').update(token, 'utf8').digest('hex');
}

function bad(reason, productId = '') {
  return { valid: false, grant: false, entitlement: false, product_id: productId, reason };
}

function validateRequest(input, allowedPackage, products) {
  if (!input || typeof input !== 'object') return 'Invalid request body';
  if (input.package_name !== allowedPackage) return 'Package name is not allowed';
  if (typeof input.product_id !== 'string' || !products[input.product_id]) return 'Product is not allowed';
  if (typeof input.purchase_token !== 'string' || input.purchase_token.length < 1 || input.purchase_token.length > 4096) return 'Purchase token is invalid';
  if (typeof input.claim_id !== 'string' || input.claim_id.length < 8 || input.claim_id.length > 128) return 'Claim id is invalid';
  return '';
}

export function createPurchaseService({ allowedPackage, products, play, ledger }) {
  if (!allowedPackage || !products || !play || !ledger) throw new Error('Purchase service dependencies are required');

  return {
    async readiness() {
      const dependencies = { firestore: false, google_play: false };
      try {
        if (typeof ledger.probeAccess !== 'function') throw new Error('Firestore readiness probe unavailable');
        dependencies.firestore = (await ledger.probeAccess()) === true;
      } catch {
        return { ok: false, dependencies, reason: 'Firestore access failed' };
      }
      try {
        if (typeof play.probeAccess !== 'function') throw new Error('Google Play readiness probe unavailable');
        dependencies.google_play = (await play.probeAccess({ packageName: allowedPackage })) === true;
      } catch {
        return { ok: false, dependencies, reason: 'Google Play Purchases API access failed' };
      }
      return { ok: dependencies.firestore && dependencies.google_play, dependencies, package_name: allowedPackage };
    },

    async verify(input) {
      const error = validateRequest(input, allowedPackage, products);
      if (error) return bad(error, String(input?.product_id ?? ''));

      let purchase;
      try {
        purchase = await play.getPurchase({ packageName: allowedPackage, token: input.purchase_token });
      } catch {
        return bad('Google Play verification failed', input.product_id);
      }
      if (!purchase || purchase.purchaseState !== 'PURCHASED') {
        return bad('Google Play purchase is not in PURCHASED state', input.product_id);
      }
      if (!Array.isArray(purchase.productIds) || !purchase.productIds.includes(input.product_id)) {
        return bad('Google Play purchase does not contain the requested product', input.product_id);
      }

      const tokenHash = fingerprint(input.purchase_token);
      const issued = await ledger.issue({
        tokenHash,
        packageName: allowedPackage,
        productId: input.product_id,
        claimId: input.claim_id,
        purchase,
      });
      if (issued?.conflict) return bad('Purchase token is already bound to another product', input.product_id);
      const product = products[input.product_id];
      return {
        valid: true,
        grant: issued?.grant === true,
        entitlement: product.nonConsumable === true,
        product_id: input.product_id,
        claim_id: input.claim_id,
        claim_state: String(issued?.state ?? ''),
        reason: issued?.grant === true ? 'verified' : 'already claimed',
      };
    },

    async commit(input) {
      const error = validateRequest(input, allowedPackage, products);
      if (error) return { committed: false, product_id: String(input?.product_id ?? ''), reason: error };
      const committed = await ledger.commit({
        tokenHash: fingerprint(input.purchase_token),
        packageName: allowedPackage,
        productId: input.product_id,
        claimId: input.claim_id,
      });
      return {
        committed: committed === true,
        product_id: input.product_id,
        reason: committed === true ? 'committed' : 'claim not found',
      };
    },
  };
}
