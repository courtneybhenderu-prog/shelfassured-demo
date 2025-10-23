-- Step 5: Security Advisor Pass
-- Check for common security issues

-- Check for SECURITY DEFINER functions
SELECT 'SECURITY DEFINER Functions:' as info;
SELECT 
    routine_name,
    security_type,
    routine_schema
FROM information_schema.routines 
WHERE security_type = 'DEFINER'
ORDER BY routine_name;

-- Check for unsafe search_path
SELECT 'Functions with search_path:' as info;
SELECT 
    routine_name,
    external_language,
    routine_definition
FROM information_schema.routines 
WHERE routine_definition LIKE '%search_path%'
ORDER BY routine_name;

-- Check RLS status and missing policies
SELECT 'RLS Status Check:' as info;
SELECT 
    schemaname,
    tablename,
    rowsecurity as rls_enabled,
    CASE 
        WHEN rowsecurity = true THEN 'RLS Enabled'
        ELSE 'RLS Disabled'
    END as status
FROM pg_tables 
WHERE schemaname = 'public'
  AND tablename IN ('jobs', 'job_store_skus', 'stores', 'skus', 'brands')
ORDER BY tablename;

-- Check for policies on RLS-enabled tables
SELECT 'RLS Policies:' as info;
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies 
WHERE schemaname = 'public'
ORDER BY tablename, policyname;
