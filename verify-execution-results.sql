-- ========================================
-- Verify Store Reconciliation Execution Results
-- ========================================

-- Summary statistics
SELECT 
    'EXECUTION SUMMARY' as info,
    (SELECT COUNT(*) FROM stores WHERE is_active = TRUE) as active_stores,
    (SELECT COUNT(*) FROM stores WHERE is_active = FALSE) as inactive_stores,
    (SELECT COUNT(*) FROM stores WHERE created_at >= NOW() - INTERVAL '5 minutes') as new_stores_inserted,
    (SELECT COUNT(*) FROM stores WHERE updated_at >= NOW() - INTERVAL '5 minutes' AND created_at < NOW() - INTERVAL '5 minutes') as existing_stores_updated,
    (SELECT COUNT(*) FROM stores WHERE store_number IS NOT NULL) as stores_with_number;

-- Check matched stores (should have been updated, not inserted)
SELECT 
    'MATCHED STORES (Updated)' as info,
    COUNT(*) as count,
    COUNT(DISTINCT "STORE") as unique_store_names
FROM stores
WHERE updated_at >= NOW() - INTERVAL '5 minutes'
  AND created_at < NOW() - INTERVAL '5 minutes'
  AND is_active = TRUE;

-- Check new stores (should have generated display names)
SELECT 
    'NEW STORES (Inserted)' as info,
    COUNT(*) as count,
    COUNT(CASE WHEN "STORE" LIKE '% – % – % – %' THEN 1 END) as stores_with_generated_names
FROM stores
WHERE created_at >= NOW() - INTERVAL '5 minutes';

-- Sample of new stores to verify display name format
SELECT 
    'SAMPLE NEW STORES' as info,
    "STORE",
    banner,
    city,
    state,
    store_number
FROM stores
WHERE created_at >= NOW() - INTERVAL '5 minutes'
ORDER BY created_at DESC
LIMIT 10;

-- Sample of updated stores to verify STORE was preserved
SELECT 
    'SAMPLE UPDATED STORES' as info,
    "STORE",
    banner,
    city,
    state,
    store_number,
    updated_at
FROM stores
WHERE updated_at >= NOW() - INTERVAL '5 minutes'
  AND created_at < NOW() - INTERVAL '5 minutes'
ORDER BY updated_at DESC
LIMIT 10;

-- Sample of inactive stores
SELECT 
    'SAMPLE INACTIVE STORES' as info,
    "STORE",
    banner,
    city,
    state,
    is_active,
    updated_at
FROM stores
WHERE is_active = FALSE
  AND updated_at >= NOW() - INTERVAL '5 minutes'
ORDER BY updated_at DESC
LIMIT 10;

