export function normalizeProductPurchaseV2(data = {}) {
  const rawState = data?.purchaseStateContext?.purchaseState ?? 'PURCHASE_STATE_UNSPECIFIED';
  const normalizedState = String(rawState).replace(/^PURCHASE_STATE_/, '');
  const purchaseState = ['PURCHASED', 'PENDING', 'CANCELLED'].includes(normalizedState)
    ? normalizedState
    : 'UNSPECIFIED';
  const items = Array.isArray(data.productLineItem) ? data.productLineItem : [];
  return {
    purchaseState,
    productIds: items.map((item) => String(item?.productId ?? '')).filter(Boolean),
    orderId: String(data.orderId ?? ''),
    purchaseCompletionTime: String(data.purchaseCompletionTime ?? ''),
    acknowledgementState: String(data.acknowledgementState ?? ''),
  };
}
