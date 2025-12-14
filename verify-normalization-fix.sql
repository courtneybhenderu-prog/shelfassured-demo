-- ========================================
-- Verify normalization fix worked
-- ========================================

-- Check if address_norm has suite/unit/building removed
SELECT 
    'Address normalization check' as check_type,
    COUNT(*) as total_stores,
    COUNT(CASE WHEN address_norm LIKE '%suite%' OR address_norm LIKE '%unit%' OR address_norm LIKE '%building%' THEN 1 END) as still_has_suite_unit,
    COUNT(CASE WHEN address_norm NOT LIKE '%suite%' AND address_norm NOT LIKE '%unit%' AND address_norm NOT LIKE '%building%' THEN 1 END) as normalized_correctly
FROM stores
WHERE address_norm IS NOT NULL;

-- Check if match_key uses address_norm correctly
SELECT 
    'Match key check' as check_type,
    address as original,
    address_norm,
    match_key,
    CASE 
        WHEN match_key LIKE '%|' || address_norm || '|%' THEN '✅ Uses address_norm'
        WHEN match_key LIKE '%suite%' OR match_key LIKE '%unit%' OR match_key LIKE '%building%' THEN '❌ Still has suite/unit/building'
        ELSE '⚠️ Unknown format'
    END as match_key_status
FROM stores
WHERE (address LIKE '%Suite%' OR address LIKE '%Unit%' OR address LIKE '%Building%')
  AND match_key IS NOT NULL
LIMIT 10;

