import test from 'node:test';
import assert from 'node:assert/strict';
import { routeRequest } from '../src/http_logic.js';

test('health endpoint is public and minimal', async () => {
  const result = await routeRequest({ method: 'GET', path: '/healthz', body: null }, {});
  assert.equal(result.status, 200);
  assert.deepEqual(result.body, { ok: true });
});

test('verify route delegates to purchase service', async () => {
  const service = { async verify(body) { return { valid: true, echoed: body.product_id }; } };
  const result = await routeRequest({ method: 'POST', path: '/verify', body: { product_id: 'unjam_remove_ads' } }, service);
  assert.equal(result.status, 200);
  assert.equal(result.body.echoed, 'unjam_remove_ads');
});

test('commit route delegates to purchase service', async () => {
  const service = { async commit() { return { committed: false, reason: 'claim not found' }; } };
  const result = await routeRequest({ method: 'POST', path: '/commit', body: {} }, service);
  assert.equal(result.status, 409);
});

test('unknown route is 404', async () => {
  const result = await routeRequest({ method: 'POST', path: '/other', body: {} }, {});
  assert.equal(result.status, 404);
});
