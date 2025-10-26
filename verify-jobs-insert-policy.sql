-- Quick check: Verify jobs INSERT policy exists
SELECT 
    policyname, 
    permissive, 
    roles, 
    cmd, 
    with_check
FROM pg_policies
WHERE schemaname = 'public' 
  AND tablename = 'jobs'
  AND cmd = 'INSERT'
ORDER BY policyname;

