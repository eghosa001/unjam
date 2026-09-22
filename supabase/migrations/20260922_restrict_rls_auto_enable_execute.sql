-- Keep the Supabase platform RLS event-trigger helper internal.
-- The event trigger itself does not require anon/authenticated RPC execution.
REVOKE EXECUTE ON FUNCTION public.rls_auto_enable() FROM PUBLIC, anon, authenticated;
