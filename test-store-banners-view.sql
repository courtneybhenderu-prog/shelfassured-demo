-- Test if store_banners view is accessible and returns data
-- Run this in Supabase SQL Editor to verify the view works

-- Test 1: Check if view exists
SELECT EXISTS (
    SELECT 1 
    FROM information_schema.views 
    WHERE table_schema = 'public' 
    AND table_name = 'store_banners'
) AS view_exists;

-- Test 2: Try to query the view directly
SELECT 
    'View query test' AS test_name,
    COUNT(*) AS banner_count,
    COUNT(DISTINCT banner) AS unique_banners
FROM store_banners;

-- Test 3: Get sample banners
SELECT 
    'Sample banners' AS test_name,
    banner,
    store_count
FROM store_banners
ORDER BY banner
LIMIT 10;

-- Test 4: Check permissions
SELECT 
    'Permissions check' AS test_name,
    grantee,
    privilege_type
FROM information_schema.role_table_grants
WHERE table_schema = 'public'
  AND table_name = 'store_banners';

