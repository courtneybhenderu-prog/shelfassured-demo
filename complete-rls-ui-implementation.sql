-- Complete Implementation: RLS + UI Update
-- This script implements the complete solution

-- Step 1: Check current RLS policies
SELECT 'Current RLS Policies on jobs:' as info;
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

-- Step 2: Create permissive INSERT policy for authenticated users
DROP POLICY IF EXISTS "allow insert on jobs for authenticated" ON public.jobs;
DROP POLICY IF EXISTS jobs_insert_any ON public.jobs;
DROP POLICY IF EXISTS jobs_insert_policy ON public.jobs;

CREATE POLICY "allow insert on jobs for authenticated"
ON public.jobs
FOR INSERT
TO authenticated
WITH CHECK (true);

-- Step 3: Ensure SELECT policy exists
DROP POLICY IF EXISTS "allow select on jobs for authenticated" ON public.jobs;
DROP POLICY IF EXISTS jobs_select_any ON public.jobs;
DROP POLICY IF EXISTS jobs_select_policy ON public.jobs;

CREATE POLICY "allow select on jobs for authenticated"
ON public.jobs
FOR SELECT
TO authenticated
USING (true);

-- Step 4: Reload PostgREST schema
NOTIFY pgrst, 'reload schema';

-- Step 5: Verify policies were created
SELECT 'Updated RLS Policies on jobs:' as info;
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

-- Step 6: Verify job_store_skus table exists and is ready
SELECT 'job_store_skus table status:' as info;
SELECT 
    table_name,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'job_store_skus' 
  AND table_schema = 'public'
ORDER BY ordinal_position;


