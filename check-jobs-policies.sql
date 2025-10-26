-- Step 1: Inspect current RLS policies on jobs table
-- Run this first to see what policies exist

SELECT 
    policyname, 
    permissive, 
    roles, 
    cmd, 
    qual, 
    with_check
FROM pg_policies
WHERE schemaname = 'public' 
  AND tablename = 'jobs'
ORDER BY policyname;

