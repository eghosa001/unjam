import test from 'node:test';
import assert from 'node:assert/strict';
import { createGooglePlayClient } from '../src/google_play.js';

function authThat(status) {
  return {
    async getClient() {
      return {
        async request() {
          const error = new Error('probe');
          error.response = { status };
          throw error;
        },
      };
    },
  };
}

test('Play readiness treats invalid-token responses as authorized', async () => {
  for (const status of [400, 404]) {
    const play = createGooglePlayClient({ auth: authThat(status) });
    assert.equal(await play.probeAccess({ packageName: 'com.eghosa.unjamgam' }), true);
  }
});

test('Play readiness rejects missing app/API authorization', async () => {
  for (const status of [401, 403]) {
    const play = createGooglePlayClient({ auth: authThat(status) });
    await assert.rejects(() => play.probeAccess({ packageName: 'com.eghosa.unjamgam' }));
  }
});
