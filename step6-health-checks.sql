-- Step 6: Health Checks
-- Quick verification that everything is working correctly

-- Check 1: No duplicates sneak in
SELECT 'Duplicate Check:' as info;
SELECT 
    job_id, 
    store_id, 
    sku_id, 
    count(*) as duplicate_count
FROM public.job_store_skus
GROUP BY 1, 2, 3
HAVING count(*) > 1;
-- Expect 0 rows

-- Check 2: Assignment activity (sanity metric)
SELECT 'Assignment Activity (Last 14 days):' as info;
SELECT 
    date_trunc('day', created_at) as day, 
    count(*) as assignments
FROM public.job_store_skus
GROUP BY 1 
ORDER BY 1 DESC 
LIMIT 14;

-- Check 3: Data integrity - all foreign keys valid
SELECT 'Foreign Key Integrity:' as info;
SELECT 
    'job_store_skus -> jobs' as relationship,
    COUNT(*) as total_rows,
    COUNT(j.id) as valid_job_refs,
    COUNT(*) - COUNT(j.id) as orphaned_rows
FROM job_store_skus jss
LEFT JOIN jobs j ON j.id = jss.job_id

UNION ALL

SELECT 
    'job_store_skus -> stores' as relationship,
    COUNT(*) as total_rows,
    COUNT(s.id) as valid_store_refs,
    COUNT(*) - COUNT(s.id) as orphaned_rows
FROM job_store_skus jss
LEFT JOIN stores s ON s.id = jss.store_id

UNION ALL

SELECT 
    'job_store_skus -> skus' as relationship,
    COUNT(*) as total_rows,
    COUNT(sk.id) as valid_sku_refs,
    COUNT(*) - COUNT(sk.id) as orphaned_rows
FROM job_store_skus jss
LEFT JOIN skus sk ON sk.id = jss.sku_id;

-- Check 4: Recent activity summary
SELECT 'Recent Activity Summary:' as info;
SELECT 
    COUNT(*) as total_assignments,
    COUNT(DISTINCT job_id) as unique_jobs,
    COUNT(DISTINCT store_id) as unique_stores,
    COUNT(DISTINCT sku_id) as unique_skus,
    MIN(created_at) as earliest_assignment,
    MAX(created_at) as latest_assignment
FROM job_store_skus;

