-- Trigger Clean-up Verification
-- Confirm problematic triggers are removed and no secret queries exist

-- Check for existing triggers on job_store_skus table
SELECT 
    trigger_name,
    event_manipulation,
    action_timing,
    action_statement
FROM information_schema.triggers 
WHERE event_object_table = 'job_store_skus'
ORDER BY trigger_name;

-- Check for existing triggers on jobs table
SELECT 
    trigger_name,
    event_manipulation,
    action_timing,
    action_statement
FROM information_schema.triggers 
WHERE event_object_table = 'jobs'
ORDER BY trigger_name;

-- Check for existing triggers on job_stores table
SELECT 
    trigger_name,
    event_manipulation,
    action_timing,
    action_statement
FROM information_schema.triggers 
WHERE event_object_table = 'job_stores'
ORDER BY trigger_name;

-- Check for existing triggers on job_skus table
SELECT 
    trigger_name,
    event_manipulation,
    action_timing,
    action_statement
FROM information_schema.triggers 
WHERE event_object_table = 'job_skus'
ORDER BY trigger_name;

-- Verify no problematic payout calculation triggers exist
SELECT 
    trigger_name,
    event_object_table,
    action_statement
FROM information_schema.triggers 
WHERE action_statement LIKE '%payout%'
    OR action_statement LIKE '%recalculate%'
ORDER BY event_object_table, trigger_name;

-- Check for any functions that might query jobs table with different permissions
SELECT 
    proname as function_name,
    prosrc as function_source
FROM pg_proc 
WHERE prosrc LIKE '%jobs%'
    AND proname NOT LIKE '%update_updated_at%'
ORDER BY proname;


