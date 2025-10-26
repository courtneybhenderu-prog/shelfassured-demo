-- RLS Re-enable Plan for job_store_skus
-- Parent-deferred policy to jobs table
-- Execute when ready to re-enable RLS

-- Enable RLS on job_store_skus table
ALTER TABLE public.job_store_skus ENABLE ROW LEVEL SECURITY;

-- Drop existing policy if it exists
DROP POLICY IF EXISTS jss_rw ON public.job_store_skus;

-- Create parent-deferred RLS policy
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

-- Verify RLS is enabled and policy exists
SELECT 
    schemaname,
    tablename,
    rowsecurity,
    policyname,
    permissive,
    roles,
    cmd,
    qual
FROM pg_policies 
WHERE tablename = 'job_store_skus'
UNION ALL
SELECT 
    schemaname,
    tablename,
    rowsecurity,
    NULL as policyname,
    NULL as permissive,
    NULL as roles,
    NULL as cmd,
    NULL as qual
FROM pg_tables 
WHERE tablename = 'job_store_skus';

