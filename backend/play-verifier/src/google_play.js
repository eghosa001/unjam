import { GoogleAuth } from 'google-auth-library';
import { normalizeProductPurchaseV2 } from './play_response.js';

const SCOPE = 'https://www.googleapis.com/auth/androidpublisher';

export function createGooglePlayClient({ auth = new GoogleAuth({ scopes: [SCOPE] }) } = {}) {
  return {
    async getPurchase({ packageName, token }) {
      const client = await auth.getClient();
      const url = `https://androidpublisher.googleapis.com/androidpublisher/v3/applications/${encodeURIComponent(packageName)}/purchases/productsv2/tokens/${encodeURIComponent(token)}`;
      const response = await client.request({ method: 'GET', url });
      return normalizeProductPurchaseV2(response.data);
    },

    async probeAccess({ packageName }) {
      const client = await auth.getClient();
      const probeToken = 'unjam-readiness-probe-invalid-token';
      const url = `https://androidpublisher.googleapis.com/androidpublisher/v3/applications/${encodeURIComponent(packageName)}/purchases/productsv2/tokens/${encodeURIComponent(probeToken)}`;
      try {
        await client.request({ method: 'GET', url });
        return true;
      } catch (error) {
        const status = Number(error?.response?.status || error?.code || 0);
        // An invalid synthetic token should be rejected only after Google has
        // authenticated this service account and authorized it for the app.
        // 401/403 therefore remain fatal readiness failures.
        if (status === 400 || status === 404) return true;
        throw error;
      }
    },
  };
}
