-- Fix the store selector to use retailer-based filtering
-- This creates/updates v_distinct_banners to use actual store_chain values

-- Drop the old view if it exists
DROP VIEW IF EXISTS public.v_distinct_banners;

-- Create the view based on actual store_chain values in the stores table
CREATE OR REPLACE VIEW public.v_distinct_banners AS
SELECT DISTINCT
    COALESCE(store_chain, 'Unknown') AS banner_name
FROM stores
WHERE is_active = true
ORDER BY banner_name;

-- Grant access to authenticated users
GRANT SELECT ON public.v_distinct_banners TO authenticated;

-- Verify the view works
SELECT 
    banner_name,
    COUNT(*) as store_count
FROM public.v_distinct_banners v
LEFT JOIN stores s ON COALESCE(s.store_chain, 'Unknown') = v.banner_name
WHERE s.is_active = true
GROUP BY banner_name
ORDER BY store_count DESC;

