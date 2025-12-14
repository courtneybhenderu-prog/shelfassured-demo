-- Quick verification queries for v_job_assignments view
-- Run these after deploying the view to verify everything works

-- 1) Pick a recent job id from jobs table
SELECT 'Recent jobs:' AS info;
SELECT id, title, created_at 
FROM public.jobs 
ORDER BY created_at DESC 
LIMIT 5;

-- 2) Test the view with a specific job (replace with actual job_id)
-- SELECT 'Testing view with job:' AS info;
-- SELECT * FROM public.v_job_assignments
-- WHERE job_id = '<<paste a job_id from above>>'
-- ORDER BY store_chain, store_name, sku_name;

-- 3) Check if we have any job_store_skus data
SELECT 'Job assignments count:' AS info;
SELECT COUNT(*) as total_assignments
FROM public.job_store_skus;

-- 4) Sample of actual assignments
SELECT 'Sample assignments:' AS info;
SELECT 
    jss.job_id,
    j.title as job_title,
    s.store_chain,
    s.name as store_name,
    sk.name as sku_name,
    b.name as brand_name
FROM public.job_store_skus jss
JOIN public.jobs j ON j.id = jss.job_id
JOIN public.stores s ON s.id = jss.store_id
JOIN public.skus sk ON sk.id = jss.sku_id
LEFT JOIN public.brands b ON b.id = sk.brand_id
ORDER BY jss.created_at DESC
LIMIT 5;


