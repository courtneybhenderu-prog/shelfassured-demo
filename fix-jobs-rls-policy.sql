-- Fast RLS Unblock for Jobs Table
-- Keeps RLS ON but allows authenticated users to create jobs
-- This is safer than disabling RLS entirely

-- Ensure RLS is enabled on jobs
ALTER TABLE public.jobs ENABLE ROW LEVEL SECURITY;

-- Remove any overly restrictive insert policy
DROP POLICY IF EXISTS jobs_insert_any ON public.jobs;
DROP POLICY IF EXISTS jobs_insert_policy ON public.jobs;
DROP POLICY IF EXISTS jobs_policy ON public.jobs;

-- Allow any AUTHENTICATED user to insert a job (temporary but safe)
CREATE POLICY jobs_insert_any ON public.jobs
FOR INSERT
TO authenticated
WITH CHECK (true);

-- Ensure SELECT policy exists so users can read jobs
DROP POLICY IF EXISTS jobs_select_any ON public.jobs;
DROP POLICY IF EXISTS jobs_select_policy ON public.jobs;

CREATE POLICY jobs_select_any ON public.jobs
FOR SELECT
TO authenticated
USING (true);

-- Reload PostgREST cache to pick up policy changes
NOTIFY pgrst, 'reload schema';

-- Verify the policies were created
SELECT 
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies 
WHERE tablename = 'jobs'
ORDER BY policyname;

