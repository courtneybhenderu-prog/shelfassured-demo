-- ========================================
-- Quick Status Check - All Results in One View
-- ========================================

SELECT 
    '1. RPC Functions' as check_item,
    CASE 
        WHEN EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'approve_submission')
         AND EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'reject_submission')
        THEN '✅ Ready'
        ELSE '❌ Missing'
    END as status
UNION ALL
SELECT 
    '2. Notifications Schema',
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.columns 
                     WHERE table_name = 'notifications' AND column_name = 'type')
        THEN '✅ New schema'
        ELSE '❌ Wrong/Missing'
    END
UNION ALL
SELECT 
    '3. Storage Bucket',
    CASE 
        WHEN EXISTS (SELECT 1 FROM storage.buckets WHERE id = 'job_submissions')
        THEN '✅ Exists'
        ELSE '⚠️ Missing - Create in Dashboard'
    END
UNION ALL
SELECT 
    '4. Storage RLS Policies',
    CASE 
        WHEN EXISTS (SELECT 1 FROM pg_policies 
                     WHERE tablename = 'objects' 
                     AND schemaname = 'storage'
                     AND policyname LIKE '%job_submission%')
        THEN '✅ Set up'
        ELSE '⚠️ Missing - Run setup-storage-bucket-rls.sql'
    END
UNION ALL
SELECT 
    '5. Review Outcome Column',
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.columns 
                     WHERE table_name = 'job_submissions' 
                     AND column_name = 'review_outcome')
        THEN '✅ Exists'
        ELSE '⚠️ Missing - Add column'
    END
UNION ALL
SELECT 
    '6. Payments Table',
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.tables 
                     WHERE table_name = 'payments')
        THEN '✅ Exists'
        ELSE '❌ Missing'
    END
ORDER BY check_item;

