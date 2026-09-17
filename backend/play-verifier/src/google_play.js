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
  };
}
