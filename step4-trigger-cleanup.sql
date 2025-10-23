-- Step 4: Legacy Trigger Cleanup
-- Confirm no legacy triggers remain that could cause issues

-- Check for any remaining recalculate_job_payout triggers
SELECT 'Checking for legacy triggers:' as info;

SELECT 
    trigger_name,
    event_manipulation,
    event_object_table,
    action_statement
FROM information_schema.triggers 
WHERE trigger_name LIKE '%payout%' 
   OR trigger_name LIKE '%recalculate%'
ORDER BY event_object_table, trigger_name;

-- Check for any functions that might be problematic
SELECT 'Checking for legacy functions:' as info;

SELECT 
    routine_name,
    routine_type,
    data_type as return_type
FROM information_schema.routines 
WHERE routine_name LIKE '%payout%' 
   OR routine_name LIKE '%recalculate%'
ORDER BY routine_name;

-- If any problematic triggers exist, drop them
-- (Uncomment and modify as needed)

/*
-- Example: Drop problematic trigger
DROP TRIGGER IF EXISTS recalculate_payout_on_store_change ON public.job_stores;
DROP TRIGGER IF EXISTS recalculate_payout_on_sku_change ON public.job_skus;

-- Example: Drop problematic function
DROP FUNCTION IF EXISTS public.recalculate_job_payout() CASCADE;
DROP FUNCTION IF EXISTS public.calculate_job_payout() CASCADE;
*/
