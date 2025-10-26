-- Step 3: RLS Posture Setup
-- Keep RLS ON for jobs (admins see all; assignee sees own)
-- Keep RLS OFF for job_store_skus while stabilizing

-- Ensure jobs table has RLS enabled
ALTER TABLE public.jobs ENABLE ROW LEVEL SECURITY;

-- Keep job_store_skus RLS disabled for now (stabilization phase)
ALTER TABLE public.job_store_skus DISABLE ROW LEVEL SECURITY;

-- Optional: Prepare the parent-deferred policy for when you're ready to enable RLS
-- (Uncomment when ready for production security)

/*
ALTER TABLE public.job_store_skus ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS jss_rw ON public.job_store_skus;
CREATE POLICY jss_rw ON public.job_store_skus
FOR ALL
USING (
  EXISTS (
    SELECT 1 FROM public.jobs j
    WHERE j.id = job_store_skus.job_id
      AND (is_admin(auth.uid()) OR j.assigned_user_id = auth.uid())
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.jobs j
    WHERE j.id = job_store_skus.job_id
      AND (is_admin(auth.uid()) OR j.assigned_user_id = auth.uid())
  )
);
*/

SELECT 'RLS Status:' as info;
SELECT 
    schemaname,
    tablename,
    rowsecurity as rls_enabled
FROM pg_tables 
WHERE tablename IN ('jobs', 'job_store_skus')
ORDER BY tablename;

