import { FieldValue, Firestore } from '@google-cloud/firestore';

export function createFirestoreLedger({ db = new Firestore(), collectionName = 'play_purchase_claims' } = {}) {
  const collection = db.collection(collectionName);
  return {
    async issue({ tokenHash, packageName, productId, claimId, purchase }) {
      const ref = collection.doc(tokenHash);
      return db.runTransaction(async (tx) => {
        const snapshot = await tx.get(ref);
        if (!snapshot.exists) {
          tx.create(ref, {
            package_name: packageName,
            product_id: productId,
            order_id: purchase.orderId || null,
            purchase_completion_time: purchase.purchaseCompletionTime || null,
            claim_id: claimId,
            state: 'issued',
            first_seen_at: FieldValue.serverTimestamp(),
            last_seen_at: FieldValue.serverTimestamp(),
          });
          return { grant: true, state: 'issued' };
        }
        const current = snapshot.data() || {};
        if (current.package_name !== packageName || current.product_id !== productId) {
          return { conflict: true, state: String(current.state || '') };
        }
        tx.update(ref, { last_seen_at: FieldValue.serverTimestamp() });
        const state = String(current.state || '');
        return { grant: state === 'issued' && current.claim_id === claimId, state };
      });
    },

    async commit({ tokenHash, packageName, productId, claimId }) {
      const ref = collection.doc(tokenHash);
      return db.runTransaction(async (tx) => {
        const snapshot = await tx.get(ref);
        if (!snapshot.exists) return false;
        const current = snapshot.data() || {};
        if (current.package_name !== packageName || current.product_id !== productId || current.claim_id !== claimId) return false;
        if (current.state === 'committed') return true;
        if (current.state !== 'issued') return false;
        tx.update(ref, {
          state: 'committed',
          committed_at: FieldValue.serverTimestamp(),
          last_seen_at: FieldValue.serverTimestamp(),
        });
        return true;
      });
    },
  };
}
