-- Step 2: Create minimal INSERT policy for authenticated users
-- This ensures job creation works while keeping RLS enabled

-- Remove any existing restrictive policies
DROP POLICY IF EXISTS "allow insert on jobs for authenticated" ON public.jobs;
DROP POLICY IF EXISTS jobs_insert_any ON public.jobs;
DROP POLICY IF EXISTS jobs_insert_policy ON public.jobs;

-- Create permissive INSERT policy for authenticated users
CREATE POLICY "allow insert on jobs for authenticated"
ON public.jobs
FOR INSERT
TO authenticated
WITH CHECK (true);

-- Ensure SELECT policy exists (for reading jobs)
DROP POLICY IF EXISTS "allow select on jobs for authenticated" ON public.jobs;
DROP POLICY IF EXISTS jobs_select_any ON public.jobs;

CREATE POLICY "allow select on jobs for authenticated"
ON public.jobs
FOR SELECT
TO authenticated
USING (true);

-- Refresh PostgREST schema so policies take effect
NOTIFY pgrst, 'reload schema';

-- Verify policies were created
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


