-- Security Advisor Pass - Supabase Security Checklist
-- Run these queries to verify security posture

-- 1. Check for SECURITY DEFINER functions
SELECT 
    proname as function_name,
    prosecdef as is_security_definer,
    prosrc as function_source
FROM pg_proc 
WHERE prosecdef = true
ORDER BY proname;

-- 2. Check for unsafe search_path in functions
SELECT 
    proname as function_name,
    proconfig as function_config
FROM pg_proc 
WHERE proconfig IS NOT NULL
ORDER BY proname;

-- 3. Check RLS-enabled tables missing policies
SELECT 
    schemaname,
    tablename,
    rowsecurity,
    (SELECT COUNT(*) FROM pg_policies p WHERE p.tablename = t.tablename) as policy_count
FROM pg_tables t
WHERE schemaname = 'public' 
    AND rowsecurity = true
ORDER BY tablename;

-- 4. Check for tables with RLS disabled that should have it
SELECT 
    schemaname,
    tablename,
    rowsecurity
FROM pg_tables 
WHERE schemaname = 'public' 
    AND tablename IN ('jobs', 'users', 'brands', 'stores', 'skus')
ORDER BY tablename;

-- 5. Check for missing foreign key constraints
SELECT 
    tc.table_name,
    tc.constraint_name,
    tc.constraint_type
FROM information_schema.table_constraints tc
WHERE tc.table_schema = 'public'
    AND tc.table_name = 'job_store_skus'
ORDER BY tc.constraint_type, tc.constraint_name;

-- 6. Verify job_store_skus table security
SELECT 
    'job_store_skus security check' as check_type,
    CASE 
        WHEN EXISTS (SELECT 1 FROM pg_tables WHERE tablename = 'job_store_skus') 
        THEN 'Table exists' 
        ELSE 'Table missing' 
    END as table_status,
    CASE 
        WHEN EXISTS (SELECT 1 FROM pg_tables WHERE tablename = 'job_store_skus' AND rowsecurity = false) 
        THEN 'RLS disabled (expected)' 
        ELSE 'RLS status unknown' 
    END as rls_status;


