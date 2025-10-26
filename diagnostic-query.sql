-- Diagnostic query to understand current state

-- 1. Check what columns exist in stores table
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'stores' AND table_schema = 'public'
ORDER BY ordinal_position;

-- 2. Check what v_distinct_banners view currently returns
SELECT 
    'Current view returns' as info,
    banner_name,
    COUNT(*) as count
FROM v_distinct_banners v
LEFT JOIN stores s ON s.store_chain = v.banner_name AND s.is_active = true
GROUP BY banner_name
ORDER BY banner_name;

-- 3. Check actual store_chain values in stores
SELECT DISTINCT store_chain, COUNT(*) as store_count
FROM stores
WHERE is_active = true AND store_chain IS NOT NULL
GROUP BY store_chain
ORDER BY store_count DESC;

-- 4. Sample stores to see data
SELECT name, store_chain, banner, city, state
FROM stores
WHERE is_active = true
ORDER BY store_chain, city
LIMIT 20;
