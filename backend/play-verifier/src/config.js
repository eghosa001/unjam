export const PACKAGE_NAME = process.env.UNJAM_PACKAGE_NAME || 'com.eghosa.unjam';
export const PRODUCTS = Object.freeze({
  unjam_remove_ads: { nonConsumable: true },
  unjam_starter_pack: { nonConsumable: true },
  unjam_coins_500: { nonConsumable: false },
  unjam_coins_1500: { nonConsumable: false },
  unjam_coins_4000: { nonConsumable: false },
});
export const LEDGER_COLLECTION = process.env.UNJAM_LEDGER_COLLECTION || 'play_purchase_claims';
export const MAX_JSON_BYTES = 8 * 1024;
