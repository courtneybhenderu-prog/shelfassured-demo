-- ========================================
-- Final Verification Checklist
-- Run this to confirm everything is ready
-- ========================================

-- 1. Verify both RPC functions exist
SELECT 'RPC Functions' as check_type,
       CASE 
           WHEN EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'approve_submission')
            AND EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'reject_submission')
           THEN '✅ Both RPC functions exist'
           ELSE '❌ Missing RPC functions'
       END as status;

-- 2. Verify notifications table (new schema)
SELECT 'Notifications Schema' as check_type,
       CASE 
           WHEN EXISTS (SELECT 1 FROM information_schema.columns 
                        WHERE table_name = 'notifications' AND column_name = 'type')
           THEN '✅ New schema (type, payload, read_at)'
           ELSE '❌ Wrong schema or missing table'
       END as status;

-- 3. Verify storage bucket exists
SELECT 'Storage Bucket' as check_type,
       CASE 
           WHEN EXISTS (SELECT 1 FROM storage.buckets WHERE id = 'job_submissions')
           THEN '✅ Bucket exists'
           ELSE '⚠️ Bucket missing - create in Dashboard'
       END as status;

-- 4. Verify storage RLS policies exist
SELECT 'Storage RLS Policies' as check_type,
       CASE 
           WHEN EXISTS (SELECT 1 FROM pg_policies 
                        WHERE tablename = 'objects' 
                        AND schemaname = 'storage'
                        AND policyname LIKE '%job_submission%')
           THEN '✅ RLS policies exist'
           ELSE '⚠️ RLS policies missing - run setup-storage-bucket-rls.sql'
       END as status;

-- 5. Verify review_outcome column exists
SELECT 'Review Outcome Column' as check_type,
       CASE 
           WHEN EXISTS (SELECT 1 FROM information_schema.columns 
                        WHERE table_name = 'job_submissions' 
                        AND column_name = 'review_outcome')
           THEN '✅ Column exists'
           ELSE '⚠️ Column missing - add it'
       END as status;

-- 6. Verify payments table exists
SELECT 'Payments Table' as check_type,
       CASE 
           WHEN EXISTS (SELECT 1 FROM information_schema.tables 
                        WHERE table_name = 'payments')
           THEN '✅ Table exists'
           ELSE '❌ Table missing'
       END as status;

-- ========================================
-- Summary
-- ========================================
SELECT 
    '=== READY TO TEST ===' as summary,
    'If all checks above show ✅, you can test the submission review flow' as note;

