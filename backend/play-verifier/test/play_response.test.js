import test from 'node:test';
import assert from 'node:assert/strict';
import { normalizeProductPurchaseV2 } from '../src/play_response.js';

test('normalizes a purchased ProductPurchaseV2 response', () => {
  const result = normalizeProductPurchaseV2({
    purchaseStateContext: { purchaseState: 'PURCHASED' },
    productLineItem: [
      { productId: 'unjam_starter_pack', consumptionState: 'CONSUMPTION_STATE_YET_TO_BE_CONSUMED' },
    ],
    orderId: 'GPA.123',
    purchaseCompletionTime: '2026-09-17T12:00:00Z',
    acknowledgementState: 'ACKNOWLEDGEMENT_STATE_PENDING',
  });
  assert.deepEqual(result, {
    purchaseState: 'PURCHASED',
    productIds: ['unjam_starter_pack'],
    orderId: 'GPA.123',
    purchaseCompletionTime: '2026-09-17T12:00:00Z',
    acknowledgementState: 'ACKNOWLEDGEMENT_STATE_PENDING',
  });
});

test('does not treat pending Play purchases as purchased', () => {
  const result = normalizeProductPurchaseV2({
    purchaseStateContext: { purchaseState: 'PENDING' },
    productLineItem: [{ productId: 'unjam_coins_500' }],
  });
  assert.equal(result.purchaseState, 'PENDING');
});
